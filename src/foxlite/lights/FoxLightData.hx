package foxlite.lights;

import flixel.util.FlxColor;
import foxlite.math.FoxMathUtil;
import openfl.geom.Rectangle;
import openfl.geom.Matrix3D;
import foxlite.texture.FoxTextureBuffer;
import foxlite.FoxCamera;
import foxlite.lights.FoxDirectionalLight;
import foxlite.lights.FoxLightType;
import foxlite.lights.FoxPointLight;
import foxlite.lights.FoxSpotLight;
import foxlite.lights.uniform.UniformDirectionalLight;
import foxlite.lights.uniform.UniformPointLight;
import foxlite.lights.uniform.UniformSpotLight;
import foxlite.lights.uniform.UniformAreaLight;
import foxlite.polyfill.VectorFactory;
import foxlite.renderer.FoxRenderer;
import foxlite.texture.FoxFramebuffer;
import foxlite.texture.FoxTextureFilter;
import haxe.ds.BalancedTree;
import openfl.Vector;
import openfl.geom.Vector3D;

class FoxLightData {

	public inline static final MAX_DIRECTIONAL_LIGHTS =  4;
	public inline static final MAX_POINT_LIGHTS 	  = 16;
	public inline static final MAX_SPOT_LIGHTS 		  =  8;
	public inline static final MAX_AREA_LIGHTS 		  =  8;

	public var ambientLight:Vector3D = new Vector3D(1, 1, 1);

	public final directionalLights:Array<FoxDirectionalLight> = [];
	public final orderedPointLights:BalancedTree<Float, FoxPointLight> = new BalancedTree();
	public final orderedSpotLights:BalancedTree<Float, FoxSpotLight> = new BalancedTree();
	public final orderedAreaLights:BalancedTree<Float, FoxAreaLight> = new BalancedTree();
	public final shadowLights:Array<FoxBaseLight> = [];

	// Data
	public final directionalLightBuffer:Array<UniformDirectionalLight> = [];
	public final pointLightBuffer:Array<UniformPointLight> = [];
	public final spotLightBuffer:Array<UniformSpotLight> = [];
	public final areaLightBuffer:Array<UniformAreaLight> = [];

	public var lightCount:Array<Int> = [0, 0, 0, 0];

	public var shadowCasterData:FoxTextureBuffer = new FoxTextureBuffer((MAX_DIRECTIONAL_LIGHTS + MAX_SPOT_LIGHTS)*4, 4);

	/*
		Shadow targets, used exclusively for shadowmaps.

		This is a depth texture containing portions of shadowmaps for lights.

		Due to platform texture size limits, this is a tradeoff between shadow
		texture size and how many shadows there can be at once.
	*/
	public var directionalShadowAtlas = FoxFramebuffer.createShadowMap(2, 2);
	public var spotShadowAtlas = FoxFramebuffer.createShadowMap(2, 2);
	// Point lights and Area lights should use Cubemaps instead

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
	public var spotLightShadowMapSize(default, set):Int = 512;
	
	/**
		Calculated tiles for point lights.

		This value is result of `Math.floor(shadowMapMaxWidth / spotLightShadowMapSize)`
	**/
	public var tiles2:Int = 0;

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
		// Initialize buffers
		for(i in 0...FoxLightData.MAX_DIRECTIONAL_LIGHTS) directionalLightBuffer.push(new UniformDirectionalLight());
		for(i in 0...FoxLightData.MAX_POINT_LIGHTS) pointLightBuffer.push(new UniformPointLight());
		for(i in 0...FoxLightData.MAX_SPOT_LIGHTS) spotLightBuffer.push(new UniformSpotLight());
		for(i in 0...FoxLightData.MAX_AREA_LIGHTS) areaLightBuffer.push(new UniformAreaLight());

