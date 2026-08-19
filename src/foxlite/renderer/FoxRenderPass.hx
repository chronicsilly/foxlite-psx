/*
*    ___           __ _ _       
*   / __\____  __ / /(_) |_ ___ 
*  / _\/ _ \ \/ // / | | __/ _ \
* / / | (_) >  </ /__| | ||  __/
* \/   \___/_/\_\____/_|\__\___| by dwdvIl
*                              
* 	     -- FoxRenderPass --
* 
* Customizable render passes for all!
* A render pass is like compositing:
* You render what you want, with a shader or material applied globally
* To any texture you want, using any camera you want, and then you can use
* that framebuffer texture in any shader or model
* Very useful for compositing and deferred rendering!
*
*/

package foxlite.renderer;

import Reflect;
import foxlite.FoxCamera;
import foxlite.FoxLayer;
import foxlite.FoxShader;
import foxlite.lights.FoxBaseLight;
import foxlite.lights.FoxLightData;
import foxlite.lights.FoxLightType;
import foxlite.loaders.FoxLoaderUtil;
import foxlite.material.FoxMaterial;
import foxlite.math.FoxMathUtil;
import foxlite.renderer.FoxRenderer;
import foxlite.system.FoxDrawTree;
import foxlite.system.FoxDrawTreeNode;
import foxlite.texture.FoxFramebuffer;
import foxlite.texture.FoxMipFilter;
import lime.graphics.opengl.GL;
import lime.math.Vector2;
import openfl.geom.Rectangle;
import openfl.ui.GameInput;
#if foxlite_polymod
import foxlite.funkin.PolymodUtils;
import lime.utils.DataPointer;
#end

class FoxRenderPass {

	public var name:String = "FoxRenderPass";

	/**
		The name of the target `FoxFramebuffer` in the scene.
	**/
	public var target:String = "default";
	public var clearColor:Array<Float> = [1, 1, 1, 1];
	public var useCameraColor:Bool = false;
	public var clear:Bool = true;

	/**
		If true, it will clear the shadow map before rendering shadows.
		If you have objects split in 2 passes, set this to false to prevent clearing
		the previous rendered objects' shadow texture
	**/
	public var clearShadowMap:Bool = true;

	/**
		Wheter or not to clear the depth and stencil buffers.

		Note: This only works when `clear` is `false`, as clearing those buffers are essential for 3D rendering.
	**/
	public var clearDepthAndStencil:Bool = true;
	public var enabled:Bool = true;

	/**
		 Shader to use for all models on this pass
	**/
	public var shader:FoxShader = null;

	/**
		If set, everything will be drawn using this material, 
		the shader on the original material WILL be used, unless
		`shader` is set in this pass.
	**/
	public var material:FoxMaterial = null; 
	
	// If both shader and material are null,
	// everything will be rendered with their own materials and shaders

	public var groups:Array<Int> = [];

	/**
		This is the portion of the screen where contents will be rendered.

		Useful if you want to offset the screen, scale it or
		create split screens in a single render texture.

		Call `setEmpty()` to use the framebuffer size (only applies to attachment 0)

		__Note:__ By default, the region starts at the bottom left of the screen,
		as opposed to Flixel's top right.
	**/
	public var region:Rectangle = new Rectangle();

	/**
		Render region for the shadow map.

		Check `region` for details.
	**/
	public var __shadowMapRegion:Rectangle = new Rectangle();

	/**
		This is the portion of the screen that will be clipped for rendering.
		
		__Note:__ This option is not implemented yet.
	**/
	public var scissor:Rectangle = new Rectangle(0, 0, 0, 0);

	// Holder value for iResolution uniform
	var iResolution:Vector2 = new Vector2();

	var shadowNode = new FoxDrawTreeNode(null);

	/**
		Creates a new render pass
		
		@param drawGroups The groups that will be drawn by this pass
		@param target The FoxScene's Render Target name
		@param properties (Optional) Pass an object to initialize the pass properties
	**/
	public function new(?drawGroups:Array<Int>, _target:String="default", ?properties:Dynamic) {
		if(drawGroups != null) for(g in drawGroups) groups.push(g);
		target = _target;

		#if !foxlite_polymod
		if(properties != null) for(v in Reflect.fields(properties)) {
			Reflect.setField(this, v, Reflect.field(properties, v));
		}
		#end
	}

