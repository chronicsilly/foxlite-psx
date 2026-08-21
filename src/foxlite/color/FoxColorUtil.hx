package foxlite.color;

import flixel.util.FlxColor;
import foxlite.renderer.FoxRenderer;
import openfl.geom.Vector3D;

class FoxColorUtil {

    /**
		Takes a `FlxColor` and outputs a normalized `Vector3D`

		@param c The input color
		@param output (Optional) The output to store the values, use it to prevent allocating a new vector
	**/
	public static function fromFlxColor(c:FlxColor, ?output:Vector3D):Vector3D {
        if(output == null) {
            output = new Vector3D();
            FoxRenderer.allocationsThisFrame += 1;
        }

		output.setTo(c.redFloat, c.greenFloat, c.blueFloat);
		output.w = c.alphaFloat;

        return output;
	}

	/**
		Takes a `Vector3D` and outputs a `FlxColor`

		@param c The normalized color vector
	**/
	public inline static function toFlxColor(c:Vector3D):FlxColor {
		return FlxColor.fromRGBFloat(c.x, c.y, c.z, c.w);
	}

}