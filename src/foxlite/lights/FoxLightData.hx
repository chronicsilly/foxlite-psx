package foxlite.lights;

import foxlite.FoxCamera;
import foxlite.lights.FoxDirectionalLight;
import foxlite.lights.FoxLightType;
import foxlite.lights.FoxPointLight;
import foxlite.lights.FoxSpotLight;
import foxlite.polyfill.VectorFactory;
import foxlite.renderer.FoxRenderer;
import foxlite.texture.FoxFramebuffer;
import foxlite.texture.FoxTextureFilter;
import haxe.ds.BalancedTree;
import openfl.Vector;
import openfl.geom.Vector3D;

class FoxLightData {

	public inline static final MAX_LIGHTS = 24;
	public inline static final MAX_SHADOW_LIGHTS = 8;

	public var ambientLight:Vector3D = new Vector3D(1, 1, 1);

	public final directionalLights:Array<FoxDirectionalLight> = [];
	public final orderedPointLights:BalancedTree<Float, FoxPointLight> = new BalancedTree();
	public final orderedSpotLights:BalancedTree<Float, FoxSpotLight> = new BalancedTree();
	public final orderedAreaLights:BalancedTree<Float, FoxAreaLight> = new BalancedTree();
	public final shadowLights:Array<FoxBaseLight> = [];

	// Data
	public var lightBuffer:Vector<Vector3D> = VectorFactory.Vector3D();
	public var lightTypes:Array<FoxLightType> = [];

	public var shadowLightBuffer:Vector<Vector3D> = VectorFactory.Vector3D();
	public var shadowLightTypes:Array<FoxLightType> = [];

	/**
		Shadow targets, used exclusively for shadowmaps.

		This is a depth texture containing portions of shadowmaps for lights.

		Due to platform texture size limits, this is a tradeoff between shadow
		texture size and how many shadows there can be at once.
	**/
	public var shadowMapAtlas:Array<FoxFramebuffer> = [
		FoxFramebuffer.createShadowMap(2, 2),
		FoxFramebuffer.createShadowMap(2, 2),
		FoxFramebuffer.createShadowMap(2, 2)
	];

	/**
		The max width of the whole `shadowMapAtlas`. The shadowmap will expand to this size.
	**/
	public var shadowMapMaxWidth(default, set):Int = 4096;

	/**
		The max height of the whole `shadowMapAtlas`. The shadowmap will expand to this size.
	**/
	public var shadowMapMaxHeight:Int = 4096;

	/**
		The size of light shadowmap atlas. Must be a PowerOf2 for optimal packing.
		This also limits the number of shadows you can have based on
		how many regions can be packed inside the shadow map atlas.

		In short, this is the 'Shadow texture size' for each light, but
		the bigger it is, the less shadows you can have.
	**/
	public var directionalLightShadowMapSize(default, set):Int = 1024;

	/**
		Calculated tiles for directional lights.

		This value is result of `Math.floor(shadowMapMaxWidth / directionalLightShadowMapSize)`

	**/
	public var tiles0:Int = 0;

	/**
		The size of light shadowmap atlas. Must be a PowerOf2 for optimal packing.
		This also limits the number of shadows you can have based on
		how many regions can be packed inside the shadow map atlas.

		In short, this is the 'Shadow texture size' for each light, but
		the bigger it is, the less shadows you can have.
	**/
	public var pointLightShadowMapSize(default, set):Int = 512;

	/**
		Calculated tiles for point lights.

		This value is result of `Math.floor(shadowMapMaxWidth / pointLightShadowMapSize)`
	**/
	public var tiles1:Int = 0;

	/**
		The size of light shadowmap atlas. Must be a PowerOf2 for optimal packing.
		This also limits the number of shadows you can have based on
		how many regions can be packed inside the shadow map atlas.

		In short, this is the 'Shadow texture size' for each light, but
		the bigger it is, the less shadows you can have.
	**/
	public var spotLightShadowMapSize(default, set):Int = 1024;
	