	public function pass(camera:FoxCamera, drawGroups:Array<FoxDrawTree>, framebuffer:FoxFramebuffer) {
		var context = framebuffer.context;
		var gl = context.gl;
		var visibilityLayers = camera.modelLayers;

		FoxRenderer.setTarget(framebuffer);

		if(clear) {
			if(useCameraColor) {
				var c = camera.bgColor;
				context.clear(((c >> 16) & 0xFF) / 255, ((c >> 8) & 0xFF) / 255, (c & 0xFF) / 255, ((c >> 24) & 0xFF) / 255);
			}
			else {
				var c:Array<Float> = clearColor;
				context.clear(c[0], c[1], c[2], c[3]);
			}
		}
		else if(clearDepthAndStencil) FoxRenderer.clearDepthStencil();
		// Context3D resets the viewport, so we have to set it again
		GL.viewport(Std.int(region.x), Std.int(region.y), region.width <= 0 ? framebuffer.width : Std.int(region.width), region.height <= 0 ? framebuffer.height : Std.int(region.height));
		//FoxRenderer.setScissorRect(scissor);

		for(g in groups) {
			for(data in drawGroups[g]) { // in-order
				var mat = material ?? data.material;
				var matShader = shader ?? mat.shader ?? FoxRenderer.MISSING_SHADER;

				if(matShader == null) {
					continue; // Please assign a shader...
				}

				// Sets the GL context and updates material params
				setGlobals(matShader, camera, framebuffer);

				if(matShader.__hasLights) {
					camera.lightData.updateShaderLights(matShader);
				}
				var samplerId = FoxRenderer.useMaterial(context, mat);

				// Set camera transforms
				matShader.setMatrix4("projection", camera.projectionMatrix);
				matShader.setMatrix4("invProjection", camera.__invProjectionMatrix);
				
				matShader.setMatrix4("view", camera.viewMatrix);
				matShader.setMatrix4("invView", camera.__invViewMatrix);

				render(data, matShader, visibilityLayers, samplerId);
			}
		}

		// Generate mipmaps for framebuffer textures with mipmap filtering enabled
		for(tex in framebuffer.colorBuffers) if(tex.mipFilter != FoxMipFilter.MIPNONE) tex.generateMipmaps();
	}

	/**
		Renders all models in shadow mode, this makes use of the `SHADOW_PASS` preprocessor
		in the shaders, and lights matrices.
	**/
	public function shadowPass(light:FoxBaseLight, camera:FoxCamera, drawGroups:Array<FoxDrawTree>, shadowFramebuffer:FoxFramebuffer) {
		var context = shadowFramebuffer.context;
		var glTex = shadowFramebuffer.glTexture;
		var visibilityLayers = camera.modelLayers;

		FoxRenderer.setTarget(shadowFramebuffer);
		if(clearShadowMap) context.clear(0, 0, 0, 0, 1, 0, 6);

		GL.viewport(Std.int(__shadowMapRegion.x), Std.int(__shadowMapRegion.y), __shadowMapRegion.width <= 0 ? shadowFramebuffer.width : Std.int(__shadowMapRegion.width), __shadowMapRegion.height <= 0 ? shadowFramebuffer.height : Std.int(__shadowMapRegion.height));

		var viewMatrix = light.viewMatrix;

		for(g in groups) {
			for(data in drawGroups[g]) {
				var mat = data.material;
				if(!mat.depthTest) continue; // Skip non-depth tested meshes

				// Filter by models that can cast shadows, skip if none
				var shadowModels = data.models.filter(f -> f.castShadows);
				if(shadowModels.length == 0) continue;

				var matShader = shader ?? mat.shader ?? FoxRenderer.MISSING_SHADER;

				if(matShader == null) {
					continue; // Please assign a shader...
				}
				else matShader = matShader.shadow;

				iResolution.setTo(glTex.__width, glTex.__height);
				matShader.setVector2("iResolution", iResolution);

				var samplerId = FoxRenderer.useMaterialForShadow(context, mat);
				
				shadowNode.material = data.material;
				shadowNode.meshes = data.meshes;
				shadowNode.models = shadowModels;
				
				// Render from the perspective of the light source
				matShader.setMatrix4("projection", light.projectionMatrix);
				matShader.setMatrix4("view", viewMatrix);

				render(shadowNode, matShader, visibilityLayers, samplerId);
			}
		}
	}

