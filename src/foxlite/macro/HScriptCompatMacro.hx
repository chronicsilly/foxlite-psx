// Intended for source 
package foxlite.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;

class HScriptCompatMacro {

	// Runs this macro
	public static function run() {
		privateAccess();
		vectorAccess();
	}

	/**
		Allow accessing private fields.
		This is the main reason FoxLite works in HScript.
	**/
	public static function privateAccess() {
		for(target in [
			"openfl.display3D.Context3D",
			"openfl.display3D.Program3D",
			"openfl.display3D.textures.TextureBase",
			"openfl.display.BitmapData",
			"openfl.display3D.IndexBuffer3D",
			"openfl.display3D.VertexBuffer3D",
			"openfl.display.ShaderParameter"
		]) {
			haxe.macro.Compiler.addGlobalMetadata(target, "@:allow(foxlite)", true, true, false);
		}		
    }

	/**
		Removes __array from all openfl.Vector access.

		We need __array to index `Vector.rawData` via ArrayAccess in HScript.
		This is not needed in haxe, but to keep code unchanged between both, 
		we use this macro.
	**/
	public static function vectorAccess() {

		for(fox in [
			"foxlite.math.FoxMathUtil",
			"foxlite.FoxObject",
			"foxlite.animation.FoxLerp",
			"foxlite.FoxCamera",
			"foxlite.texture.FoxTextureBuffer",
			"foxlite.mesh.FoxMesh",
			"foxlite.skin.FoxSkinData",
			"foxlite.lights.FoxLightData",
			"foxlite.instancing.FoxInstanceData",
			"foxlite.lights.FoxDirectionalLight"
		]) {
			haxe.macro.Compiler.addGlobalMetadata(fox, "@:build(foxlite.macro.HScriptCompatMacro.build_VectorAccess())", true, true, false);
		}
	}
	
	public static function build_VectorAccess():Array<Field> {
		var fields = Context.getBuildFields();
		for(field in fields) {
			switch(field.kind) {
				case FFun(fn):
					if(fn.expr != null) fn.expr = remove__array(fn.expr);
				default:
			}
		}
		return fields;
	}

	// Remove __array from all openfl.Vector access
	private static function remove__array(e:Expr):Expr {
		return switch(e.expr) {
			case EField(obj, "__array"): {
				obj;
			}
			case _:
				ExprTools.map(e, remove__array); // Recurse
		}
	}
	
}
#end