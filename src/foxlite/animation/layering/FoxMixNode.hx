package foxlite.animation.layering;

import haxe.ds.StringMap;
import foxlite.animation.FoxAnimationBlender;
import foxlite.animation.data.FoxTrackData;
import foxlite.animation.layering.FoxBaseNode;
import foxlite.animation.FoxTrackType;
import flixel.math.FlxMath;

class FoxMixNode extends FoxBaseNode {

	public var inputA:String;
	public var inputB:String;
	public var factor:Float;

	public function new(inputA:String, inputB:String, factor:Float=0.5) {
		super();
		this.inputA = inputA;
		this.inputB = inputB;
		this.factor = factor;
	}

	public override function process(blender:FoxAnimationBlender) {
		var inA:FoxBaseNode = blender.nodes.get(inputA);
		var inB:FoxBaseNode = blender.nodes.get(inputB);

		initialize(inA.data);

		if(inA != null && inB != null) for(name=>output in data) {
			var trackA = inA.data.get(name);
			var trackB = inB.data.get(name);
			if(trackB == null) trackB = trackA; // Allow passtrough if there's no input B
			if(trackA == null) continue;

			if(trackA.type == trackB.type) switch(output.type) {
				case FoxTrackType.INT:			output.value = Std.int(FlxMath.lerp(trackA.value, trackB.value, factor));
				case FoxTrackType.BOOL:			output.value = factor < 0.5 ? trackA.value : trackB.value;
				case FoxTrackType.ANGLE:		output.value = FoxLerp.lerpAngle(trackA.value, trackB.value, factor);
				case FoxTrackType.FLOAT:		output.value = FlxMath.lerp(trackA.value, trackB.value, factor);
				case FoxTrackType.COLOR:		output.value = FoxLerp.lerpColorHex(trackA.value, trackB.value, factor);
				case FoxTrackType.DEGREES:		output.value = FoxLerp.lerpAngleDegrees(trackA.value, trackB.value, factor);
				case FoxTrackType.VECTOR2: 		FoxLerp.lerp2DToOutput(trackA.value, trackB.value, factor, output.value);
				case FoxTrackType.VECTOR4: 	 	FoxLerp.lerp4DToOutput(trackA.value, trackB.value, factor, output.value);
				case FoxTrackType.MATRIX4:		FoxLerp.lerpMatrix4ToOutput(trackA.value, trackB.value, factor, output.value);
				case FoxTrackType.VECTOR3D: 	FoxLerp.lerp3DToOutput(trackA.value, trackB.value, factor, output.value);
				case FoxTrackType.QUATERNION: 	FoxLerp.lerpQuaternion(trackA.value, trackB.value, factor, output.value);
				case FoxTrackType.EULER_ANGLES: FoxLerp.lerpAngle3DToOutput(trackA.value, trackB.value, factor, output.value);
			}
		}
	}
}