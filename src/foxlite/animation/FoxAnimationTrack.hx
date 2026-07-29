package foxlite.animation;

import foxlite.animation.FoxAnimationTrackType;
import foxlite.animation.FoxLerp;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;

class FoxAnimationTrack #if !foxlite_polymod <T> #end {
	public var name:String;
	public var frameIndex:Int = 0;
	public var active:Bool = true;
	public var type:FoxAnimationTrackType = FoxAnimationTrackType.FLOAT;
	public var frames:Array<FoxKeyframe<T>> = [];
	public var value:T;

	public function new(trackName:String, initialValue:T):Void {
		name = trackName;
		value = initialValue;
	}

	public function addFrame(time:Float, value:T, easing:FoxAnimationEaseType=0) {
		#if foxlite_polymod
		frames.push(new FoxKeyframe(time, value, easing));
		#else
		frames.push(new FoxKeyframe<T>(time, value, easing));
		#end
	}

	public function removeFrame(frame:FoxKeyframe<T>) {
		frames.remove(frame);
	}

	public function removeFrameByIndex(index:Int) {
		frames.splice(index, 1);
	}

	/**
	* @param closestFrame The index will be rounded towards the closest value (i.e: 0.55 between 0 and 1, the closest is 1)
	*  				if false: it will return the index of the current frame
	* @param ceil The index of the next frame will always be returned
	*/
	public function getFrameIndexByTime(time:Float, closestFrame:Bool=false, ceil:Bool=false):Int {
		for(f in 0...frames.length) {
			if(frames[f].time < time) continue;
			var index:Int = #if !foxlite_polymod cast #end Math.max(f - 1, 0);
			if(ceil) return f;
			return closestFrame && (time - frames[index].time > frames[f].time - time) ? f : index;
		}
		return -1;
	}

	/**
	* @param closestFrame The index will be rounded towards the closest value (i.e: 0.55 between 0 and 1, the closest is 1)
	*  				if false: it will return the current frame
	* @param nextFrame The next frame will always be returned
	*/
	public function getFrameByTime(time:Float, closestFrame:Bool=false, nextFrame:Bool=false):FoxKeyframe<T> {
		for(f in 0...frames.length) {
			if(frames[f].time < time) continue;
			var index:Int = #if !foxlite_polymod cast #end Math.max(f - 1, 0);
			if(nextFrame) return frames[f];
			return frames[closestFrame && (time - frames[index].time > frames[f].time - time) ? f : index];
		}
		return null;
	}

	/**
		Returns the interpolated value between two frames of this track, the frames
		can be reversed and not strictly sequential, meaning you can interpolate between
		any frames.

		The frame easing is applied.
	**/
	public function getValueInterpolated(frame0:FoxKeyframe<T>, frame1:FoxKeyframe<T>, weight:Float):T {
		weight = switch(frame0.ease) {
			case FoxAnimationEaseType.ZERO: 	  	 0;
			case FoxAnimationEaseType.EASE_IN: 	  	 FlxEase.quadIn(weight);
			case FoxAnimationEaseType.EASE_OUT:   	 FlxEase.quadOut(weight);
			case FoxAnimationEaseType.EASE_INOUT: 	 FlxEase.quadInOut(weight);
			default: weight;
		}

		// TODO: Create a macro for this to skip runtime type checks
		var v0:Any = frame0.value;
		var v1:Any = frame1.value;
		return #if !foxlite_polymod cast #end switch(type) {
			case FoxAnimationTrackType.INT: 		 Std.int(FlxMath.lerp(v0, v1, weight));
			case FoxAnimationTrackType.BOOL: 		 v0; // Same as Zero
			case FoxAnimationTrackType.ANGLE: 		 FoxLerp.lerpAngle(v0, v1, weight);
			case FoxAnimationTrackType.FLOAT: 		 FlxMath.lerp(v0, v1, weight);
			case FoxAnimationTrackType.VECTOR2: 	 FoxLerp.lerp2D(v0, v1, weight);
			case FoxAnimationTrackType.VECTOR4: 	 FoxLerp.lerp4D(v0, v1, weight);
			case FoxAnimationTrackType.MATRIX4:		 FoxLerp.lerpMatrix4(v0, v1, weight);
			case FoxAnimationTrackType.VECTOR3D: 	 FoxLerp.lerp3D(v0, v1, weight);
			case FoxAnimationTrackType.QUATERNION: 	 FoxLerp.lerpQuaternion(v0, v1, weight);
			case FoxAnimationTrackType.EULER_ANGLES: FoxLerp.lerpAngle3D(v0, v1, weight);
			default: v0;
		}
	}

	/**
		Returns the interpolated value between two timestamps of this track, controlled by time
	**/
	public function getValueInterpolatedByTime(time:Float):T {
		var f0 = getFrameByTime(time);
		var f1 = getFrameByTime(time, false, true);
		var w = FoxLerp.inverseLerp(f0.time, f1.time, time);
		return getValueInterpolated(f0, f1, w);
	}

	public function clearFrames() {
		frames.resize(0);
	}
}