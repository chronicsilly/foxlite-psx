package foxlite.instancing;

import foxlite.polyfill.TypedArray;
import haxe.io.Bytes;
import lime.utils.Float32Array;
import openfl.display3D.Context3D;
import openfl.display3D.VertexBuffer3D;

class FoxInstanceChunkData {
	public var buffer:Float32Array;
	public var glBuffer:VertexBuffer3D;

	public function new() {}

	// -------------------------------------------------------
	public var bytes:Bytes;

	public inline function setFloat(pos:Int, v:Float):Void {
		#if (js || !foxlite_polymod)
		buffer[pos] = v;
		#else
		bytes.setFloat(pos<<1, v);
		#end
	}

	public inline function getFloat(pos:Int):Float {
		#if (js || !foxlite_polymod)
		return buffer[pos];
		#else
		return bytes.getFloat(pos<<1);
		#end
	}
	// -------------------------------------------------------

	public function reallocate(context:Context3D, size:Int) {
		glBuffer?.dispose();
		glBuffer = context.createVertexBuffer(size, 4, #if !foxlite_polymod cast #end 0);

		var init:Array<Float> = [];
		init.resize(size*4);
		
		buffer = TypedArray.Float32Array(init);
		#if js
		// js handles bytes differently, we use this instead for Bytes.blit()
		bytes = Bytes.ofData(buffer.buffer);
		#else
		bytes = #if !foxlite_polymod cast #end buffer.buffer;
		#end
	}

	public function dispose() {
		glBuffer?.dispose();
		buffer = null;
		bytes = null;
	}
}