	public function passShadowLights(lightData:FoxLightData, camera:FoxCamera, drawGroups:Array<FoxDrawTree>) {
		var shadowLights = lightData.shadowLights;
		var prevClear = clearShadowMap;
		clearShadowMap = false;
		if(prevClear && shadowLights.length > 0) lightData.clearShadowMaps();

		for(i=>light in shadowLights) {
			var r = light.shadowAtlasRect;
			__shadowMapRegion.setTo(r.x, r.y, r.z, r.w);
			
			var shadowMapAtlas = lightData.getShadowAtlas(light.getType());
			if(shadowMapAtlas == null) continue;
			shadowPass(light, camera, drawGroups, shadowMapAtlas);
			
			// TODO: For point lights, render 6 times in a cubemap
			// Then use it as a samplerCube in the shader
			// Figure out somehow how to use more than one for lights, if-else comparisons are slow but plausible
			// and texture arrays aren't available in GLSL 2
		}
		clearShadowMap = prevClear;
	}

	public function render(data:FoxDrawTreeNode, _shader:FoxShader, layers:FoxLayer, samplerOffset:Int=0) {
		var meshIterator = data.meshes.iterator();
		var prevModel:FoxModel = null;
		for(model in data.models) {
			// Check if model is in our allowed list
			var mesh = meshIterator.next();
			if(layers & model.layers == 0) continue;

			if(prevModel != model) {
				prevModel = model;
				_shader.setMatrix4("model", model.transform);
						
				// -- Skinned mesh --
				var skinloc = _shader.__uSkinnedLocation;
				if(skinloc != -1) {
					if(model.skin == null) GL.uniform1i(cast skinloc, 0);	// uSkinned = false
					else {
						// Upload bone transforms
						var boneData = model.skin.boneData;
						FoxRenderer.useTexture(samplerOffset, boneData);
						GL.uniform1i(cast _shader.__bonesDataLocation, samplerOffset); // Set BONESDATA to bones buffer
						GL.uniform1f(cast _shader.__bonesDataSizeLocation, 1 / boneData.getLength()); // BONESDATA texel size

						GL.uniform1i(cast skinloc, 1); // uSkinned = true
					}
				}

				// -- Instanced mesh
				var instloc = _shader.__uInstancedLocation;
				if(instloc != -1) {
					GL.uniform1i(cast instloc, model.isInstanced() ? 1 : 0);
				}
			}
			model.renderMesh(mesh);
		}
	}

	public function setGlobals(shader:FoxShader, camera:FoxCamera, framebuffer:FoxFramebuffer) {
		// Set global data
		var env = camera.scene.environment;
		if(env.skyTexture != null) shader.setSampler2D("skyTexture", env.skyTexture);
		else shader.textureInput.remove('skyTexture');
		
		shader.setVector2("skyOffset", env.skyOffset);
		shader.setVector4("fogColor", env.fogColor);

		iResolution.setTo(framebuffer.glTexture.__width, framebuffer.glTexture.__height);
		shader.setVector2("iResolution", iResolution);
	}

	public static function fromAsset(name:String):Array<FoxRenderPass> {
		var data:Array<Dynamic> = FoxLoaderUtil.loadJSON(name);
		trace("[FoxLite > FoxRenderPass]: LOADING PIPELINE: ", data);
		if(data == null || data.length == 0) return null;

		var pipeline = [];

		for(pass in data) {
			var renderPass = new FoxRenderPass();
			renderPass.name = pass.name;
			if(pass.target != null) renderPass.target = pass.target;
			if(pass.shader != null) renderPass.shader = FoxShader.fromAsset(pass.shader);
			if(pass.material != null) renderPass.material = FoxMaterial.fromJSON(pass.material); // must be JSON for now
			if(pass.enabled != null) renderPass.enabled = pass.enabled;
			
			// Polytype values
			if(pass.clear is Bool) renderPass.clear = pass.clear;
			if(pass.clear is String) {
				if(pass.clear == "default") renderPass.useCameraColor = true;
				else {
					var c = Std.parseInt(pass.clear);
					renderPass.clearColor = [((c >> 16) & 0xFF) / 255, ((c >> 8) & 0xFF) / 255, (c & 0xFF) / 255, ((c >> 24) & 0xFF) / 255];
				}
			}
			else if(pass.clear is Array) {
				var c = pass.clear;
				renderPass.clear = true;
				renderPass.clearColor = [c[0] ?? 0, c[1] ?? 0, c[2] ?? 0, c[3] ?? 1];
			}
			if(pass.clearDepthAndStencil is Bool) renderPass.clearDepthAndStencil = pass.clearDepthAndStencil;
			if(pass.clearShadowMap is Bool) renderPass.clearShadowMap = pass.clearShadowMap;

			if(pass.groups is Array) {
				renderPass.groups = cast pass.groups;
			}

			pipeline.push(renderPass);
		}

		return pipeline;
	}
}

