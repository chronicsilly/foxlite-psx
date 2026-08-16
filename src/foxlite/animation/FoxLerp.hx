package foxlite.animation;

import foxlite.math.FoxMathUtil;
import flixel.math.FlxMath;
import foxlite.renderer.FoxRenderer;
import lime.math.Vector2;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class FoxLerp {

	// For (L)inear Int(ERP)olation function, use FlxMath
	// For easing functions, use FlxEase

	public static function moveToward(from:Float, to:Float, step:Float):Float {
		var diff:Float = to - from;
		if(diff == 0) return from;
		var dir:Float = FlxMath.signOf(diff);
		var projected:Float = from + step * dir;

		if(Math.abs(projected) >= Math.abs(to)) return to;
		return projected; 
	}

	public inline static function lerp(a:Float, b:Float, w:Float):Float {
		return FlxMath.lerp(a, b, w);
	}

	public static function lerpAngle(a:Float, b:Float, w:Float):Float {
		// https://stackoverflow.com/questions/2708476/rotation-interpolation
		final TAU = FoxMathUtil.TAU;
		var shortest_angle = ((b - a) % TAU + Math.PI) % TAU - Math.PI;
   		return a + shortest_angle * w;
	}

	public static function inverseLerp(a:Float, b:Float, v:Float):Float {
		var c = b - a;
		return c == 0 ? 1 : (v - a) / c;
	}

	public static function lerp2D(a:Vector2, b:Vector2, w:Float):Vector2 {
		FoxRenderer.allocationsThisFrame += 1;
		return new Vector2(
			FlxMath.lerp(a.x, b.x, w),
			FlxMath.lerp(a.y, b.y, w)
		);
	}

	public static function lerp2DToOutput(a:Vector2, b:Vector2, w:Float, output:Vector2):Vector2 {
		output.setTo(
			FlxMath.lerp(a.x, b.x, w),
			FlxMath.lerp(a.y, b.y, w)
		);
		return output;
	}

	public static function lerp3D(a:Vector3D, b:Vector3D, w:Float):Vector3D {
		FoxRenderer.allocationsThisFrame += 1;
		return new Vector3D(
			FlxMath.lerp(a.x, b.x, w),
			FlxMath.lerp(a.y, b.y, w),
			FlxMath.lerp(a.z, b.z, w)
		);
	}

	public static function lerp3DToOutput(a:Vector3D, b:Vector3D, w:Float, output:Vector3D):Vector3D {
		output.setTo(
			FlxMath.lerp(a.x, b.x, w),
			FlxMath.lerp(a.y, b.y, w),
			FlxMath.lerp(a.z, b.z, w)
		);
		return output;
	}

	public static function lerpAngle3D(a:Vector3D, b:Vector3D, w:Float):Vector3D {
		FoxRenderer.allocationsThisFrame += 1;
		return new Vector3D(
			FoxLerp.lerpAngle(a.x, b.x, w),
			FoxLerp.lerpAngle(a.y, b.y, w),
			FoxLerp.lerpAngle(a.z, b.z, w)
		);
	}

	public static function lerpAngle3DToOutput(a:Vector3D, b:Vector3D, w:Float, output:Vector3D):Vector3D {
		output.setTo(
			FoxLerp.lerpAngle(a.x, b.x, w),
			FoxLerp.lerpAngle(a.y, b.y, w),
			FoxLerp.lerpAngle(a.z, b.z, w)
		);
		return output;
	}


	public static function inverseLerp3D(a:Vector3D, b:Vector3D, v:Vector3D):Float {
		FoxRenderer.allocationsThisFrame += 2;
		// https://discussions.unity.com/t/inverselerp-for-vector3/177038/2
		var ab:Vector3D = b.subtract(a);
		var av:Vector3D = v.subtract(a);
		return av.dotProduct(ab) / ab.dotProduct(ab);
	}

	public static function lerp4D(a:Vector3D, b:Vector3D, w:Float):Vector3D {
		FoxRenderer.allocationsThisFrame += 1;
		return new Vector3D(
			FlxMath.lerp(a.x, b.x, w),
			FlxMath.lerp(a.y, b.y, w),
			FlxMath.lerp(a.z, b.z, w),
			FlxMath.lerp(a.w, b.w, w)
		);
	}

	public static function lerp4DToOutput(a:Vector3D, b:Vector3D, w:Float, output:Vector3D):Vector3D {
		output.setTo(
			FlxMath.lerp(a.x, b.x, w),
			FlxMath.lerp(a.y, b.y, w),
			FlxMath.lerp(a.z, b.z, w)
		);
		output.w = FlxMath.lerp(a.w, b.w, w);
		return output;
	}

	public inline static function lerpQuaternion(a:Vector3D, b:Vector3D, w:Float):Vector3D {
		return FoxLerp.lerp4D(a, b, w); // TODO: Proper quaternion interpolation
	}

	public inline static function lerpQuaternionToOutput(a:Vector3D, b:Vector3D, w:Float, output:Vector3D):Vector3D {
		return FoxLerp.lerp4DToOutput(a, b, w, output); // TODO: Proper quaternion interpolation
	}

	// Test
	public static function lerpMatrix4(a:Matrix3D, b:Matrix3D, w:Float):Matrix3D {
		FoxRenderer.allocationsThisFrame += 1;
		var m = new Matrix3D(a.rawData);
		m.interpolateTo(b, w);
		return m;
	}

	public static function lerpMatrix4ToOutput(a:Matrix3D, b:Matrix3D, w:Float, output:Matrix3D):Matrix3D {
		output.copyRawDataFrom(a.rawData);
		output.interpolateTo(b, w);
		return output;
	}
}