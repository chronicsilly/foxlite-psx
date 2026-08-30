package foxlite.animation.layering;

import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import lime.math.Vector2;
import flixel.util.FlxColor;
import haxe.ds.StringMap;
import foxlite.animation.FoxAnimationBlender;
import foxlite.animation.data.FoxTrackData;
import foxlite.animation.layering.FoxBaseNode;
import foxlite.animation.FoxTrackType;

class FoxAddNode extends FoxBaseNode {

	public var inputA:String;
	public var inputB:String;
	public var factor:Float;

	public function new(inputA:String, inputB:String, factor:Float=1) {
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

			// I'm in a rush AAAAAAAAAAAA
			if(trackA.type == trackB.type) switch(output.type) {
				case FoxTrackType.INT:			output.value = Std.int((trackA.value:Int) + (trackB.value:Int)*factor);
				case FoxTrackType.BOOL:			output.value = factor < 0.5 ? trackA.value : ((trackA.value:Bool) || (trackB.value:Bool)); 
				case FoxTrackType.ANGLE,
					 FoxTrackType.DEGREES,
					 FoxTrackType.FLOAT:		output.value = (trackA.value:Float) + (trackB.value:Float) * factor;
				case FoxTrackType.COLOR:		output.value = FlxColor.fromRGBFloat(
					(trackA.value:FlxColor).redFloat   + (trackB.value:FlxColor).redFloat   * factor,
					(trackA.value:FlxColor).greenFloat + (trackB.value:FlxColor).greenFloat * factor,
					(trackA.value:FlxColor).blueFloat  + (trackB.value:FlxColor).blueFloat  * factor,
					(trackA.value:FlxColor).alphaFloat + (trackB.value:FlxColor).alphaFloat * factor
				);
				case FoxTrackType.VECTOR2: 		{
					final A:Vector2 = trackA.value;
					final B:Vector2 = trackB.value;
					(output.value:Vector2).setTo(A.x + B.x*factor, A.y + B.y*factor);
				};
				case FoxTrackType.VECTOR4,
					 FoxTrackType.VECTOR3D,
					 FoxTrackType.QUATERNION,
					 FoxTrackType.EULER_ANGLES: {
					final A:Vector3D = trackA.value;
					final B:Vector3D = trackB.value;
					final O:Vector3D = output.value;
					O.setTo(A.x + B.x*factor, A.y + B.y*factor, A.z + B.z*factor);
					O.w = A.w + B.w*factor;
				};
				case FoxTrackType.MATRIX4:		{
					final A = (trackA.value:Matrix3D).rawData.__array;
					final B = (trackB.value:Matrix3D).rawData.__array;
					final O = (output.value:Matrix3D).rawData.__array;
					for(i in 0...16) O[i] = A[i] + B[i] * factor;
				};
			}
		}
	}
}