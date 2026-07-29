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

import flixel.math.FlxMath;
import foxlite.FoxCache;
import foxlite.animation.FoxAnimationTrack;
import foxlite.animation.FoxAnimationTrackType;
import foxlite.animation.FoxLerp;
import foxlite.renderer.FoxRenderer;
import haxe.ds.StringMap;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class TrackData {
	public var frameIndex:Int = 0;
	public var value:Any;

	public function new(t:FoxAnimationTrack<Any>) {
		value = t.value;
	}
}

class FoxAnimation {

	/**
		Contains the tracks of this animation.

		Cast it to a `FoxAnimationTrack<Type>` to access it.
	**/
	public var tracks:Map<String, FoxAnimationTrack<Any>> = new StringMap();
	public var trackData:Map<String, TrackData> = new StringMap();

	public var time:Float = 0;
	public var duration:Float = 0;
	public var timeScale:Float = 1.0;
	public var reverse:Bool = false;
	public var playing:Bool = false;
	public var loop:Bool = false; // TODO: Add LoopModes and parse (0 = none, 1 = linear, 2 = pingpong)
	public var name:String;
	public var assetsKey:String;
	public var __resetQueried:Bool = false; // true if animation is on the end of the loop and must restart

	public function new(animationName:String="FoxAnimation"):Void {
		name = animationName;
		FoxRenderer.allocationsThisFrame += 3;
	}

	public function update(dt:Float) {
		if(!playing) return;

		time = loop ? FlxMath.mod(time, duration) : FlxMath.bound(time, 0, duration);
		
		for(trackName=>track in tracks) {
			var frames = track.frames;
			if(frames.length == 0) continue;

			var data = trackData.get(trackName);

			if(__resetQueried) data.frameIndex = 0;

			var curFrame = frames[Std.int(FlxMath.bound(data.frameIndex, 0, frames.length - 1))];
			var nextFrame = frames[Std.int(FlxMath.bound(data.frameIndex + (reverse ? -1 : 1), 0, frames.length - 1))];

			var timeLerp = FoxLerp.inverseLerp(curFrame.time, nextFrame.time, time);

			if(timeLerp >= 1) {
				track.frameIndex += reverse ? -1 : 1;
			}
			else if(timeLerp < 0) data.frameIndex -= reverse ? -1 : 1; // if for some crazy reason it's negative, go backwards
			data.frameIndex = Std.int(FlxMath.bound(data.frameIndex, 0, frames.length - 1));

			timeLerp = FlxMath.bound(timeLerp, 0, 1);

			data.value = track.getValueInterpolated(curFrame, nextFrame, timeLerp);
		}

		time += (reverse ? -dt : dt) * timeScale;
		if(!reverse && time >= duration || reverse && time <= 0) { // End hit
			if(!loop) {
				pause();
				onFinish();
			}
			else { // Reset frame indices
				__resetQueried = true;
			}
		}
		else __resetQueried = false;

		onUpdate();
	}

	public function play(?from:Float, ?looping:Bool, ?reversed:Bool) {
		if(from != null) time = from;
		if(looping != null) loop = looping;
		if(reversed != null) reversed = reverse;
		playing = true;
	}

	public function stop() {
		time = 0;
		update(0); // Resets its state
		for(t in tracks) t.frameIndex = -1;
		playing = false;
	}

	public inline function pause() {
		playing = false;
	}

	public inline function resume() {
		playing = true;
	}

	public function addTrack(trackName:String, type:Int=0):Any {
		// This weird syntax is to avoid an even weirder syntax for polymod compatibility
		var track:Any = switch(type) {
			case FoxAnimationTrackType.ANGLE, FoxAnimationTrackType.FLOAT: {
				var t:FoxAnimationTrack<Float> = new FoxAnimationTrack(trackName, 0.0);
				t;
			};
			case FoxAnimationTrackType.BOOL: {
				var t:FoxAnimationTrack<Bool> = new FoxAnimationTrack(trackName, false);
				t;
			};
			case FoxAnimationTrackType.INT: {
				var t:FoxAnimationTrack<Int> = new FoxAnimationTrack(trackName, 0);
				t;
			};
			case FoxAnimationTrackType.VECTOR3D, FoxAnimationTrackType.VECTOR4, FoxAnimationTrackType.QUATERNION, FoxAnimationTrackType.EULER_ANGLES: {
				var t:FoxAnimationTrack<Vector3D> = new FoxAnimationTrack(trackName, new Vector3D());
				t;
			};
			case FoxAnimationTrackType.MATRIX4: {
				var t:FoxAnimationTrack<Matrix3D> = new FoxAnimationTrack(trackName, new Matrix3D());
				t;
			};
			default: null;
		}
		if(track == null) return null;

		tracks.set(trackName, track);
		trackData.set(trackName, new TrackData(track)); 
		FoxRenderer.allocationsThisFrame += 2;
		return track;
	}

	public function removeTrack(trackName:String) {
		tracks.remove(trackName);
		trackData.remove(trackName);
	}

	public dynamic function onFinish():Void {}
	public dynamic function onUpdate():Void {}

	public function destroy() {
		tracks.clear();
		trackData.clear();
		playing = false;

		var cache = FoxCache.animationLibs().get(assetsKey);
		if(cache != null) {
			cache.remove(this.name);
			if(!cache.keys().hasNext()) FoxCache.animationLibs().remove(assetsKey);
		}
	}
}