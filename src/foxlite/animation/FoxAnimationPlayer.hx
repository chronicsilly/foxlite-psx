/*
*      ___           __ _ _       
*     / __\__/\__/\_/ /(_) |_ ___ 
*    / _\/ _ \ \/ // / | | __/ _ \
*   / / | (_) >  </ /__| | ||  __/
*   \/   \___/_/\_\____/_|\__\___|
*                              
*	MIT License
*
*	Copyright (c) 2026 drew
*
*	Permission is hereby granted, free of charge, to any person obtaining a copy
*	of this software and associated documentation files (the "Software"), to deal
*	in the Software without restriction, including without limitation the rights
*	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
*	copies of the Software, and to permit persons to whom the Software is
*	furnished to do so, subject to the following conditions:
*
*	The above copyright notice and this permission notice shall be included in all
*	copies or substantial portions of the Software.
*
*	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
*	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
*	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
*	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
*	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
*	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*	SOFTWARE.
*/

package foxlite.animation;

import Reflect;
import foxlite.FoxCache;
import foxlite.animation.FoxAnimation;
import foxlite.animation.FoxAnimationTrack;
import foxlite.animation.FoxAnimationLinker;
import foxlite.animation.FoxCallbackTrack;
import foxlite.animation.FoxLerp;
import foxlite.flixel.FlxTypedSignalImpl;
import haxe.ds.StringMap;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import flixel.math.FlxMath;

import foxlite.animation.data.FoxTrackData;

class FoxAnimationPlayer extends FoxAnimationLinker {

	public var library:Map<String, FoxAnimation> = new StringMap();
	
	public var playing:Bool = false;
	public var time:Float = 0;
	public var timeScale:Float = 1;
	public var reverse:Bool = false;
	public var curAnim:FoxAnimation;

	/**
		If enabled, will ensure the animation plays smoothly if keyframes are too close together.
		For more details, check `fineTune()`. Disable this if performance is unacceptable.
	**/
	public var fineTuned:Bool = #if !foxlite_polymod true; #else false; #end

	var __reset:Bool = false;
	var __playFrame:Bool = true;

	// Events
	public var onLoop:FlxTypedSignalImpl<()->Void> = new FlxTypedSignalImpl();
	public var onFinish:FlxTypedSignalImpl<()->Void> = new FlxTypedSignalImpl();
	public var onUpdate:FlxTypedSignalImpl<()->Void> = new FlxTypedSignalImpl();

	public function new(?library:Map<String, FoxAnimation>) {
		super();
		if(library != null) for(anim in library) addAnimation(anim);
		name = "FoxAnimationPlayer";
	}

