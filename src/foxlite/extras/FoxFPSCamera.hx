package foxlite.extras;

import Reflect;
import flixel.FlxG;
import flixel.math.FlxMath;
import foxlite.FoxCamera;
import lime.math.Vector2;
import openfl.geom.Vector3D;

class FoxFPSCamera extends FoxCamera {

	public var enableYMovement:Bool = true; // Floating
	public var enableControls:Bool = true;
	public var sensitivity:Float = 0.002; // Look sensitivity
	public var speed:Float = 7.0;

	public var velocity:Vector3D = new Vector3D();
	public var targetAngle:Vector3D = new Vector3D();
	public var smoothFactor:Float = 0.5;

	// Pitch angles
	public var minPitch:Float = -Math.PI/2;
	public var maxPitch:Float = Math.PI/2;

	// Controls
	public var forwards:String = "W";
	public var backwards:String = "S";
	public var strafeRight:String = "D";
	public var strafeLeft:String = "A";
	public var run:String = "SHIFT";
	public var inputDir:Vector2 = new Vector2();

	// Temp pos for touchscreen
	#if !FLX_NO_TOUCH
	public var touchLastX:Int = 0;
	public var touchLastY:Int = 0;
	#end

	// Default: W S D A
	public function new() {
		super();
	}

	public override function update(dt:Float) {
		if(enableControls) {
			
			inputDir.x = pressed(strafeRight) - pressed(strafeLeft);
			inputDir.y = pressed(backwards) - pressed(forwards);

			var moveSpeed:Float = speed * (pressed(run) + 1) * dt;
			var ddt:Float = Math.min(dt * 60 * smoothFactor, 1);

			// Rotation
			var input:Bool = false;
			#if !FLX_NO_MOUSE
			if(FlxG.mouse.pressed) input = true;
			#end
			#if !FLX_NO_TOUCH
			if(FlxG.touches.list.length > 0) input = true;
			#end

			if(input) {
				var deltaX:Float = 0;
				var deltaY:Float = 0;

				#if !FLX_NO_MOUSE
				deltaX += FlxG.mouse.deltaViewX;
				deltaY += FlxG.mouse.deltaViewY;
				#end
				
				#if !FLX_NO_TOUCH
				var touch = FlxG.touches.getFirst();
				if(touch != null) {
					if(!touch.justPressed) {
						deltaX += touch.x - touchLastX;
						deltaY += touch.y - touchLastY;
					}
					touchLastX = touch.x;
					touchLastY = touch.y;
				}
				#end

				targetAngle.x -= deltaY * sensitivity;
				targetAngle.y -= deltaX * sensitivity;
				targetAngle.x = FlxMath.bound(targetAngle.x, minPitch, maxPitch);
			}

			rotation.x = FlxMath.lerp(rotation.x, targetAngle.x, ddt);
			rotation.y = FlxMath.lerp(rotation.y, targetAngle.y, ddt);

			// Camera forward direction in 2D
			var cos = Math.cos(-rotation.y);
			var sin = Math.sin(-rotation.y);

			if(enableYMovement) {
				var dirY = Math.sin(rotation.x);
				velocity.y = FlxMath.lerp(velocity.y, dirY * -inputDir.y * moveSpeed, ddt);
				inputDir.y *= 1.0 - Math.abs(dirY);
			}

			// Rotate input based on Y rotation
			var x = inputDir.x;
			var y = inputDir.y;
			inputDir.x = x*cos - y*sin;
			inputDir.y = x*sin + y*cos;

			velocity.x = FlxMath.lerp(velocity.x, inputDir.x * moveSpeed, ddt);
			velocity.z = FlxMath.lerp(velocity.z, inputDir.y * moveSpeed, ddt);

			position.incrementBy(velocity);

			__updateMatrices = true;
		}

		super.update(dt);
	}

	public inline function pressed(key:String):Float {
		#if FLX_NO_KEYBOARD
		return 0;
		#else
		return Reflect.getProperty(FlxG.keys.pressed, key) ? 1 : 0;
		#end
	}
}