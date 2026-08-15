package foxlite;

import haxe.ds.StringMap;
import foxlite.FoxShader;
import foxlite.animation.FoxAnimation;
import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMesh;
import foxlite.texture.FoxTexture;

#if !foxlite_polymod
typedef FoxTextureCollection = Map<String, FoxTexture>;
typedef FoxShaderCollection = Map<String, FoxShader>;
typedef FoxShaderDefinesCollection = Map<String, String>;
typedef FoxMaterialCollection = Map<String, Map<String, FoxMaterial>>;
typedef FoxMeshCollection = Map<String, Array<FoxMesh>>;
typedef FoxAnimationCollection = Map<String, Map<String, FoxAnimation>>;
#end

class FoxCache {

	public var _texture:FoxTextureCollection = new StringMap();
	public var _shaders:FoxShaderCollection = new StringMap();
	public var _shaderIncludes:FoxShaderDefinesCollection = new StringMap();
	public var _materialLibs:FoxMaterialCollection = new StringMap();
	public var _meshes:FoxMeshCollection = new StringMap();
	public var _animationLibs:FoxAnimationCollection = new StringMap();

	public static final instance = new FoxCache();

	public function new() {}

	public static inline function staticInit() {
		#if foxlite_polymod
		trace(instance);
		#end
	}

	public static inline function textures():FoxTextureCollection {
		return FoxCache.instance._texture;
	}

	public static inline function shaders():FoxShaderCollection {
		return FoxCache.instance._shaders;
	}

	public static inline function shaderIncludes():FoxShaderDefinesCollection {
		return FoxCache.instance._shaderIncludes;
	}
	
	public static inline function materialLibs():FoxMaterialCollection {
		return FoxCache.instance._materialLibs;
	}

	public static inline function meshes():FoxMeshCollection {
		return FoxCache.instance._meshes;
	}

	public static inline function animationLibs():FoxAnimationCollection {
		return FoxCache.instance._animationLibs;
	}

	public function freeResources():Void {
		trace("[FoxLite > FoxCache]: CLEARING CACHE!");
		for(r in _texture) r?.destroy();
		for(r in _shaders) r?.destroy();
		for(r in _materialLibs) for(m in r) m?.destroy();
		for(r in _meshes) for(m in r) m?.destroy();
		for(r in _animationLibs) for(a in r) a?.destroy();

		_texture.clear();
		_shaders.clear();
		_shaderIncludes.clear();
		_materialLibs.clear();
		_meshes.clear();
		_animationLibs.clear();
	}
}