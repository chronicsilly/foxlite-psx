package foxlite.polyfill;

#if foxlite_polymod
import lime.utils.ArrayBufferView; // HScript iris
#end
import lime.utils.Float32Array;
import lime.utils.Float64Array;
import lime.utils.Int16Array;
import lime.utils.Int32Array;
import lime.utils.Int8Array;
import lime.utils.UInt16Array;
import lime.utils.UInt32Array;
import lime.utils.UInt8Array;
import lime.utils.UInt8ClampedArray;
// Haxe way (it can now be done in V-Slice 0.8.4)

class TypedArray {

	// Typed array types
	static final None = 0;
	static final Int8 = 1;
	static final Int16 = 2;
	static final Int32 = 3;
	static final Uint8 = 4;
	static final Uint8Clamped = 5;
	static final Uint16 = 6;
	static final Uint32 = 7;
	static final Float32 = 8;
	static final Float64 = 9;

	#if foxlite_polymod
	public inline static function Int8Array(data:Array<Int>):ArrayBufferView {
		return new ArrayBufferView(0, Int8).initArray(data);
	}

	public inline static function Int16Array(data:Array<Int>):ArrayBufferView {
		return new ArrayBufferView(0, Int16).initArray(data);
	}

	public inline static function Int32Array(data:Array<Int>):ArrayBufferView {
		return new ArrayBufferView(0, Int32).initArray(data);
	}

	public inline static function UInt8Array(data:Array<Int>):ArrayBufferView {
		return new ArrayBufferView(0, Uint8).initArray(data);
	}

	public inline static function UInt8ClampedArray(data:Array<Int>):ArrayBufferView {
		return new ArrayBufferView(0, Uint8Clamped).initArray(data);
	}

	public inline static function UInt16Array(data:Array<Int>):ArrayBufferView {
		return new ArrayBufferView(0, Uint16).initArray(data);
	}

	public inline static function UInt32Array(data:Array<Int>):ArrayBufferView {
		return new ArrayBufferView(0, Uint32).initArray(data);
	}
	
	public inline static function Float32Array(data:Array<Float>):ArrayBufferView {
		return new ArrayBufferView(0, Float32).initArray(data);
	}

	public inline static function Float64Array(data:Array<Float>):ArrayBufferView {
		return new ArrayBufferView(0, Float64).initArray(data);
	}

	#else 

	public inline static function Int8Array(data:Array<Int>):Int8Array {
		return new Int8Array(null, data);
	}

	public inline static function Int16Array(data:Array<Int>):Int16Array {
		return new Int16Array(null, data);
	}

	public inline static function Int32Array(data:Array<Int>):Int32Array {
		return new Int32Array(null, data);
	}

	public inline static function UInt8Array(data:Array<Int>):UInt8Array {
		return new UInt8Array(null, data);
	}

	public inline static function UInt8ClampedArray(data:Array<Int>):UInt8ClampedArray {
		return new UInt8ClampedArray(null, data);
	}

	public inline static function UInt16Array(data:Array<Int>):UInt16Array {
		return new UInt16Array(null, data);
	}

	public inline static function UInt32Array(data:Array<Int>):UInt32Array {
		return new UInt32Array(null, data);
	}

	public inline static function Float32Array(data:Array<Float>):Float32Array {
		return new Float32Array(null, data);
	}
	
	public inline static function Float64Array(data:Array<Float>):Float64Array {
		return new Float64Array(null, data);
	}
	#end
}