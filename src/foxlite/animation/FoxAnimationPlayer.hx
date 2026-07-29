package foxlite.animation;

import Reflect;
import foxlite.FoxBasic;
import foxlite.FoxCache;
import foxlite.animation.FoxAnimation;
import foxlite.loaders.FoxLoaderUtil;
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

class FoxAnimationPlayer extends FoxBasic {

	public var curAnim:FoxAnimation;
	public var library:Map<String, FoxAnimation> = new StringMap();
	public var libraryName:String;
	public var ready:Bool = false;
	public var trackData:Map<String, TrackData> = new StringMap();

	public function new() {
		super();
		name = "FoxAnimationPlayer";
	}

	public override function update(dt:Float) {
		curAnim?.update(dt);
		ready = true; // If we updated at least once, we can be sure we're ready
	}

	public function addAnimation(anim:FoxAnimation) {
		library.set(anim.name, anim);
	}

	public function removeAnimation(name:String) {
		library.remove(name);
	}

	public function getAnimation(name:String):FoxAnimation {
		return library.get(name);
	}

	public function play(name:String, ?from:Float, ?looping:Bool, ?reversed:Bool, ?forceUpdate:Bool) {
		curAnim = library.get(name);
		curAnim?.play(from, looping, reversed);
		ready = false;
		if(forceUpdate != null && forceUpdate) update(0); 
	}

	public function stop() {
		curAnim?.stop();
		curAnim = null;
		ready = false;
	}

	public function pause() {
		curAnim?.pause();
	}

	public function resume() {
		curAnim?.resume();
	}

	public function isPlaying() {
		return curAnim?.playing ?? false;
	}

	public function getTrack(name:String):Any {
		return curAnim?.tracks?.get(name);
	}

	/**
		Gets the current cached track data, this object contains the
		current frame index and the current interpolated value

		__Warning:__ This can be null if no animation is playing
	**/
	public function getTrackData(name:String):foxlite.animation.FoxAnimation.TrackData {
		return curAnim?.trackData?.get(name);
	}

	/**
		Gets the current interpolated track value

		__Warning:__ This can be null if no animation is playing
	**/
	public function getTrackValue(name:String):Any {
		return curAnim?.trackData.get(name)?.value;
	}

	public function getTime() {
		return curAnim?.time ?? 0;
	}

	public override function destroy() {
		for(a in library) a.destroy();
		library = null;
		curAnim = null;
		super.destroy();
	}

	/**
	* Loads Animation libraries and single animations
	* returns `FoxAnimationPlayer` with all animations from the library,
	* or with only one, specified by `:Animation`. i.e: `fromAsset("data/anim:MyAnim");`
	*
	*/
	public static function fromAsset(name:String):FoxAnimationPlayer {
		var extra = name.split(":"); // You can do animations/animfile:MyAnim to pick a specific one from the library
		var animNameFile = extra[1];
		name = extra[0];
		
		if(FoxCache.animationLibs().exists(name)) {
			var animations:Map<String, FoxAnimation> = FoxCache.animationLibs().get(name);
			
			trace("FOUND ANIM IN CACHE: " + name, animations);

			var animPlayer = new FoxAnimationPlayer();
			animPlayer.libraryName = animNameFile;
			if(animNameFile == "") {
				for(anim in animations) 
					animPlayer.addAnimation(anim);
			}
			else animPlayer.addAnimation(animations.get(animNameFile));
		
			return animPlayer;
		}

		var data = FoxLoaderUtil.loadJSON(name);
		if(data == null) return null;

		var animations:Map<String, FoxAnimation> = new StringMap();
		animations.clear();

		for(animName in Reflect.fields(data)) {
			var animData = Reflect.field(data, animName);
			var anim = new FoxAnimation();
			anim.name = animName;
			anim.assetsKey = name;
			anim.duration = animData.duration;
			anim.timeScale = animData.timeScale;
			anim.loop = animData.loop;
			anim.reverse = animData.reverse;

			for(trackName in Reflect.fields(animData.tracks)) {
				var trackData = Reflect.field(animData.tracks, trackName);
				if(trackData.frames == null) {
					trace("[FoxLite > FoxAnimation]: Importing: " + animName + " WARNING! NO FRAME DATA FOR TRACK: " + trackName);
					continue;
				}

				var track:FoxAnimationTrack<Any> = anim.addTrack(trackName, trackData.type);

				var frames:Array<Dynamic> = trackData.frames;
				for(f in frames) {
					if(f[0] == null || f.length != 3) continue;
					var frameData:Dynamic = f[1];
					switch(trackData.typeHint) {
						case FoxAnimationTrackType.VECTOR3D, FoxAnimationTrackType.EULER_ANGLES:
							frameData = new Vector3D(frameData[0], frameData[1], frameData[2]);
						
						case FoxAnimationTrackType.VECTOR4, FoxAnimationTrackType.QUATERNION:
							frameData = new Vector3D(frameData[0], frameData[1], frameData[2], frameData[3]);
						
						case FoxAnimationTrackType.MATRIX4:
							frameData = new Matrix3D();
					}
					
					track.addFrame(f[0], frameData, f[2] != null && f[2] >= 0 && f[2] <= FoxAnimationEaseType.ZERO ? f[2] : 0);
				}
			}
			animations.set(animName, anim);
		}

		// TODO: Do this for FoxAnimation separatedly too, this is for the Collection
		FoxCache.animationLibs().set(name, animations);

		var animPlayer = new FoxAnimationPlayer();
		animPlayer.libraryName = animNameFile;
		if(animNameFile == "") {
			for(anim in animations) 
				animPlayer.addAnimation(anim);
		}
		else animPlayer.addAnimation(animations.get(animNameFile));

		return animPlayer;

		//return animNameFile == "" ? animations : animations.get(animNameFile);
	}
}
