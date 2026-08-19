package foxlite.loaders;

// TODO
import foxlite.animation.FoxAnimation;
import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMesh;
import foxlite.skin.FoxSkinData;
import haxe.Json;
import haxe.io.Bytes;

/**
	TODO
**/
class FoxGLTFLoader {

	public static function load(name:String, ?extraShaderFlags:Array<String>, ?customShaderPath:String):{meshes:Array<FoxMesh>, materials:Map<String, FoxMaterial>, ?skinData:Map<String, FoxSkinData>, ?animations:Map<String, FoxAnimation>} {
		
		return null;
	}
}