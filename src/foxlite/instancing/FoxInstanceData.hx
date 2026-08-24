package foxlite.instancing;

import flixel.util.FlxColor;
import foxlite.instancing.FoxInstanceChunkData;
import foxlite.math.FoxMathUtil;
import foxlite.renderer.FoxRenderer;
import haxe.io.Bytes;
import lime.utils.Float32Array;
import openfl.display3D.Context3D;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class FoxInstanceData {

	public var column0:FoxInstanceChunkData = new FoxInstanceChunkData();
	public var column1:FoxInstanceChunkData = new FoxInstanceChunkData();
	public var column2:FoxInstanceChunkData = new FoxInstanceChunkData();
	public var color:FoxInstanceChunkData = new FoxInstanceChunkData();

	var __tmpBuffer = new Float32Array(4);
	var _bytes:Bytes;

	// Temporary matrix stuffs
	var __tempMatrix:Matrix3D = new Matrix3D();

	public var context:Context3D;

	public function new() {
		context = FoxRenderer.getContext();
		#if js
		// js handles bytes differently, we use this instead for Bytes.blit()
		_bytes = Bytes.ofData(__tmpBuffer.buffer);
		#else
		_bytes = cast __tmpBuffer.buffer;
		#end
	}

	public function reallocate(size:Int) {
		column0.reallocate(context, size);
		column1.reallocate(context, size);
		column2.reallocate(context, size);
		color.reallocate(context, size);

		// Initialize
		
		size *= 4;
		var i:Int = 0, j:Int = 1, k:Int = 2;
		while(i < size) {
			column0.setFloat(i, 1); // col 1, row 1
			column1.setFloat(j, 1); // col 2, row 2
			column2.setFloat(k, 1); // col 3, row 3

			color.setFloat(i, 1); // Color
			color.setFloat(j, 1);
			color.setFloat(k, 1);
			color.setFloat(i+3, 1);
			i += 4; j += 4; k += 4;
		}

		column0.glBuffer.uploadFromTypedArray(column0.buffer);
		column1.glBuffer.uploadFromTypedArray(column1.buffer);
		column2.glBuffer.uploadFromTypedArray(column2.buffer);
		color.glBuffer.uploadFromTypedArray(color.buffer);
			
		FoxRenderer.allocationsThisFrame += 8;
	}

	public function setInstanceTransform(pos:Int, transform:Matrix3D) {
		pos *= 4;
		var a = transform.rawData.__array;
		/*
		* We're writing it as a 3x4 matrix:
		*  0  1  2  X
		*  4  5  6  X
		*  8  9 10  X
		* 12 13 14  X
		*/
		var i:Int = 0, j:Int = 1, k:Int = 2;
		for(p in pos...pos+4) {
			column0.setFloat(p, a[i]);
			column1.setFloat(p, a[j]);
			column2.setFloat(p, a[k]);
			i += 4; j += 4; k += 4;
		}
	}

	public function setInstanceTransformSeparate(pos:Int, ?position:Vector3D, ?rotation:Vector3D, ?scale:Vector3D) {
		FoxMathUtil.transformMatrix(__tempMatrix, position ?? FoxMathUtil.ZERO, rotation ?? FoxMathUtil.ZERO, scale ?? FoxMathUtil.ONE);
		setInstanceTransform(pos, __tempMatrix);
	}

	public function getInstanceTransform(pos:Int):Matrix3D {
		pos *= 4;
		var transform = new Matrix3D();
		var a = transform.rawData.__array;

		var i:Int = 0, j:Int = 1, k:Int = 2;
		for(p in pos...pos+4) {
			a[i] = column0.getFloat(p);
			a[j] = column1.getFloat(p);
			a[k] = column2.getFloat(p);
			i += 4; j += 4; k += 4;
		}
		FoxRenderer.allocationsThisFrame += 1;
		return transform;
	}

	public function setInstanceColor(pos:Int, col:Vector3D) {
		pos *= 4;
		color.setFloat(pos  , col.x);
		color.setFloat(pos+1, col.y);
		color.setFloat(pos+2, col.z);
		color.setFloat(pos+3, col.w);
	}

	public function setInstanceFlxColor(pos:Int, col:FlxColor) {
		pos *= 4;
		color.setFloat(pos  , col.redFloat);
		color.setFloat(pos+1, col.greenFloat);
		color.setFloat(pos+2, col.blueFloat);
		color.setFloat(pos+3, col.alphaFloat);
	}

	public function getInstanceColor(pos:Int):Vector3D {
		pos *= 4;
		FoxRenderer.allocationsThisFrame += 1;
		return new Vector3D(
			color.getFloat(pos  ),
			color.getFloat(pos+1),
			color.getFloat(pos+2),
			color.getFloat(pos+3)
		);
	}

	public function getInstanceFlxColor(pos:Int):FlxColor {
		pos *= 4;
		return FlxColor.fromRGBFloat(
			color.getFloat(pos  ),
			color.getFloat(pos+1),
			color.getFloat(pos+2),
			color.getFloat(pos+3)
		);
	}

	public function flushAll() {
		FoxRenderer.updateVertexBuffer(context, column0.glBuffer, column0.buffer);
		FoxRenderer.updateVertexBuffer(context, column1.glBuffer, column1.buffer);
		FoxRenderer.updateVertexBuffer(context, column2.glBuffer, column2.buffer);
		FoxRenderer.updateVertexBuffer(context, color.glBuffer, color.buffer);
	}

	public function flushInstance(instance:Int) {
		// Blit instance data bytes to temp
		// Then upload them
		var offset:Int = instance * 4;
		var i:Int = instance * 16; // 4 components x 4 bytes
		_bytes.blit(0, column0.bytes, i, 16);
		FoxRenderer.updateVertexBuffer(context, column0.glBuffer, __tmpBuffer, offset);
		_bytes.blit(0, column1.bytes, i, 16);
		FoxRenderer.updateVertexBuffer(context, column1.glBuffer, __tmpBuffer, offset);
		_bytes.blit(0, column2.bytes, i, 16);
		FoxRenderer.updateVertexBuffer(context, column2.glBuffer, __tmpBuffer, offset);
		_bytes.blit(0, color.bytes, i, 16);
		FoxRenderer.updateVertexBuffer(context, color.glBuffer, __tmpBuffer, offset);
	}

	public function destroy() {
		column0.dispose();
		column1.dispose();
		column2.dispose();
		color.dispose();
	}
}