package foxlite.loaders;

import haxe.Json;
import openfl.utils.Assets;

#if polymod
import funkin.Paths;
#end

class FoxLoaderUtil {

	// These are dynamic so you can change them at runtime

	public static #if !foxlite_polymod dynamic #end function jsonPath(name:String):String {
		#if polymod
		return Paths.json(name);
		#else
		return 'assets/data/$name.json';
		#end
	}

	public static #if !foxlite_polymod dynamic #end function filePath(name:String):String {
		#if polymod
		return Paths.file(name);
		#else
		return 'assets/$name';
		#end
	}

	public static #if !foxlite_polymod dynamic #end function imagePath(name:String):String {
		#if polymod
		return Paths.image(name);
		#else
		return 'assets/images/$name.png';
		#end
	}

	public static #if !foxlite_polymod dynamic #end function shaderVert(name:String):String {
		#if polymod
		return Paths.vert(name);
		#else
		return 'assets/shaders/$name.vert';
		#end
	}

	public static #if !foxlite_polymod dynamic #end function shaderFrag(name:String):String {
		#if polymod
		return Paths.frag(name);
		#else
		return 'assets/shaders/$name.frag';
		#end
	}

	public static #if !foxlite_polymod dynamic #end function shaderIncludeRoot(name:String):String {
		return 'shaders/$name';
	}

	public static function loadJSON(name:String) {
		var path = jsonPath(name);
		if(!Assets.exists(path)) return null;
		return Json.parse(Assets.getText(path));
	}

	public static function loadText(name:String):String {
		var path = filePath(name);
		if(!Assets.exists(path)) return null;
		return Assets.getText(path);
	}
	
	/**
		Iterates a String for each line separated by `sep`

		@param s The input String
		@param cb The callback function that will be executed for each chunk
		@param sep Custom line separator, default is "\n"
	**/
	public static function forEachLine(s:String, cb:(chunk:String) -> Void, sep:String="\n") {
		var pos = 0;
		var len = -1;
		while(true) {
			len = s.indexOf(sep, pos);
			cb(s.substr(pos, len > -1 ? len-pos : null));
			pos = len+1;
			if(len == -1) break;
		}
	}

	/**
		Returns a file path without the extension
	**/
	public static function file(f:String):String {
		var i = f.lastIndexOf(".");
		return i == -1 ? f : f.substr(0, i);
	}

	/**
		Returns a file path without the file
	**/
	public static function path(f:String):String {
		return f.substr(0, f.lastIndexOf('/')+1);
	}
}