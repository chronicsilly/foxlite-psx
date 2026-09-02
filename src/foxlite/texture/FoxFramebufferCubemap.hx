package foxlite.texture;

import foxlite.renderer.FoxRenderer;
import foxlite.texture.FoxFramebuffer;
import foxlite.texture.FoxTextureFilter;
import lime.graphics.opengl.GL;
import lime.utils.Float32Array;
import lime.utils.UInt8Array;
import openfl.display3D.textures.CubeTexture;

class FoxFramebufferCubemap extends FoxFramebuffer {

	public function new() {
		super();
	}

	/**
		Attaches a depth cubemap texture to this framebuffer.

		Setting `texture` to null removes the attachment.

		@param texture A valid `FoxTextureCubemap` (`FoxTexture` is allowed only if the wrapped GL texture is a cubemap)
		@returns Always `false` since the framebuffer doesn't have any starting attachments
	**/
	public override function setDepthTexture(?texture:FoxTexture, withStencil:Bool = true):Bool {
		if(texture != null && !Std.isOfType(texture.glTexture, CubeTexture)) throw "Invalid texture!";
		var gl = context.gl;
		gl.bindFramebuffer(gl.FRAMEBUFFER, glTexture.__glFramebuffer);
		// Don't overwrite ours, openfl
		if(glTexture.__glDepthRenderbuffer == null) glTexture.__glDepthRenderbuffer = gl.createRenderbuffer();
		var texID = texture?.glTexture?.__textureID;
		// Attach with stencil buffer aswell
		var attachment = withStencil ? gl.DEPTH_STENCIL_ATTACHMENT : gl.DEPTH_ATTACHMENT;
		@:privateAccess hasStencil = withStencil && StringTools.endsWith(texture.__format.toUpperCase(), "STENCIL8");
		hasDepth = texture != null;
		glTexture.__optimizeForRenderToTexture = hasDepth; // indicate that we do have depth
		depthBuffer = texture;
		return false;
	}

	/**
		Attaches a color texture to this cubemap, you can also specify a color buffer output (first attachment MUST be 0)

		Setting `texture` to null removes the attachment.

		@param texture A valid `FoxTextureCubemap` (`FoxTexture` is allowed only if the wrapped GL texture is a cubemap)

		@returns Always `false` since the framebuffer doesn't have any starting attachments
	**/
	public override function setColorTexture(index:Int, ?texture:FoxTexture):Bool {
		if(texture != null && !Std.isOfType(texture.glTexture, CubeTexture)) throw "Invalid texture!";
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

		return false;
	}

	public override function resize(newWidth:Int, newHeight:Int) {
		if(newWidth == width && newHeight == height) {
			return;
		}
		colorBuffers.map(f -> f.resize(newWidth, newHeight));
		glTexture.dispose();
		if(stencilBuffer != null) GL.deleteRenderbuffer(stencilBuffer);
		stencilBuffer = null;
		__initTexture();
		depthBuffer.resize(newWidth, newHeight);
	}

	// Not supported
	public override function readPixels(x:Int = 0, y:Int = 0, ?width:Int, ?height:Int):UInt8Array {return null; }
	public override function readDepth(x:Int = 0, y:Int = 0, ?width:Int, ?height:Int):Float32Array {return null; }

	public override function isCubemap():Bool {
		return true;
	}

	/**
		Creates a framebuffer with a cubemap attached, this is 6 textures (one for each face of the cube) for color and depth each
	**/
	public static function create3D(size:Int, alphaChannel:Bool=true, type:String="unsigned_byte"):FoxFramebufferCubemap {
		var fb = new FoxFramebufferCubemap();
		var colorCube = FoxTextureCubemap.create(size, alphaChannel ? "rgba" : "rgb", type);
		var depthCube = FoxTextureCubemap.create(size, "DEPTH24_STENCIL8", "UNSIGNED_INT_24_8");

		depthCube.filter = FoxTextureFilter.NEAREST;
		fb.setDepthTexture(depthCube, true);
		fb.setColorTexture(0, colorCube);
		return fb;
	}

	public static function createShadowCubemap(size):FoxFramebufferCubemap {
		var fb = new FoxFramebufferCubemap();
		var depthCube = FoxTextureCubemap.create(size, "DEPTH_COMPONENT24", "unsigned_int");
		depthCube.filter = FoxTextureFilter.NEAREST;
		fb.setDepthTexture(depthCube, false);

		fb.setColorTexture(0, FoxTextureCubemap.create(size, "r8"));
		return fb;
	}
}