	/**
		Calculated tiles for point lights.

		This value is result of `Math.floor(shadowMapMaxWidth / spotLightShadowMapSize)`
	**/
	public var tiles2:Int = 0;

	/**
		The number of `Vector3D` per light
	**/
	public final vectorsPerLight:Int = 4;

	private function set_shadowMapMaxWidth(v:Int):Int {
		this.tiles0 = Math.floor(v / this.directionalLightShadowMapSize);
		this.tiles1 = Math.floor(v / this.pointLightShadowMapSize);
		this.tiles2 = Math.floor(v / this.spotLightShadowMapSize);
		this.shadowMapMaxWidth = v;
		return v;
	}

	private function set_directionalLightShadowMapSize(v:Int):Int {
		this.tiles0 = Math.floor(this.shadowMapMaxWidth / v);
		this.directionalLightShadowMapSize = v;
		return v;
	}

	private function set_pointLightShadowMapSize(v:Int):Int {
		this.tiles1 = Math.floor(this.shadowMapMaxWidth / v);
		this.pointLightShadowMapSize = v;
		return v;
	}

	private function set_spotLightShadowMapSize(v:Int):Int {
		this.tiles2 = Math.floor(this.shadowMapMaxWidth / v);
		this.spotLightShadowMapSize = v;
		return v;
	}

	public function new() {
		for(_ in 0...FoxLightData.MAX_LIGHTS*vectorsPerLight) lightBuffer.push(new Vector3D());
		for(_ in 0...FoxLightData.MAX_SHADOW_LIGHTS*vectorsPerLight) shadowLightBuffer.push(new Vector3D());

		var gl = FoxRenderer.getContext().gl;
		var maxTexSize = gl.getParameter(gl.MAX_TEXTURE_SIZE) ?? 4096;
		shadowMapMaxWidth = maxTexSize;
		shadowMapMaxHeight = maxTexSize;
	}

	public static function staticInit() {
		#if foxlite_polymod
		trace(MAX_LIGHTS, MAX_SHADOW_LIGHTS);
		#end
	}

