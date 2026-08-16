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

import lime.math.Vector2;
import flixel.math.FlxMath;
import foxlite.FoxCache;
import foxlite.animation.FoxAnimationTrack;
import foxlite.animation.FoxCallbackTrack;
import foxlite.animation.FoxTrackType;
import foxlite.animation.FoxLerp;
import foxlite.renderer.FoxRenderer;
import haxe.ds.StringMap;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class FoxAnimation {

	/**
		Contains the tracks of this animation.

		Don't access this directly, instead call `getTrack()` and cast it to a desired type.
	**/
	public var tracks:Map<String, FoxAnimationTrack<Any>> = new StringMap();

	public var duration(default, set):Float = 0;
	public var loop:Bool = false;
	public var name:String;
	public var assetsKey:String;

	function set_duration(v:Float):Float {
		return this.duration = Math.max(v, 0);
	}

	public function new(animationName:String="FoxAnimation"):Void {
		name = animationName;
		FoxRenderer.allocationsThisFrame += 3;
	}

	public function addTrack(trackName:String, type:FoxTrackType=0):Any {
		// This weird syntax is to avoid an even weirder syntax for polymod compatibility
		var track:Any = switch(type) {
			case FoxTrackType.ANGLE, 
				 FoxTrackType.FLOAT: (new FoxAnimationTrack(trackName, type):FoxAnimationTrack<Float>);
			case FoxTrackType.BOOL: (new FoxAnimationTrack(trackName, type):FoxAnimationTrack<Bool>);
			case FoxTrackType.INT: (new FoxAnimationTrack(trackName, type):FoxAnimationTrack<Int>);
			case FoxTrackType.VECTOR3D, 
				 FoxTrackType.VECTOR4, 
				 FoxTrackType.QUATERNION, 
				 FoxTrackType.EULER_ANGLES: (new FoxAnimationTrack(trackName, type):FoxAnimationTrack<Vector3D>);
			case FoxTrackType.MATRIX4: (new FoxAnimationTrack(trackName, type):FoxAnimationTrack<Matrix3D>);
			case FoxTrackType.VECTOR2: (new FoxAnimationTrack(trackName, type):FoxAnimationTrack<Vector2>);
			case FoxTrackType.FUNCTION: new FoxCallbackTrack(trackName, type);
			default: null;
		}
		if(track == null) return null;

		tracks.set(trackName, track); 
		FoxRenderer.allocationsThisFrame += 2;
		return track;
	}

	public function getTrack(trackName:String):Any {
		return tracks.get(trackName);
	}

	public function removeTrack(trackName:String) {
		tracks.remove(trackName);
	}

	public function destroy() {
		tracks.clear();

		var cache = FoxCache.animationLibs().get(assetsKey);
		if(cache != null) {
			cache.remove(this.name);
			if(!cache.keys().hasNext()) FoxCache.animationLibs().remove(assetsKey);
		}
	}
}