package foxlite.animation;

import flixel.math.FlxMath;
#if !foxlite_polymod
import flixel.util.FlxColor;
#end
import foxlite.math.FoxMathUtil;
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

	public static function lerpAngleDegrees(a:Float, b:Float, w:Float):Float {
		var shortest_angle = ((b - a) % 360 + 180) % 360 - 180;
   		return a + shortest_angle * w;
	}

	/**
		Format follows FlxColor's ARGB
	**/
	public inline static function lerpColorHex(a:FlxColor, b:FlxColor, w:Float):FlxColor {
		#if (foxlite_polymod || cne)
		return FlxColor.interpolate(a, b, w);
		#else
		var x1 = (a >> 16) & 0xFF;
		var y1 = (a >>  8) & 0xFF;
		var z1 =  a & 0xFF;
		var w1 = (a >> 24) & 0xFF;

		var x2 = (b >> 16) & 0xFF;
		var y2 = (b >>  8) & 0xFF;
		var z2 =  b & 0xFF;
		var w2 = (b >> 24) & 0xFF;

		x1 += Std.int((x2 - x1) * w);
		y1 += Std.int((y2 - y1) * w);
		z1 += Std.int((z2 - z1) * w);
		w1 += Std.int((w2 - w1) * w);
		return w1 << 24 | x1 << 16 | y1 << 8 | z1;
		#end
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

	public static function lerpQuaternion(a:Vector3D, b:Vector3D, w:Float, ?output:Vector3D):Vector3D {
		// Slerp
		var dot = a.dotProduct(b) + a.w*b.w;
		var c = b.clone();
		if(output == null) output = new Vector3D();

		//make sure we take the shortest path in case dot Product is negative
		if(dot < 0.0) {
			c.negate();
			c.w *= -1;
			dot *= -1;
		}
		
		//if the two quaternions are too close to each other, just linear interpolate between the 4D vector
		if(dot > 0.9995) {
			FoxLerp.lerp4DToOutput(a, c, w, output);
			// normalize
			var len = Math.sqrt(output.lengthSquared + output.w*output.w);
			output.scaleBy(1 / len);
			output.w /= len;
			return output;
		}

		//perform the spherical linear interpolation
		var theta0:Float = Math.acos(dot);
		var theta:Float = w * theta0;
		var sinTheta:Float = Math.sin(theta);
		var sinTheta0:Float = Math.sin(theta0);

		var scalePreviousQuat:Float = Math.cos(theta) - dot * sinTheta / sinTheta0;
		var scaleNextQuat:Float = sinTheta / sinTheta0;

		output.copyFrom(c);
		output.scaleBy(scaleNextQuat);
		output.w = c.w * scaleNextQuat;

		// copy temporarily
		var x = output.x, y = output.y, z = output.z, w = output.w;
		
		output.copyFrom(a);
		output.scaleBy(scalePreviousQuat);
		output.w = a.w * scalePreviousQuat;

		output.x += x;
		output.y += y;
		output.z += z;
		output.w += w;

		return output;
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