	public override function update(dt:Float) {
		if(curAnim == null || !playing) return;
		
		time = curAnim.loop ? FlxMath.mod(time, curAnim.duration) : FlxMath.bound(time, 0, curAnim.duration);
		var tDir = reverse ? -1 : 1;

		var curData:Map<String, FoxTrackData> = trackData.get(curAnim.name);

		for(trackName=>track in curAnim.tracks) {
			var frames = track.frames;
			var len = frames.length - 1;
			if(len == -1) continue;

			var data:FoxTrackData = curData.get(trackName);

			if(__reset) data.frameIndex = reverse ? len : 0;
			if(__playFrame) data.prevFrameIndex = -1;
			
			if(fineTuned) data.frameIndex = fineTune(data, frames, this.time, tDir, curAnim.duration);
			
			var curFrame = frames[data.frameIndex];
			var nextFrame = frames[Std.int(FlxMath.bound(data.frameIndex + tDir, 0, len))];

			var timeLerp = FoxLerp.inverseLerp(curFrame.time, nextFrame.time, time);

			var frameChanged = data.prevFrameIndex != data.frameIndex;
			data.prevFrameIndex = data.frameIndex;
			
			if(timeLerp >= 1) data.frameIndex += tDir;
			else if(timeLerp < 0) data.frameIndex -= tDir; // if for some crazy reason it's negative, go backwards

			// Advance frame
			data.frameIndex = Std.int(FlxMath.bound(data.frameIndex, 0, len));

			var v0 = curFrame.value;
			var v1 = nextFrame.value;

			if(track.type == FoxTrackType.FUNCTION && frameChanged) {
				// For function track types we only need to call it
				var arg:Array<Dynamic> = v0;
				var func = (cast track:FoxCallbackTrack).callbacks.get(arg[0]);
				if(func != null) Reflect.callMethod(null, func, arg[1]);
				else trace('Could not call "${arg[0]}"! For track "$trackName" in "${curAnim.name}"');
				continue;
			}

			// Easing
			timeLerp = FoxAnimationTrack.getEaseWeight(FlxMath.bound(timeLerp, 0, 1), curFrame.ease);

			// Save interpolated value
			switch(track.type) {
				case FoxTrackType.INT:{			data.value = Std.int(FlxMath.lerp(v0, v1, timeLerp)); };
				case FoxTrackType.BOOL:{		data.value = v0; }; // Same as Zero 
				case FoxTrackType.ANGLE:{		data.value = FoxLerp.lerpAngle(v0, v1, timeLerp); };
				case FoxTrackType.FLOAT:{		data.value = FlxMath.lerp(v0, v1, timeLerp); };
				case FoxTrackType.COLOR:{		data.value = FoxLerp.lerpColorHex(v0, v1, timeLerp); };
				case FoxTrackType.DEGREES:{		data.value = FoxLerp.lerpAngleDegrees(v0, v1, timeLerp); };
				case FoxTrackType.VECTOR2: 		FoxLerp.lerp2DToOutput(v0, v1, timeLerp, data.value);
				case FoxTrackType.VECTOR4: 	 	FoxLerp.lerp4DToOutput(v0, v1, timeLerp, data.value);
				case FoxTrackType.MATRIX4:		FoxLerp.lerpMatrix4ToOutput(v0, v1, timeLerp, data.value);
				case FoxTrackType.VECTOR3D: 	FoxLerp.lerp3DToOutput(v0, v1, timeLerp, data.value);
				case FoxTrackType.QUATERNION: 	FoxLerp.lerpQuaternion(v0, v1, timeLerp, data.value);
				case FoxTrackType.EULER_ANGLES: FoxLerp.lerpAngle3DToOutput(v0, v1, timeLerp, data.value);
				default: { data.value = v0; };
			}
		}

		time += (reverse ? -dt : dt) * timeScale;

		if(!reverse && time > curAnim.duration || reverse && time < 0) { 
			// End hit
			if(curAnim.loop) { // TODO: Add LoopModes and parse (0 = none, 1 = linear, 2 = pingpong)
				queryReset();
				onLoop.dispatch();
			}
			else {
				pause();
				onFinish.dispatch();
			}
		}
		else {
			__reset = false;
			onUpdate.dispatch();
		}
		__playFrame = false;
		super.update(dt);
	}

	public override function addAnimation(anim:FoxAnimation) {
		super.addAnimation(anim);
		library.set(anim.name, anim);
	}

	public function removeAnimation(name:String) {
		library.remove(name);
	}

	public function getAnimation(name:String):FoxAnimation {
		return library.get(name);
	}

	/**
		Gets the interpolated track value from a currently active animation.

		__Warning!__ Can be null if no animation is playing.
	**/
	public function getTrackValue(name:String):Any {
		if(curAnim == null) return null;
		return trackData.get(curAnim.name)?.get(name)?.value;
	}

	public function play(name:String, ?from:Float, ?reversed:Bool) {
		curAnim = library.get(name);
		animSelector = name;
		if(reversed != null) reverse = reversed;
		__playFrame = true;
		playing = true;
		if(from != null) seek(from);
	}

	/**
		Fine-tunes a frame index to always interpolate between two timestamps for a current play time.

		This ensures the animation plays smoothly and doesn't hold onto a keyframe if they're too close together until the next frame.
	**/
	public function fineTune(data:FoxTrackData, frames:Array<FoxKeyframe<Any>>, time:Float, direction:Int, duration:Float):Int {
		var len = frames.length - 1;
		while(true) {
			var curTime = frames[data.frameIndex].time;
			var nextTime = frames[Std.int(FlxMath.bound(data.frameIndex + direction, 0, len))].time;

			if(time >= Math.max(Math.min(curTime, nextTime), 0) && time <= Math.min(Math.max(curTime, nextTime), duration)) {
				break; 
			}
			else {
				data.frameIndex = Std.int(FlxMath.mod(data.frameIndex + direction, frames.length));
			}
		}
		return data.frameIndex;
	}

	/**
		Seeks the animation to a particular `time`. This has the same effect as setting `time` directly, with a bit extra safety.

		@param forceUpdate Forces the animation to update right away (values will interpolate and functions may be called)
	**/
	public function seek(seekTime:Float, forceUpdate:Bool=false) {
		if(curAnim == null) return;
		time = FlxMath.bound(seekTime, 0, curAnim.duration);
		if(forceUpdate) update(0);
	}

	public function stop() {
		curAnim = null;
		playing = false;
	}

	public function pause() {
		playing = false;
	}

	public function resume() {
		playing = true;
	}

	public function queryReset() {
		__reset = true;
	}

	public function getTrack(name:String):Any {
		return curAnim?.tracks?.get(name);
	}

	public override function destroy() {
		library = null;
		curAnim = null;
		playing = false;
		super.destroy();
	}
}
