package foxlite.math;

import foxlite.polyfill.VectorFactory;
import foxlite.renderer.FoxRenderer;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

// If you're wondering why there's different names for each created matrix in the functions
// it's because for some reason if they have the same name, their values get overwriten
// even if they're in completely different scopes!!!!! 
// Edit: this has been written in version 0.8.1, after updating to 0.8.3, the issue was fixed

class FoxMathUtil {

	public inline static final degToRad =  0.0174532925199433;
	public inline static final radToDeg = 57.2957795130823209;
	public inline static final TAU = 	   6.2831853071795865; // PI x 2
	public inline static final PI_2 = 	   1.5707963267948967; // PI / 2

	/**
		Cache temporary vectors
	**/
	public static final __tempVector = new Vector3D();
	public static final __tempVector2 = new Vector3D();
	public static final __tempVector3 = new Vector3D();

	/**
		Cached Identity values so no allocation happens when calling openfl's `Matrix3D.identity()`
	**/
	public static final MATRIX_IDENTITY = VectorFactory.Float([1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]);

	// Vector3D Axes
	public static final RIGHT 	  = new Vector3D(1, 0, 0);
	public static final UP 		  = new Vector3D(0, 1, 0);
	public static final FORWARD	  = new Vector3D(0, 0, 1);
	public static final ZERO 	  = new Vector3D(0, 0, 0);
	public static final ONE 	  = new Vector3D(1, 1, 1);

	public static function staticInit() {
		#if foxlite_polymod
		trace(degToRad, radToDeg, RIGHT, UP, FORWARD, ZERO, ONE, TAU, PI_2, __tempVector, __tempVector2, __tempVector3, MATRIX_IDENTITY);
		#end
	}

	public static function perspectiveMatrix(mp:Matrix3D, fov:Float, aspect:Float, near:Float, far:Float):Matrix3D {
		var ZRANG = near - far;
		fov = 1 / Math.tan((fov * 0.5) * degToRad);
		
		mp.copyRawDataFrom(MATRIX_IDENTITY); // identity()
		var a = mp.rawData.__array;
		a[0] = fov / aspect;
		a[5] = fov;
		a[10] = -(-near - far) / ZRANG;
		a[11] = 2.0 * far * near / ZRANG;
		a[14] = -1;
		a[15] = 0;
		mp.transpose();
		FoxRenderer.allocationsThisFrame += 1;
		return mp;
	}

	public static function perspectiveMatrixClipFast(mp:Matrix3D, near:Float, far:Float):Matrix3D {
		var ZRANG = near - far;
		var a = mp.rawData.__array;
		a[10] = -(-near - far) / ZRANG;
		a[14] = 2.0 * far * near / ZRANG;
		return mp;
	}

	public static function createPerspective(fov:Float, aspect:Float, near:Float, far:Float):Matrix3D {
		FoxRenderer.allocationsThisFrame += 1;
		return perspectiveMatrix(new Matrix3D(), fov, aspect, near, far);
	}
	
	public static function orthogonalMatrix(mo:Matrix3D, size:Float, aspect:Float, near:Float, far:Float):Matrix3D {
		var right = size * 0.5;
		var left = -right;
		var top = size / aspect * 0.5;
		var bottom = -top;

		mo.copyRawDataFrom(MATRIX_IDENTITY); // identity()
		
		var a = mo.rawData.__array;
		a[0] = 2.0 / (right - left);
		a[3] = -((right + left) / (right - left));
		a[5] = 2.0 / (top - bottom);
		a[7] = -((top + bottom) / (top - bottom));
		a[10] = -2.0 / (far - near);
		a[11] = -((far + near) / (far - near));
		a[15] = 1;
		mo.transpose();
		FoxRenderer.allocationsThisFrame += 1;

		return mo;
	}

	public static function createOrthogonal(size:Float, aspect:Float, near:Float, far:Float):Matrix3D {
		FoxRenderer.allocationsThisFrame += 1;
		return orthogonalMatrix(new Matrix3D(), size, aspect, near, far);
	}

	// My brain hurts
	public static function transformMatrix(matTRS:Matrix3D, pos:Vector3D, rotEuler:Vector3D, scale:Vector3D):Matrix3D {
		matTRS.copyRawDataFrom(MATRIX_IDENTITY); // identity()
		if(!scale.equals(FoxMathUtil.ONE)) {
			matTRS.appendScale(scale.x, scale.y, scale.z); // It's actually 2 new allocs, bruh openfl
			FoxRenderer.allocationsThisFrame += 2;
		}

		// These methods are so incredibly wasteful in memory, since they create more Matrix3D's
		// but we have to use them because doing them in HScript will be slow af
		// We can't use recompose() because it has a different rotation order
		// it just messes up our rotations, we need YXZ order to preserve Z rotation:
		var rot = rotEuler.clone();
		rot.scaleBy(radToDeg);
		if(rot.z != 0) matTRS.appendRotation(rot.z, FORWARD);
		if(rot.y != 0) matTRS.appendRotation(rot.y, UP);
		if(rot.x != 0) matTRS.appendRotation(rot.x, RIGHT);

		matTRS.appendTranslation(pos.x, pos.y, pos.z);
		FoxRenderer.allocationsThisFrame += 3;

		return matTRS;
	}