		var gl = FoxRenderer.getContext().gl;
		var maxTexSize = gl.getParameter(gl.MAX_TEXTURE_SIZE) ?? 4096;
		shadowMapMaxWidth = maxTexSize;
		shadowMapMaxHeight = maxTexSize;
		FoxRenderer.allocationsThisFrame += (
			FoxLightData.MAX_DIRECTIONAL_LIGHTS + FoxLightData.MAX_POINT_LIGHTS +
			FoxLightData.MAX_SPOT_LIGHTS + FoxLightData.MAX_AREA_LIGHTS
		) + 5;
	}

	public static function staticInit() {
	}

	public function prepareLights(camera:FoxCamera) {
		shadowLights.resize(0);
		var i:Int = 0;
		for(light in directionalLights) {
			if(i >= FoxLightData.MAX_DIRECTIONAL_LIGHTS) break;

			var buf = directionalLightBuffer[i];
			var c = buf.color;
			c.copyFrom(light.color);
			c.scaleBy(light.energy);
			camera.__invViewMatrix.transformVectorToOutput(light.direction, buf.direction); // invView * direction

			if(light.shadow) {
				buf.casterIndex = shadowLights.length;
				shadowCasterData.setMatrix4(buf.casterIndex*16, light.viewProjection);
				shadowLights.push(light);
				buf.shadowRegion = light.shadowAtlasUV;
			}
			else buf.shadowRegion = null;

			i += 1;
		}
		lightCount[FoxLightType.DIRECTIONAL] = i;

		i = 0;
		for(light in orderedPointLights) {
			if(i >= FoxLightData.MAX_POINT_LIGHTS) break;
			
			var c = pointLightBuffer[i].color;
			c.copyFrom(light.color);
			c.scaleBy(light.energy);
			c.w = light.range;

			var p = pointLightBuffer[i].position;
			camera.viewMatrix.transformVectorToOutput(light.globalPosition, p); // view * position
			p.w = light.attenuation;

			if(light.shadow) shadowLights.push(light);
			i += 1;
		}
		lightCount[FoxLightType.POINT] = i;

		i = 0;
		for(light in orderedSpotLights) {
			if(i >= FoxLightData.MAX_SPOT_LIGHTS) break;

			var buf = spotLightBuffer[i];
			var c = buf.color;
			c.copyFrom(light.color);
			c.scaleBy(light.energy);
			c.w = light.range;

			var p = buf.position;
			camera.viewMatrix.transformVectorToOutput(light.globalPosition, p); // view * position
			p.w = light.attenuation;

			var d = buf.direction;
			camera.__invViewMatrix.transformVectorToOutput(light.direction, d); // invView * direction
			d.w = Math.cos(light.angle * FoxMathUtil.degToRad);

			if(light.shadow) {
				buf.casterIndex = shadowLights.length;
				shadowCasterData.setMatrix4(buf.casterIndex*16, light.viewProjection);
				shadowLights.push(light);
				buf.shadowRegion = light.shadowAtlasUV;
			}
			else buf.shadowRegion = null;
			i += 1;
		}
		lightCount[FoxLightType.SPOT] = i;

		i = 0;
		for(light in orderedAreaLights) {
			if(i >= FoxLightData.MAX_AREA_LIGHTS) break;

			var c = areaLightBuffer[i].color;
			c.copyFrom(light.color);
			c.scaleBy(light.energy);
			c.w = light.range;

			var p = areaLightBuffer[i].position;
			camera.viewMatrix.transformVectorToOutput(light.globalPosition, p); // view * position
			p.w = light.attenuation;

			var d = areaLightBuffer[i].direction;
			camera.__invViewMatrix.transformVectorToOutput(light.direction, d); // invView * direction
			d.w = light.getSdfRange();

			var s = areaLightBuffer[i].sdfData;
			s.copyFrom(light.sdfData);
			s.w = light.sdfData.w;

			if(light.shadow) shadowLights.push(light);
			i += 1;
		}
		lightCount[FoxLightType.AREA] = i;

		// Shadowmap atlas tiling
		if(shadowLights.length > 0) {
			prepareShadowLights(camera);
			shadowCasterData.updateGPU();
		}
	}

	public function prepareShadowLights(camera:FoxCamera) {
		var caster:Int = 0, i:Int = 0, j:Int = 0;
		for(idx=>light in shadowLights) {
			switch(light.getType()) {
				case FoxLightType.DIRECTIONAL: {
					var atlas = directionalShadowAtlas;
					var uv = light.shadowAtlasUV;
					var r = light.shadowAtlasRect;

					// Tiles X and Y
					r.setTo(i % tiles0, Std.int(i / tiles0), 1);
					r.w = directionalLightShadowMapSize;
					r.scaleBy(directionalLightShadowMapSize);

					growShadowMapBound(atlas, Std.int(r.x + r.z), Std.int(r.y + r.w)); // Allocate shadowmap
					
					// UV map region
					uv.x = r.x / atlas.width;
					uv.y = r.y / atlas.height;
					uv.z = uv.x + r.z / atlas.width;
					uv.w = uv.y + r.w / atlas.height;
					i += 1;
				};
				case FoxLightType.SPOT: {
					var atlas = spotShadowAtlas;
					var uv = light.shadowAtlasUV;
					var r = light.shadowAtlasRect;

					// Tiles X and Y
					r.setTo(i % tiles2, Std.int(i / tiles2), 1);
					r.w = spotLightShadowMapSize;
					r.scaleBy(spotLightShadowMapSize);

					growShadowMapBound(atlas, Std.int(r.x + r.z), Std.int(r.y + r.w)); // Allocate shadowmap
					
					// UV map region
					uv.x = r.x / atlas.width;
					uv.y = r.y / atlas.height;
					uv.z = uv.x + r.z / atlas.width;
					uv.w = uv.y + r.w / atlas.height;
					i += 1;
				};
			}
		}
	}

	public function getShadowAtlas(lightType:FoxLightType):Null<FoxFramebuffer> {
		return switch(lightType) {
			case FoxLightType.DIRECTIONAL: directionalShadowAtlas;
			case FoxLightType.SPOT: spotShadowAtlas;
			default: null;
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

	public function setAmbientLightFlxColor(color:FlxColor) {
		ambientLight.setTo(color.redFloat, color.greenFloat, color.blueFloat);
	}

	public function updateShaderLights(shader:FoxShader) {
		shader.setVector3("ambientLight", ambientLight);
		shader.setIntArray("lightCount", lightCount);

		for(i in 0...lightCount[FoxLightType.DIRECTIONAL]) {
			var packed = directionalLightBuffer[i];
			shader.setVector4('directionalLights[$i].color', packed.color);
			shader.setVector4('directionalLights[$i].direction', packed.direction);
			shader.setInt('directionalLights[$i].shadowCaster', packed.casterIndex);
			if(packed.casterIndex > -1) {
				shader.setVector4('directionalLights[$i].shadowRegion', packed.shadowRegion);
			}
		}

		for(i in 0...lightCount[FoxLightType.POINT]) {
			var packed = pointLightBuffer[i];
			shader.setVector4('pointLights[$i].color', packed.color);
			shader.setVector4('pointLights[$i].position', packed.position);
			shader.setInt('pointLights[$i].shadowCaster', packed.casterIndex);
		}

		for(i in 0...lightCount[FoxLightType.SPOT]) {
			var packed = spotLightBuffer[i];
			shader.setVector4('spotLights[$i].color', packed.color);
			shader.setVector4('spotLights[$i].position', packed.position);
			shader.setVector4('spotLights[$i].direction', packed.direction);
			shader.setInt('spotLights[$i].shadowCaster', packed.casterIndex);
			if(packed.casterIndex > -1) {
				shader.setVector4('spotLights[$i].shadowRegion', packed.shadowRegion);
			}
		}

		for(i in 0...lightCount[FoxLightType.AREA]) {
			var packed = areaLightBuffer[i];
			shader.setVector4('areaLights[$i].color', packed.color);
			shader.setVector4('areaLights[$i].position', packed.position);
			shader.setVector4('areaLights[$i].direction', packed.direction);
			shader.setVector4('areaLights[$i].sdfData', packed.sdfData);
			shader.setInt('areaLights[$i].shadowCaster', packed.casterIndex);
		}

		if(shadowLights.length > 0) { // If there's at least one shadow
			// Caster data
			shader.setSampler2D('shadowCasterData', shadowCasterData);
			shader.setFloat('shadowCasterDataSize', shadowCasterData.pixelSize.x);

			// Directional lights
			shader.setSampler2D('shadowtex0', directionalShadowAtlas.depthBuffer);
			shader.setFloatArray('shadowtex0size', [1 / directionalShadowAtlas.width, 1 / directionalShadowAtlas.height]);
			// Spot lights
			shader.setSampler2D('shadowtex2', spotShadowAtlas.depthBuffer);
			shader.setFloatArray('shadowtex2size', [1 / spotShadowAtlas.width, 1 / spotShadowAtlas.height]);
		}
		else { // Cleanup
			var i = shader.textureInput;
			i.remove('shadowCasterData');
			i.remove('shadowtex0');
			i.remove('shadowtex2');
		}
	}

	public function clearShadowMaps() {
		var context = FoxRenderer.getContext();
		if(directionalLights.length > 0) {
			FoxRenderer.setTarget(directionalShadowAtlas);
			context.clear();
		}

		@:privateAccess if(orderedSpotLights.root != null) {
			FoxRenderer.setTarget(spotShadowAtlas);
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
		directionalLightBuffer.resize(0);
		pointLightBuffer.resize(0);
		spotLightBuffer.resize(0);
		areaLightBuffer.resize(0);
		shadowCasterData.destroy();
		directionalShadowAtlas.destroy();
		spotShadowAtlas.destroy();
		lightCount = null;
	}
}