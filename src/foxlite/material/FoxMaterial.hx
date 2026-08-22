package foxlite.material;

import Reflect;
import foxlite.FoxShader;
import foxlite.loaders.FoxMTLLoader;
import foxlite.material.FoxBlendMode;
import foxlite.material.FoxDepthCompareMode;
import foxlite.material.FoxTriangleFace;
import foxlite.loaders.FoxJSONLoader;
import foxlite.renderer.FoxRenderer;
import foxlite.stencil.FoxStencilAction;
import foxlite.texture.FoxTexture;
import haxe.ds.StringMap;
import lime.math.Vector2;
import lime.math.Vector4;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class FoxMaterial {

	/**
		Global ID to keep track of FoxMaterials, increments when a new one is created
	**/
	public static var __GLOBAL_ID = 0x69;

	/**
		Internal id for this material, do not change it
	**/
	var __id(default, set):Int = 0;

	/**
		A sortable identifier for the `BalancedTree` draw list.
		Cached for speed, do not modify.
	**/
	public var __tid:String = "";

	public var depthTest:Bool = true;
	public var depthFunc:FoxDepthCompareMode = FoxDepthCompareMode.LESS;
	public var depthWrite:Bool = true;
	public var culling:FoxTriangleFace = FoxTriangleFace.NONE;
	public var shadowCulling:FoxTriangleFace = FoxTriangleFace.FRONT;
	public var blendMode:FoxBlendMode = FoxBlendMode.NONE;
	public var alphaScissor:Float = 0; // Pixels with alpha below this threshold will be discarded
	public var stencil:FoxStencilAction; // Assign a FoxStencilAction to enable stencil test
	public var textures:Map<String, FoxTexture> = new StringMap();
	public var params:Map<String, Dynamic> = new StringMap();
	public var name:String;
	public var shader:FoxShader = null;
	public var assetsKey:String;

	/**
		This controls the rendering order of materials.

		Lower priority means the model will be rendered before other models.
	**/
	public var renderPriority(default, set):Int = 0;

	/**
		The render mode of this material, switches between `GL.TRIANGLES` and `GL.LINES`.

		To render models in wireframe mode, use the later.
	**/
	public var renderMode:Int = 0x0004; // Only for initialization, corresponds to GL.TRIANGLES

	/**
		Used when `renderMode`  is `GL.LINES`
	**/
	public var lineWidth:Float = 1;

	public function new(?shader_:FoxShader) {
		FoxMaterial.__GLOBAL_ID += 1;
		__id = __GLOBAL_ID;

		// Write default uniforms
		params.set("color", [1, 1, 1, 1]);
		params.set("uvOffset", [0, 0]);
		params.set("uvScale", [1, 1]);
		params.set("uScattering", 0.0);
		shader = shader_;
	}

	/**
		Uploads uniform data to the shader when this material is active.
	**/
	public function pushShaderUniforms(passShader:FoxShader) {
		for(param in params.keyValueIterator()) {
			// HScript Polymod has blacklisted Type.typeof so no switch case for us.
			if(Std.isOfType(param.value, Bool)) passShader.setBool(param.key, param.value);
			else if(Std.isOfType(param.value, Float) || Std.isOfType(param.value, Int)) {
				if(passShader.uniformCache.get(param.key)?.type == UType.INT) passShader.setInt(param.key, param.value);
				else passShader.setFloat(param.key, param.value);
			}
			else if(Std.isOfType(param.value, Array)) passShader.setFloatArray(param.key, param.value);
			else if(Std.isOfType(param.value, Matrix3D)) passShader.setMatrix4(param.key, param.value);
			else if(Std.isOfType(param.value, Vector2)) passShader.setVector2(param.key, param.value);
			else if(Std.isOfType(param.value, Vector3D) || Std.isOfType(param.value, Vector4)) {
				if(passShader.uniformCache.get(param.key)?.type == UType.FLOAT_VEC3) passShader.setVector3(param.key, param.value);
				else passShader.setVector4(param.key, param.value);
			}
		}
		
		for(tex in textures.keyValueIterator()) passShader.setSampler2D(tex.key, tex.value);
		passShader.setFloat("alphaScissor", alphaScissor);
	}

	/**
		Copies this material object, does not create new data on GPU
	**/
	public function copy():FoxMaterial {
		var mat = new FoxMaterial();
		mat.depthTest = depthTest;
		mat.depthFunc = depthFunc;
		mat.depthWrite = depthWrite;
		mat.culling = culling;
		mat.shadowCulling = culling;
		mat.blendMode = blendMode;
		mat.alphaScissor = alphaScissor;
		for(k=>v in textures) mat.textures.set(k,v);
		for(k=>v in params) mat.params.set(k,v);
		mat.name = name;
		mat.shader = shader;
		mat.renderPriority = renderPriority;
		mat.lineWidth = lineWidth;
		mat.stencil = stencil;
		return mat;
	}

	public function destroy() {
		params.clear();
		textures.clear();
		shader = null;

		if(assetsKey == null) return;
		var cache = FoxCache.materialLibs().get(assetsKey);
		if(cache != null) {
			cache.remove(this.name);
			if(!cache.keys().hasNext()) FoxCache.materialLibs().remove(assetsKey);
		}
	}

	public static function create(shader:FoxShader, ?textures:Map<String, FoxTexture>, ?params:Map<String, Dynamic>):FoxMaterial {
		var material = new FoxMaterial();
		material.shader = shader ?? FoxShader.fromAsset(FoxShader.BASIC);
		if(textures != null) for(k=>v in textures) material.textures.set(k,v);
		if(params != null) for(k=>v in params) material.params.set(k,v);
		return material;
	}

	/**
		Short and more straightforward version of `create()`
	**/
	public inline static function createCustom(shaderPath:String, ?shaderFlags:Array<String>, ?textures:Map<String, FoxTexture>, ?params:Map<String, Dynamic>):FoxMaterial {
		return FoxMaterial.create(FoxShader.fromAsset(shaderPath, shaderFlags), textures, params);
	}

	/**
		Creates a material with foxlite's basic ubershader by default
	**/
	public inline static function createBasic(?shaderFlags:Array<String>, ?textures:Map<String, FoxTexture>, ?params:Map<String, Dynamic>):FoxMaterial {
		return FoxMaterial.create(FoxShader.fromAsset(FoxShader.BASIC, shaderFlags), textures, params);
	}

	/**
		Creates a material with foxlite's minimal shader by default

		The minimal shader handles very basic 3D rendering, and does not have any lights
	**/
	public inline static function createMinimal(?shaderFlags:Array<String>, ?textures:Map<String, FoxTexture>, ?params:Map<String, Dynamic>):FoxMaterial {
		return FoxMaterial.create(FoxShader.fromAsset(FoxShader.MINIMAL, shaderFlags), textures, params);
	}

	/**
		Creates a material with foxlite's sky shader by default
	**/
	public inline static function createSky(texture:FoxTexture):FoxMaterial {
		return FoxMaterial.createSkyCustom(FoxShader.SKY, texture);
	}

	/**
		Creates a material with a custom sky shader, this also accepts custom shader parameters
	**/
	public static function createSkyCustom(shaderPath:String, texture:FoxTexture, ?params:Map<String, Dynamic>):FoxMaterial {
		var mat = FoxMaterial.create(FoxShader.fromAsset(shaderPath), texture != null ? ["skyTexture" => texture] : null, params);
		mat.depthTest = false; 
		mat.blendMode = FoxBlendMode.NONE;
		mat.depthWrite = false;
		mat.renderPriority = -1000; // Render before anything
		return mat;
	}
	
	/**
		Loads a material from a Foxlite's custom JSON format

		@returns A Map containing material entries from the JSON, or a single FoxMaterial if specified with `"path/to/mat:<material name>"`
	**/
	public static function fromJSON(name:String):Any {
		var extra = name.split(":"); // You can do materials/matfile:MyMaterial to pick a specific one from the library
		var matNameFile = extra[1];
		name = extra[0];

		var materials = FoxJSONLoader.loadMaterialLibrary(name);

		return matNameFile == null ? materials : materials.get(matNameFile);
	}

	/**
		Loads a material from a MTL file

		@returns A Map containing material entries from the MTL, or a single FoxMaterial if specified with `"path/to/mat:<material name>"`
	**/
	public static function fromMTL(name:String):Any {
		var extra = name.split(":"); // You can do materials/matfile:MyMaterial to pick a specific one from the library
		var matNameFile = extra[1];
		name = extra[0] + '.mtl';

		var materials = FoxMTLLoader.load(name);

		return matNameFile == null ? materials : materials.get(matNameFile);
	}

	private function set___id(v:Int):Int {
		this.__id = v;
		this.__tid = '${this.renderPriority}@${v}';
		return v;
	}

	private function set_renderPriority(v:Int):Int {
		if(v == this.renderPriority) return v;
		this.renderPriority = v;
		this.__tid = '${v}@${this.__id}';
		FoxRenderer.mustRebuildDrawGroups = true;
		return v;
	}
}