	public function prepareLights(camera:FoxCamera) {
		lightTypes.resize(0);
		shadowLightTypes.resize(0);
		shadowLights.resize(0);
		
		// Write directional light data
		var i:Int = 0, j:Int = 0, k:Int = 0;
		var buffer:Vector<Vector3D>;
		var types:Array<Int> = null;

		for(light in directionalLights) {
			if(light.shadow) {
				k = j;
				buffer = shadowLightBuffer.__array;
				types = shadowLightTypes;
				shadowLights.push(light);
				j += vectorsPerLight;
			}
			else {
				k = i;
				buffer = lightBuffer.__array;
				types = lightTypes;
				i += vectorsPerLight;
			}
			if(k+vectorsPerLight >= buffer.length) break; // Can't add more lights
			var v = buffer[k];	   // color
			var v2 = buffer[k+2];  // direction
			v.copyFrom(light.color);
			v.scaleBy(light.energy);
			camera.__invViewMatrix.transformVectorToOutput(light.direction, v2); // invView * direction
			types.push(FoxLightType.DIRECTIONAL);
		}

		// Write point light data
		for(light in orderedPointLights) {
			if(light.shadow) {
				k = j;
				buffer = shadowLightBuffer.__array;
				types = shadowLightTypes;
				shadowLights.push(light);
				j += vectorsPerLight;
			}
			else {
				k = i;
				buffer = lightBuffer.__array;
				types = lightTypes;
				i += vectorsPerLight;
			}
			if(k+vectorsPerLight >= buffer.length) break; // Can't add more lights
			var v = buffer[k];    // color
			var v2 = buffer[k+1]; // position
			v.copyFrom(light.color);
			v.scaleBy(light.energy);
			v.w = light.range;
			camera.viewMatrix.transformVectorToOutput(light.globalPosition, v2);
			v2.w = light.attenuation;
			types.push(FoxLightType.POINT);
		}

		// Write spot light data
		for(light in orderedSpotLights) {
			if(light.shadow) {
				k = j;
				buffer = shadowLightBuffer.__array;
				types = shadowLightTypes;
				shadowLights.push(light);
				j += vectorsPerLight;
			}
			else {
				k = i;
				buffer = lightBuffer.__array;
				types = lightTypes;
				i += vectorsPerLight;
			}
			if(k+vectorsPerLight >= buffer.length) break; // Can't add more lights
			var v = buffer[k];		// color
			var v2 = buffer[k+1];	// position
			var v3 = buffer[k+2];	// direction

			v.copyFrom(light.color);
			v.scaleBy(light.energy);
			v.w = light.range;

			camera.viewMatrix.transformVectorToOutput(light.globalPosition, v2); // view * position
			v2.w = light.attenuation;

			camera.__invViewMatrix.transformVectorToOutput(light.direction, v3); // invView * direction
			v3.w = Math.cos(light.angle);
			types.push(FoxLightType.SPOT);
		}

		// Write area light data
		for(light in orderedAreaLights) {
			if(light.shadow) {
				k = j;
				buffer = shadowLightBuffer.__array;
				types = shadowLightTypes;
				shadowLights.push(light);
				j += vectorsPerLight;
			}
			else {
				k = i;
				buffer = lightBuffer.__array;
				types = lightTypes;
				i += vectorsPerLight;
			}
			if(k+vectorsPerLight >= buffer.length) break; // Can't add more lights
			var v = buffer[k];    // color
			var v2 = buffer[k+1]; // position
			var v3 = buffer[k+2]; // direction
			var v4 = buffer[k+3]; // sdfData
			v.copyFrom(light.color);
			v.scaleBy(light.energy);
			v.w = light.range;
			camera.viewMatrix.transformVectorToOutput(light.globalPosition, v2);
			v2.w = light.attenuation;
			v3.copyFrom(light.direction); //camera.__invViewMatrix.transformVectorToOutput(light.direction, v3); // invView * direction
			v3.w = light.getSdfRange();
			v4.copyFrom(light.sdfData);
			v4.w = light.sdfData.w;
			types.push(FoxLightType.AREA);
		}

		// Shadowmap atlas tiling
		prepareShadowLights(camera);
	}

	public function prepareShadowLights(camera:FoxCamera) {
		var i:Int = 0;
		var j:Int = 0;
		var k:Int = 0;
		for(idx=>light in shadowLights) {
			var atlas = shadowMapAtlas[light.getShadowMapType()];
			var uv = light.shadowAtlasUV;
			var r = light.shadowAtlasRect;

			switch(shadowLightTypes[idx]) {
				case FoxLightType.DIRECTIONAL: {
					// Tiled X and Y
					r.setTo(i % tiles0, Std.int(i / tiles0), 1);
					r.w = directionalLightShadowMapSize;
					r.scaleBy(directionalLightShadowMapSize);
					i += 1;
					// Shadowmap stuff
					growShadowMapBound(atlas, Std.int(r.x + r.z), Std.int(r.y + r.w));
					
					var w = atlas.width;
					var h = atlas.height;
					uv.x = r.x / w;
					uv.y = r.y / h;
					uv.z = uv.x + r.z / w;
					uv.w = uv.y + r.w / h;
				};
				case FoxLightType.POINT, FoxLightType.AREA: {
					// Tiled X and Y
					// Multiplied by 2 because we'll have 2 tiles horizontally per light
					r.setTo((j*2) % tiles1, Std.int((j*2) / tiles1), 1);
					r.w = pointLightShadowMapSize;
					r.scaleBy(pointLightShadowMapSize);
					j += 1;
					
					// Shadowmap stuff
					growShadowMapBound(atlas, Std.int(r.x + r.z*2), Std.int(r.y + r.w));

					var w = atlas.width;
					var h = atlas.height;
					uv.x = r.x / w;
					uv.y = r.y / h;
					uv.z = uv.x + r.z / w;
					uv.w = uv.y + r.w / h;
				};
				case FoxLightType.SPOT: {
					// Tiled X and Y
					r.setTo(k % tiles2, Std.int(k / tiles2), 1);
					r.w = spotLightShadowMapSize;
					r.scaleBy(spotLightShadowMapSize);
					k += 1;
					
					// Shadowmap stuff
					growShadowMapBound(atlas, Std.int(r.x + r.z), Std.int(r.y + r.w));

					var w = atlas.width;
					var h = atlas.height;
					uv.x = r.x / w;
					uv.y = r.y / h;
					uv.z = uv.x + r.z / w;
					uv.w = uv.y + r.w / h;
				};
			}
		}
	}

