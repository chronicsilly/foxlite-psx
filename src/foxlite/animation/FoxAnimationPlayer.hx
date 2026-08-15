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

import foxlite.flixel.FlxTypedSignalImpl;
import Reflect;
import foxlite.FoxBasic;
import foxlite.FoxCache;
import foxlite.animation.FoxAnimation;
import foxlite.animation.FoxAnimationTrack;
import foxlite.animation.FoxCallbackTrack;
import foxlite.animation.FoxLerp;
import foxlite.loaders.FoxLoaderUtil;
import haxe.ds.StringMap;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import flixel.math.FlxMath;

class TrackData {
	public var frameIndex:Int = 0;
	public var prevFrameIndex:Int = -1;
	public var value:Any;

	public function new(t:Any) {
		value = t;
	}
}

class FoxAnimationPlayer extends FoxBasic {

	public var library:Map<String, FoxAnimation> = new StringMap();
	public var libraryName:String;
	public var trackData:Map<String, TrackData> = new StringMap();
	
	public var playing:Bool = false;
	public var time:Float = 0;
	public var timeScale:Float = 1;
	public var reverse:Bool = false;
	public var curAnim:FoxAnimation;

	var __reset:Bool = false;
	var __playFrame:Bool = true;

	// Events
	public var onLoop:FlxTypedSignalImpl<()->Void> = new FlxTypedSignalImpl();
	public var onFinish:FlxTypedSignalImpl<()->Void> = new FlxTypedSignalImpl();
	public var onUpdate:FlxTypedSignalImpl<()->Void> = new FlxTypedSignalImpl();

	public function new() {
		super();
		name = "FoxAnimationPlayer";
	}

	public override function update(dt:Float) {
		super.update(dt);
		if(curAnim == null || !playing) return;
		
		time = curAnim.loop ? FlxMath.mod(time, curAnim.duration) : FlxMath.bound(time, 0, curAnim.duration);
		var tDir = reverse ? -1 : 1;

		for(trackName=>track in curAnim.tracks) {
			var frames = track.frames;
			var len = frames.length - 1;
			if(len == -1) continue;

			var data = trackData.get(trackName);

			if(__reset) data.frameIndex = reverse ? len : 0;
			if(__playFrame) data.prevFrameIndex = -1;
			
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
				Reflect.callMethod(null, func, arg[1]);
				continue;
			}

			// Easing
			timeLerp = FoxAnimationTrack.getEaseWeight(FlxMath.bound(timeLerp, 0, 1), curFrame.ease);

			// Save interpolated value
			data.value = switch(track.type) {
				case FoxTrackType.INT: 		 	 Std.int(FlxMath.lerp(v0, v1, timeLerp));
				case FoxTrackType.BOOL: 		 v0; // Same as Zero
				case FoxTrackType.ANGLE: 		 FoxLerp.lerpAngle(v0, v1, timeLerp);
				case FoxTrackType.FLOAT: 		 FlxMath.lerp(v0, v1, timeLerp);
				case FoxTrackType.VECTOR2: 		 FoxLerp.lerp2D(v0, v1, timeLerp);
				case FoxTrackType.VECTOR4: 	 	 FoxLerp.lerp4D(v0, v1, timeLerp);
				case FoxTrackType.MATRIX4:		 FoxLerp.lerpMatrix4(v0, v1, timeLerp);
				case FoxTrackType.VECTOR3D: 	 FoxLerp.lerp3D(v0, v1, timeLerp);
				case FoxTrackType.QUATERNION: 	 FoxLerp.lerpQuaternion(v0, v1, timeLerp);
				case FoxTrackType.EULER_ANGLES:  FoxLerp.lerpAngle3D(v0, v1, timeLerp);
				default: v0;
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
	}

	public function addAnimation(anim:FoxAnimation) {
		library.set(anim.name, anim);
		// Add to track cache aswell
		for(track in anim.tracks) {
			trackData.set(track.name, new TrackData(null));
		}
	}

	public function removeAnimation(name:String) {
		library.remove(name);
	}

	public function getAnimation(name:String):FoxAnimation {
		return library.get(name);
	}

	public function getTrackValue(name:String):Any {
		return trackData.get(name)?.value;
	}

	public function play(name:String, ?from:Float, ?reversed:Bool) {
		curAnim = library.get(name);
		if(from != null) time = from;
		if(reversed != null) reverse = reversed;
		playing = true;
		__playFrame = true;
	}

	/**
		Normally, you'd assign a value to `time` to seek the animation.
		However, due to frame picking and interpolation, the current frame may
		not correspond to the current time until a number of frames later, and
		the values will sweep across all the frames in-between (including function calls).

		This method is a fine-tuned version of the seek, it sweeps across frames in advance so
		the actual update happens immediately.
	**/
	public function seek(seekTime:Float) {
		if(curAnim == null) return;
		time = FlxMath.bound(seekTime, 0, curAnim.duration);

		var tDir = reverse ? -1 : 1;
		for(trackName => track in curAnim.tracks) {
			var frames = track.frames;
			var len = frames.length-1;
			if(len == -1) continue;
			
			var data = trackData.get(trackName);
			
			var seeking:Bool = true;
			while(seeking) {
				var curTime = frames[data.frameIndex].time;
				var nextTime = frames[Std.int(FlxMath.bound(data.frameIndex + tDir, 0, len))].time;

				if(time >= Math.max(Math.min(curTime, nextTime), 0) && time <= Math.min(Math.max(curTime, nextTime), curAnim.duration)) {
					seeking = false;
					break;
				}
				else {
					data.frameIndex += tDir;
					data.frameIndex = Std.int(FlxMath.mod(data.frameIndex, frames.length));
				}
			}
		}
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
		trackData.clear();
		super.destroy();
	}
}
