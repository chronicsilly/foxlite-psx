/*
* Polyfill for HScript Iris (not needed anymore)
* openfl.Vector can't be imported, but you can use already created vectors
*/
package foxlite.polyfill;

import flixel.graphics.tile.FlxDrawTrianglesItem; // Needed for: (openfl) Vector<Float>, Vector<Int>
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

#if !foxlite_polymod
import openfl.Vector;
#end

// For openfl.Vector<Float>, Vector<Int> and Vector<Vector3D>
// openfl.Vector or DrawData cannot be imported
class VectorFactory {
	static final cache:FlxDrawTrianglesItem = new FlxDrawTrianglesItem();
	static final cacheV:Vector<Vector3D> = new Matrix3D().decompose();

	public static function staticInit() {
		while(cacheV.length > 0) cacheV.pop();	
	}

	public static function Float(?array:Array<Float>):Vector<Float> {
		var v = cache.vertices.copy();
		if(array != null) for(a in array) v.push(a);
		return v;
	}

	public static function Int(?array:Array<Int>):Vector<Int> {
		var v = cache.indices.copy();
		if(array != null) for(a in array) v.push(a);
		return v;
	}
	
	public static function Vector3D(?array:Array<Vector3D>):Vector<Vector3D> {
		var v = cacheV.copy();
		if(array != null) for(a in array) v.push(a);
		return v;
	}
}