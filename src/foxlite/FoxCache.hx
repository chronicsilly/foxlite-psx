package foxlite;

import haxe.ds.StringMap;
import foxlite.FoxShader;
import foxlite.animation.FoxAnimation;
import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMesh;
import foxlite.texture.FoxTexture;
import foxlite.skin.FoxSkinData;

#if !foxlite_polymod
@dox(hide) typedef FoxTextureCollection = Map<String, FoxTexture>;
@dox(hide) typedef FoxShaderCollection = Map<String, FoxShader>;
@dox(hide) typedef FoxShaderDefinesCollection = Map<String, String>;
@dox(hide) typedef FoxMaterialCollection = Map<String, Map<String, FoxMaterial>>;
@dox(hide) typedef FoxMeshCollection = Map<String, Array<FoxMesh>>;
@dox(hide) typedef FoxAnimationCollection = Map<String, Map<String, FoxAnimation>>;
@dox(hide) typedef FoxSkinCollection = Map<String, Array<FoxSkinData>>;
#end

class FoxCache {

	public var _texture:FoxTextureCollection = new StringMap();
	public var _shaders:FoxShaderCollection = new StringMap();
	public var _shaderIncludes:FoxShaderDefinesCollection = new StringMap();
	public var _materialLibs:FoxMaterialCollection = new StringMap();
	public var _meshes:FoxMeshCollection = new StringMap();
	public var _animationLibs:FoxAnimationCollection = new StringMap();
	public var _skins:FoxSkinCollection = new StringMap();

	/**
		If enabled, will free resources on flixel's preStateSwitch signal
	**/
	public var freeResourcesOnStateSwitch:Bool = true;

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

	public static inline function skins():FoxSkinCollection {
		return FoxCache.instance._skins;
	}

	public function freeResources():Void {
		#if debug
		trace("[FoxLite > FoxCache]: CLEARING CACHE!");
		#end
		for(r in _texture) r?.destroy();
		for(r in _shaders) r?.destroy();
		for(r in _materialLibs) for(m in r) m?.destroy();
		for(r in _meshes) for(m in r) m?.destroy();
		for(r in _animationLibs) for(a in r) a?.destroy();
		for(r in _skins) for(a in r) a?.destroy();

		_texture.clear();
		_shaders.clear();
		_shaderIncludes.clear();
		_materialLibs.clear();
		_meshes.clear();
		_animationLibs.clear();
		_skins.clear();
	}

	public static function cleanup() {
		if(FoxCache.instance.freeResourcesOnStateSwitch) FoxCache.instance.freeResources();
	}
}