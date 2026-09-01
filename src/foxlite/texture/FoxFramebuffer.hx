
// A framebuffer that can hold any sort of values, for deferred renderers and storage

package foxlite.texture;

import StringTools;
import foxlite.polyfill.TypedArray;
import foxlite.renderer.FoxRenderer;
import foxlite.texture.FoxTexture;
import lime.graphics.opengl.GL;
import lime.graphics.opengl.GLRenderbuffer;
import lime.utils.Float32Array;
import lime.utils.UInt8Array;
import openfl.display3D.Context3D;
import openfl.display3D.textures.Texture;
import openfl.display3D.textures.CubeTexture;
import openfl.errors.RangeError;
#if foxlite_polymod
import lime.utils.BytePointer;
#end

/**
	A framebuffer that can be used as target for rendering.

	There is no pre-defined width and height, instead, the textures provided
	with `setColorTexture()` and `setDepthTexture()` defines the target resolution.
	**/
class FoxFramebuffer {
	
	public var glTexture:Texture = null;
	public var stencilBuffer:GLRenderbuffer = null;
	public var depthBuffer:FoxTexture = null;
	public var colorBuffers:Array<FoxTexture> = [];
	public var hasDepth:Bool = false;
	public var hasStencil:Bool = false;
	public var context:Context3D = null;

	public var drawBuffers:Array<Int> = [];

	public var width(get, null):Int;
	public var height(get, null):Int;

	function get_width():Int {
		return glTexture.__width;
	}

	function get_height():Int {
		return glTexture.__height;
	}

	public function new() {
		FoxRenderer.allocationsThisFrame += 2;
		context = FoxRenderer.getContext();

		__initTexture();
	}

	private function __initTexture():Void {
		// Create dummy texture object
		
		@:privateAccess glTexture = new Texture(context, 2, 2, cast 1, false, 0);

		// Even though we don't tell OpenFL this is a framebuffer, 
		// we can still attach a depth buffer to it and use it as target
		glTexture.__optimizeForRenderToTexture = false;
		glTexture.__getGLFramebuffer(false, 0, 0);

		// Cleanup
		glTexture.dispose();
		// Now setup our texture

		// Our GLObjects are gone, but the texture is still here
		// we can fill it with our own data

		// Create framebuffer
		glTexture.__glFramebuffer = GL.createFramebuffer();
	}

	/**
		Attaches a depth texture to this framebuffer.

		Setting `texture` to null removes the attachment.

		@param texture A valid `FoxTexture`
		@returns `true` if the framebuffer attachment has been successful
	**/
	public function setDepthTexture(?texture:FoxTexture, withStencil:Bool=true):Bool {
		if(texture != null && Std.isOfType(texture.glTexture, CubeTexture)) throw "Invalid texture!";
		var gl = context.gl;
		gl.bindFramebuffer(gl.FRAMEBUFFER, glTexture.__glFramebuffer);
		// Don't overwrite ours, openfl
		if(glTexture.__glDepthRenderbuffer == null) glTexture.__glDepthRenderbuffer = gl.createRenderbuffer();
		var texID = texture?.glTexture?.__textureID;
		// Attach with stencil buffer aswell
		var attachment = withStencil ? gl.DEPTH_STENCIL_ATTACHMENT : gl.DEPTH_ATTACHMENT;
		@:privateAccess hasStencil = withStencil && StringTools.endsWith(texture.__format.toUpperCase(), "STENCIL8");
		gl.framebufferTexture2D(gl.FRAMEBUFFER, attachment, gl.TEXTURE_2D, cast texID, 0);
		hasDepth = texture != null;
		glTexture.__optimizeForRenderToTexture = hasDepth; // indicate that we do have depth
		depthBuffer = texture;
		return FoxRenderer.checkFrameBuffer();
	}

