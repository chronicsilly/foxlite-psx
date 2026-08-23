/*
*    ___           __ _ _       
*   / __\____  __ / /(_) |_ ___
*  / _\/ _ \ \/ // / | | __/ _ \
* / / | (_) >  </ /__| | ||  __/
* \/   \___/_/\_\____/_|\__\___| by dwdvIl
*                              
* 	     -- FoxLayer --
* 
* Simple Layer Mask implementation
* Helps you control which models / materials to draw
* There are 32 layers available (0 to 31)
* Use get([0, 1, 2...]) to get hashes for those layers
* Use add/remove to modify hashes 
* Use check() to check if a hash has a layer
* 
*
*/

package foxlite;

#if !foxlite_polymod abstract #else class #end FoxLayer #if !foxlite_polymod (Int) from Int to Int #end {

	public inline static final ALL:Int = 0xFFFFFFFF; // precomputed hash for get([0...31])

	/**
		Calculates layer hash based on array of <layer number>
	**/
	public static function get(layers:Array<Int>):FoxLayer {
		var layer:FoxLayer = 0;
		for(l in layers) layer |= 1 << l;
		return layer;
	}

	public inline static function layer(layer:Int):FoxLayer {
		return 1<<layer;
	}

	/**
		Calculates layer hash based on a string sequence of 1s and 0s,
		from right to left.
	*/
	public static function fromRadix2String(layers:String):FoxLayer {
		var layer:FoxLayer = 0;
		var len:Int = layers.length;
		for(i in 0...len) if(layers.charAt(i) == '1') layer |= 1 << (len-i-1);
		return layer;
	}

	// Adds layers to A
	public inline static function add(a:FoxLayer, b:FoxLayer):FoxLayer {
		return a | b;
	}

	// Removes layers from A
	public inline static function remove(a:FoxLayer, b:FoxLayer):FoxLayer {
		return a & ~b;
	}

	// Checks if a layer or layers B are in the group A
	public inline static function check(a:FoxLayer, b:FoxLayer):Bool {
		return a & b != 0;
	}
}