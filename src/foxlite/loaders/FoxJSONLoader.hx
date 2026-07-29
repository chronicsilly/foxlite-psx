package foxlite.loaders;

import foxlite.FoxCache;
import foxlite.loaders.FoxLoaderUtil;
import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMesh;
import haxe.ds.StringMap;

class FoxJSONLoader {
	
	public static function load(name:String):{meshes:Array<FoxMesh>, materials:Map<String, FoxMaterial>} {
		// Check cache
		if(FoxCache.meshes().exists(name)) {
			var meshes = FoxCache.meshes().get(name);
			var materials:Map<String, FoxMaterial> = new StringMap();
			for(m in meshes) {
				if(!materials.exists(m.material.name)) materials.set(m.material.name, m.material);
			}
			return {meshes:meshes, materials: materials};
		}
		
		var modelData:Array<Dynamic> = FoxLoaderUtil.loadJSON(name);
		if((modelData?.length ?? 0) == 0) return null;

		var meshes:Array<FoxMesh> = [];
		var materials:Map<String, FoxMaterial> = new StringMap();

		var path:String = FoxLoaderUtil.path(name);

		for(model in modelData) {
			var material:FoxMaterial = null;
			if(model.material != null) {
				trace("[FoxLite > FoxJSONLoader]: Loading material file: " + model.material.split(":")[0]);
				material = FoxMaterial.fromJSON(path + model.material); // Adds to cache automatically
				if(material == null) {
					trace("[FoxLite > FoxMaterial]: Warning: material not found!! " + model.material);
				}
				else materials.set(material.name, material);
			}

			var mesh = new FoxMesh();
			mesh.setArrays(model.vertices, model.uvtData, model.indices, material, model.normals, model.colors, model.weights, model.influences);
			mesh.assetsKey = name;
			meshes.push(mesh);
		}

		FoxCache.meshes().set(name, meshes);

		return {meshes:meshes, materials: materials};
	}
}