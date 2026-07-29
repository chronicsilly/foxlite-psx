package foxlite;

import foxlite.FoxShader;
import foxlite.animation.FoxAnimation;
import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMesh;
import foxlite.texture.FoxTexture;

#if !foxlite_polymod
typedef FoxTextureCollection = Map<String, FoxTexture>;
typedef FoxShaderCollection = Map<String, FoxShader>;
typedef FoxMaterialCollection = Map<String, Map<String, FoxMaterial>>;
typedef FoxMeshCollection = Map<String, Array<FoxMesh>>;
typedef FoxAnimationCollection = Map<String, Map<String, FoxAnimation>>;
#else
import haxe.ds.StringMap;
#end

class FoxCache {

	// My HScript is a machine that turns `static var myVar = new ANYTHING();` into **Null Object Reference**

	// Fr now,
	// (Polymod 1.8.0): Static variables result in "Null Object Reference" errors
	// Unless you read them in a static context
	// It's been weeks trying to fix that issue, and I gave up
	// So instead we scrap that and use the module instance instead

	public var _texture:FoxTextureCollection = #if foxlite_polymod new StringMap(); #else new FoxTextureCollection(); #end
	public var _shaders:FoxShaderCollection = #if foxlite_polymod new StringMap(); #else new FoxShaderCollection(); #end
	public var materialCollection:FoxMaterialCollection = #if foxlite_polymod new StringMap(); #else new FoxMaterialCollection(); #end
	public var _meshes:FoxMeshCollection = #if foxlite_polymod new StringMap(); #else new FoxMeshCollection(); #end
	public var animationLibCollection:FoxAnimationCollection = #if foxlite_polymod new StringMap(); #else new FoxAnimationCollection(); #end

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
	
	public static inline function materialLibs():FoxMaterialCollection {
		return FoxCache.instance.materialCollection;
	}

	public static inline function meshes():FoxMeshCollection {
		return FoxCache.instance._meshes;
	}

	public static inline function animationLibs():FoxAnimationCollection {
		return FoxCache.instance.animationLibCollection;
	}

	public function freeResources():Void {
		trace("[FoxLite > FoxCache]: CLEARING CACHE!");
		for(r in _texture) r?.destroy();
		for(r in _shaders) r?.destroy();
		for(r in materialCollection) for(m in r) m?.destroy();
		for(r in _meshes) for(m in r) m?.destroy();
		for(r in animationLibCollection) for(a in r) a?.destroy();

		_texture.clear();
		_shaders.clear();
		materialCollection.clear();
		_meshes.clear();
		animationLibCollection.clear();
	}
}