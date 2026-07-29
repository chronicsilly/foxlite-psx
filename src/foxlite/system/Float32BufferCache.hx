package foxlite.system;

import foxlite.polyfill.TypedArray;
import haxe.ds.IntMap;
import lime.utils.Float32Array;

/**
	A collection of `Float32Array` that's meant to be used as a typed array storage from an existing data.
**/
class Float32BufferCache {
	public static final buffers:Map<Int, Float32Array> = new IntMap();

	/**
		Gets a buffer of specified length by `data.length` and fills it with `data`. Else one is created and added to the cache.

		Use this to prevent wasteful allocations when creating multiple typed arrays of the same length that
		have the sole purpose of holding data.

		For example, this function is used in `FoxShader` to write uniform arrays, and gets called a lot:
		```haxe
			var buffer = Float32BufferCache.get(data);
			gl.uniform1fv(location, buffer);
		```
		After that, we no longer need the buffer, so we can call `get()` again for the next uniform rather than letting it be garbage collected.
	**/
	#if FOXLITE_NO_BUFFER_CACHE
	public inline static function get(data:Array<Float>):Float32Array {
		return TypedArray.Float32Array(data);
	}
	#else
	public static function get(data:Array<Float>):Float32Array {
		var buffer:Float32Array = buffers.get(data.length);
		
		// Create if it doesn't exist
		if(buffer == null) {
			buffer = TypedArray.Float32Array(data);
			buffers.set(data.length, buffer);
		}
		else buffer.set(data);
		return buffer;
	}
	#end

	public inline static function clear() {
		buffers.clear();
	}
}