package foxlite.flixel;

import flixel.FlxObject;
import flixel.math.FlxMath;
import foxlite.math.FoxMathUtil;
import flixel.sound.FlxSound;
import openfl.geom.Vector3D;

/**
	A `FlxSound` that pans left and right based on the camera position in 3D.
**/
class FoxDirectionalSound extends FoxObject {

	public var sound:FlxSound;
	var attenObj:FlxObject = new FlxObject(); // Tracker attenuator object

	/**
		The strength of the stereo panning.

		A value of 1.0 means pan fully left or right,

		A value of 0.5 means pan left, while right is still audible, and viceversa.

		A value of 0.0 means no panning, and negative values inverts the panning.
	**/
	public var panStrength:Float = 0.85;

	/**
		The sound range in world units.

		Note: The attenuation power follows the [Inverse Square Law](https://en.wikipedia.org/wiki/Inverse-square_law) for realistic effects.
	**/
	public var range:Float = 100;

	/**
		The index of the camera to follow in the scene.
	**/
	public var cameraIndex:Int = 0;

	public function new(target:FlxSound) {
		super();
		name = "FoxDirectionalSound";

		sound = target;
	}

	public override function update(dt:Float) {
		super.update(dt);
		if(sound == null) return;
		var camera = scene.foxCameras[cameraIndex];
		var screenPos = camera?.getScreenPoint(globalPosition);
		if(screenPos == null) return;

		// Because projection can be mirrored if behind the camera, make sure we keep it absolute
		var signW = FlxMath.signOf(screenPos.w);
		var panX = FoxMathUtil.glslClamp(screenPos.x * signW, -1, 1);

		// Stereo pan
		sound.pan = panX - panX*(1 - panStrength);

		// Attenuation
		attenObj.x = Math.pow(Vector3D.distance(globalPosition, camera.position), 2);
		sound.proximity(0, 0, attenObj, range*range, false);
	}

	public override function destroy() {
		sound?.destroy();
		attenObj.destroy();
		super.destroy();
	}
}