	/**
		Attaches a color texture to this framebuffer, you can also specify a color buffer output (first attachment MUST be 0)

		Setting `texture` to null removes the attachment.

		@param texture A valid `FoxTexture`
		@returns `true` if the framebuffer attachment has been successful
	**/
	public function setColorTexture(index:Int, ?texture:FoxTexture):Bool {
		if(texture != null && Std.isOfType(texture.glTexture, CubeTexture)) throw "Invalid texture!";
		var gl = context.gl;
		gl.bindFramebuffer(gl.FRAMEBUFFER, glTexture.__glFramebuffer);

		// lime's GL.COLOR_ATTACHMENT0 is not available in polymod?
		var colorAttachment:Int = gl.COLOR_ATTACHMENT0 + index;
		// Store for later use
		if(texture != null) {
			if(!drawBuffers.contains(colorAttachment)) {
				drawBuffers.push(colorAttachment);
				colorBuffers.push(texture);
			}
			// To have some level of compatibility with Context3D, adapt the resolution of buffer0
			if(index == 0) {
				glTexture.__width = texture.glTexture.__width;
				glTexture.__height = texture.glTexture.__height;
			}
		}
		else {
			var idx = drawBuffers.indexOf(colorAttachment);
			if(idx != -1) colorBuffers.splice(idx, 1); // Remove buffer
			drawBuffers.remove(colorAttachment);
		}

		gl.framebufferTexture2D(gl.FRAMEBUFFER, colorAttachment, gl.TEXTURE_2D, texture?.glTexture?.__textureID, 0);
		return FoxRenderer.checkFrameBuffer();
	}

	/**
		Warning! This will resize all color buffers aswell as the depth and stencil buffers if attached!

		Intended for output framebuffers only!
	**/
	public function resize(newWidth:Int, newHeight:Int) {
		if(newWidth == width && newHeight == height) {
			return;
		}
		var textures = colorBuffers.map(f -> f.resize(newWidth, newHeight));
		glTexture.dispose();
		if(stencilBuffer != null) GL.deleteRenderbuffer(stencilBuffer);
		stencilBuffer = null;
		__initTexture();
		if(hasDepth) {
			setDepthTexture(depthBuffer.resize(newWidth, newHeight), hasStencil);
		}
		for(t in 0...textures.length) setColorTexture(t, textures[t]);
	}

	/**
		Reads a region of the framebuffer texture in the GPU and stores it in a buffer.

		This function isn't properly implemented yet.

		__Note:__ This operation is slow!

		@param x The X coordinate of the region 
		@param y The Y coordinate of the region
		@param width The Width of the region
		@param height The Height of the region

	**/
	public function readPixels(x:Int=0, y:Int=0, ?width:Int, ?height:Int):UInt8Array {
		var gl = context.gl;
		gl.bindFramebuffer(gl.FRAMEBUFFER, glTexture.__glFramebuffer);

		if(width == null) width = glTexture.__width;
		if(height == null) height = glTexture.__height;

		// Allocate space 
		var mem:Array<Int> = [];
		mem.resize(width*height*4);
		var buffer = TypedArray.UInt8Array(mem);

		#if foxlite_polymod
		#if lime_webgl
		GL.readPixelsWEBGL(x, y, width, height, gl.RGBA, gl.UNSIGNED_BYTE, buffer);
		#else
		var pointer = BytePointer.fromArrayBufferView(buffer);
		GL.readPixels(x, y, width, height, gl.RGBA, gl.UNSIGNED_BYTE, pointer);
		#end
		#else
		gl.readPixels(x, y, width, height, gl.RGBA, gl.UNSIGNED_BYTE, buffer);
		#end
		
		return buffer;
	}

	/**
		Same as `readPixels()` but for the depth buffer instead (if attached)

		__Note:__ This operation is slow!

		__Note 2:__ Due to WebGL limitations, this does not work in HTML5.

		@returns a `Float32Array` containing depth values
	**/
	public function readDepth(x:Int=0, y:Int=0, ?width:Int, ?height:Int):Float32Array {
		var gl = context.gl;
		gl.bindFramebuffer(gl.FRAMEBUFFER, glTexture.__glFramebuffer);

		if(width == null) width = glTexture.__width;
		if(height == null) height = glTexture.__height;

		// Allocate space 
		var mem:Array<Float> = [];
		mem.resize(width*height*4);
		var buffer = TypedArray.Float32Array(mem);

		#if foxlite_polymod
		#if lime_webgl
		GL.readPixelsWEBGL(x, y, width, height, gl.DEPTH_COMPONENT, gl.FLOAT, buffer);
		#else
		var pointer = BytePointer.fromArrayBufferView(buffer);
		GL.readPixels(x, y, width, height, gl.DEPTH_COMPONENT, gl.FLOAT, pointer);
		#end
		#else
		gl.readPixels(x, y, width, height, gl.DEPTH_COMPONENT, gl.FLOAT, buffer);
		#end

		return buffer;
	}