	public static function viewMatrix(matRT:Matrix3D, pos:Vector3D, rotEuler:Vector3D):Matrix3D {
		matRT.copyRawDataFrom(MATRIX_IDENTITY); // identity()
		matRT.appendTranslation(-pos.x, -pos.y, -pos.z);

		// These methods are so incredibly wasteful in memory, since they create more Matrix3D's
		// but we have to use them because doing them in HScript will be slow af
		// We can't use recompose() because it has a different rotation order
		// it just messes up our rotations, we need YXZ order to preserve Z rotation:
		var rot = rotEuler.clone();
		rot.scaleBy(-radToDeg);
		if(rot.y != 0) matRT.appendRotation(rot.y, UP);
		if(rot.x != 0) matRT.appendRotation(rot.x, RIGHT);
		if(rot.z != 0) matRT.appendRotation(rot.z, FORWARD);
		FoxRenderer.allocationsThisFrame += 4;

		return matRT;
	}

	public static function viewMatrixFromTransform(output:Matrix3D, transform:Matrix3D):Matrix3D {
		output.copyRawDataFrom(MATRIX_IDENTITY); // identity()
		var pos = __tempVector;
		pos.copyFrom(transform.position);
		pos.negate();
		output.position = pos;

		// We also apply scale normalization to prevent weirdness when the camera transform has scale applied
		var rot = eulerFromMatrix(transform, __tempVector, scaleFromMatrix(transform, __tempVector2));
		rot.scaleBy(-radToDeg);
		
		if(rot.z != 0) output.appendRotation(rot.z, FORWARD);
		if(rot.y != 0) output.appendRotation(rot.y, UP);
		if(rot.x != 0) output.appendRotation(rot.x, RIGHT);
		FoxRenderer.allocationsThisFrame += 3;
		return output;
	}

	public static function createTransform(pos:Vector3D, rotEuler:Vector3D, scale:Vector3D):Matrix3D {
		FoxRenderer.allocationsThisFrame += 1;
		return transformMatrix(new Matrix3D(), pos, rotEuler, scale);
	}

	public static function createViewMatrix(pos:Vector3D, rotEuler:Vector3D):Matrix3D {
		FoxRenderer.allocationsThisFrame += 1;
		return viewMatrix(new Matrix3D(), pos, rotEuler);
	}

	public inline static function fastIdentity(matrix:Matrix3D) {
		matrix.copyRawDataFrom(MATRIX_IDENTITY);
	}

	/**
		Extracts the euler angles aka rotation from a transform matrix.

		Warning! This assumes the scale is 1, if the scale is other than 1, the 
		rotation will not be accurate and weird things can happen!
		Make sure to provide a scale vector to fix this if needed.

		__Note:__ XYZ order only
	**/
	// Adapted from https://github.com/mrdoob/three.js/blob/dev/src/math/Euler.js
	public static function eulerFromMatrix(m:Matrix3D, ?output:Vector3D, ?scale:Vector3D) {
		var mt = m.rawData.__array;
		var e = output ?? new Vector3D();

		if(scale == null) {
			e.y = Math.asin(mt[8]);
			if(Math.abs(mt[8]) < 0.9999999) {
				e.x = Math.atan2(-mt[9], mt[10]);
				e.z = Math.atan2(-mt[4], mt[0]);
			}
			else {
				e.x = Math.atan2(mt[6], mt[5]);
				e.z = 0;
			}
			return e;
		}
		
		// With scale applied
		e.y = Math.asin(mt[8] / scale.z);
		if(Math.abs(mt[8] / scale.z) < 0.9999999) {
			e.x = Math.atan2(-mt[9] / scale.z, mt[10] / scale.z);
			e.z = Math.atan2(-mt[4] / scale.y, mt[0] / scale.x);
		}
		else {
			e.x = Math.atan2(mt[6] / scale.y, mt[5] / scale.y);
			e.z = 0;
		}
		return e;
	}

	/**
		Extracts the scale from a transform matrix.

		Make sure to apply this first before extracting euler angles too if needed.
	**/
	public static function scaleFromMatrix(m:Matrix3D, ?output:Vector3D) {
		var mr = m.rawData.__array;
		var scale = output ?? new Vector3D();

		scale.x = Math.sqrt(mr[0] * mr[0] + mr[1] * mr[1] + mr[2] * mr[2]);
		scale.y = Math.sqrt(mr[4] * mr[4] + mr[5] * mr[5] + mr[6] * mr[6]);
		scale.z = Math.sqrt(mr[8] * mr[8] + mr[9] * mr[9] + mr[10] * mr[10]);

		if (mr[0] * (mr[5] * mr[10] - mr[6] * mr[9]) - mr[1] * (mr[4] * mr[10] - mr[6] * mr[8]) + mr[2] * (mr[4] * mr[9] - mr[5] * mr[8]) < 0)
		{
			scale.z = -scale.z;
		}
		return scale;
	}

	public static function directionOf(matrix:Matrix3D):Vector3D {
		FoxRenderer.allocationsThisFrame += 1;
		var a = matrix.rawData.__array;
		var v = new Vector3D(a[8], a[9], a[10]);
		v.normalize();
		return v;
	}

	public static function directionOfToOutput(matrix:Matrix3D, output:Vector3D):Vector3D {
		var a = matrix.rawData.__array;
		output.setTo(a[8], a[9], a[10]);
		output.normalize();
		return output;
	}

	public static function bakeMVP(model:Matrix3D, view:Matrix3D, projection:Matrix3D):Matrix3D {
		FoxRenderer.allocationsThisFrame += 1;
		var mvp = new Matrix3D();
		mvp.append(model);
		mvp.append(view);
		mvp.append(projection);
		return mvp;
	}
}