	public function growShadowMapBound(map:FoxFramebuffer, width:Int, height:Int) {
		if(width >= shadowMapMaxWidth || height >= shadowMapMaxHeight) {
			throw 'Maximum shadowmap size exceeded: ${width}x${height}, limit: ${shadowMapMaxWidth}x${shadowMapMaxHeight}';
			return;
		}
		if(width > map.width || height > map.height) {
			map.resize(width, height);
			map.depthBuffer.filter = FoxTextureFilter.NEAREST;
		}
	}

	public function setAmbientLight(color:Vector3D) {
		ambientLight.copyFrom(color);
	}

	public function updateShaderLights(shader:FoxShader) {
		var count = lightTypes.length;
		shader.setVector3("ambientLight", ambientLight);
		shader.setInt("lightCount", count);

		var i:Int = 0;
		var a = lightBuffer.__array;

		if(count > 0) {
			shader.setIntArray("lightTypes", lightTypes);

			for(li in 0...count) {
				shader.setVector4('lights[$li].color', a[i]);
				shader.setVector4('lights[$li].position', a[i+1]);
				shader.setVector4('lights[$li].direction', a[i+2]);
				shader.setVector4('lights[$li].sdfData', a[i+3]);
				i += vectorsPerLight;
			}
		}

		// Shadow lights
		count = shadowLights.length;

		shader.setInt("shadowCount", count);
		if(count == 0) return;

		shader.setIntArray("shadowLightTypes", shadowLightTypes);

		i = 0;
		a = shadowLightBuffer.__array;
		for(li=>light in shadowLights) {
			shader.setVector4('shadowLights[$li].color', a[i]);
			shader.setVector4('shadowLights[$li].position', a[i+1]);
			shader.setVector4('shadowLights[$li].direction', a[i+2]);
			shader.setVector4('shadowLights[$li].sdfData', a[i+3]);

			shader.setMatrix4('shadowLights[$li].viewProjection', light.viewProjection);
			shader.setVector4('shadowLights[$li].atlasRect', light.shadowAtlasUV);
			
			i += vectorsPerLight;
		}

		if(count > 0) { // If there's at least one shadow
			// TODO: cache this
			var texsize:Array<Float> = [];
			for(t=>a in shadowMapAtlas) {
				shader.setSampler2D('shadowtex$t', a.depthBuffer);
				texsize.push(1 / a.width);
				texsize.push(1 / a.height);
			}
			shader.setFloatArray('shadowtexelsize', texsize);
		}
	}

	public function clearShadowMaps() {
		var context = FoxRenderer.getContext();
		if(directionalLights.length > 0) {
			FoxRenderer.setTarget(shadowMapAtlas[FoxLightType.DIRECTIONAL]);
			context.clear();
		}

		@:privateAccess if(orderedPointLights.root != null || orderedAreaLights.root != null) {
			FoxRenderer.setTarget(shadowMapAtlas[FoxLightType.POINT]);
			context.clear();
		}

		@:privateAccess if(orderedSpotLights.root != null) {
			FoxRenderer.setTarget(shadowMapAtlas[FoxLightType.SPOT]);
			context.clear();
		}
	}

	public function clearLights() {
		directionalLights.resize(0);
		orderedPointLights.clear();
		orderedSpotLights.clear();
		orderedAreaLights.clear();
	}

	public function destroy() {
		clearLights();
		lightBuffer = null;
		lightTypes = null;
		shadowLightTypes = null;
		shadowLights.resize(0);
		shadowLightBuffer = null;
		for(a in shadowMapAtlas) a.destroy(true);
	}
}