	public function destroy(destroyBuffers:Bool=false) {
		var gl = context.gl;
		glTexture.dispose();
		if(stencilBuffer != null) gl.deleteRenderbuffer(stencilBuffer);
		stencilBuffer = null;
		drawBuffers.resize(0);
		if(destroyBuffers) {
			depthBuffer?.destroy();
			for(c in colorBuffers) c.destroy();
		}
		depthBuffer = null;
		colorBuffers.resize(0);
	}

	/**
		Convenience method to create a 2D framebuffer (no depth nor stencil attached)
	**/
	public static function create2D(width:Int, height:Int, alphaChannel:Bool=true, type:String="unsigned_byte"):FoxFramebuffer {
		var fb = new FoxFramebuffer();
		var color = FoxTexture.create(width, height, alphaChannel ? "rgba" : "rgb", type);
		fb.setColorTexture(0, color);
		return fb;
	}

	/**
		Convenience method to create a 3D framebuffer (depth+stencil buffers attached)
	**/
	public static function create3D(width:Int, height:Int, alphaChannel:Bool=true, type:String="unsigned_byte"):FoxFramebuffer {
		var fb = new FoxFramebuffer();
		var depth = FoxTexture.create(width, height, "DEPTH24_STENCIL8", "UNSIGNED_INT_24_8");
		var color = FoxTexture.create(width, height, alphaChannel ? "rgba" : "rgb", type);

		depth.filter = FoxTextureFilter.NEAREST;
		fb.setDepthTexture(depth);
		fb.setColorTexture(0, color);
		return fb;
	}

	/**
		Convenience method to create a Deferred 3D framebuffer

		Deferred Rendering is a technique where lighting calculations are postponed
		until after all the geometry has been processed.

		To do this we need multiple buffers to store information and combine them in the
		passes.

		By default, FoxLite shaders and passes are all Forward Rendered, meaning
		lighting happens when the geometry is rendered.

		__Note:__ This requires `GL_EXT_draw_buffers` extension support in the OpenGL context,
		otherwise no data will be writen to the buffers other than the first one.

		__Note 2:__ Alpha channel will be always available for extra storage.

		If `bufferCount` is 0, only the depth buffer will be attached to the framebuffer, which may not work on all platforms.
	**/
	public static function createDeferred(width:Int, height:Int, bufferCount:Int=1, precision:String="32F"):FoxFramebuffer {
		final maxColorAttachments = 32;
		if(bufferCount >= maxColorAttachments) throw new RangeError('gl.MAX_COLOR_ATTACHMENTS exceeded. ($bufferCount of $maxColorAttachments)');
		var fb = new FoxFramebuffer();
		var depth = FoxTexture.create(width, height, "DEPTH24_STENCIL8", "UNSIGNED_INT_24_8");
		depth.filter = FoxTextureFilter.NEAREST;
		fb.setDepthTexture(depth);

		for(i in 0...bufferCount) {
			var color = FoxTexture.create(width, height, "rgba" + precision, "float");
			fb.setColorTexture(i, color);
		}
		return fb;
	}

	/**
		Convenience method to create a shadowmap with the minimal amount of memory usage

		This creates a depth texture and a single channel color texture for compatibility.
	**/
	public static function createShadowMap(width:Int, height:Int):FoxFramebuffer {
		var fb = new FoxFramebuffer();
		var depth = FoxTexture.create(width, height, "DEPTH_COMPONENT24", "unsigned_int");
		depth.filter = FoxTextureFilter.NEAREST;
		fb.setDepthTexture(depth, false);

		fb.setColorTexture(0, FoxTexture.create(width, height, "r8"));
		return fb;
	}
}