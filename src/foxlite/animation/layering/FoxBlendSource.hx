package foxlite.animation.layering;

import haxe.ds.StringMap;
import foxlite.animation.data.FoxTrackData;
import foxlite.animation.layering.FoxBaseNode;
import foxlite.animation.FoxAnimationBlender;
import foxlite.material.FoxBlendMode;
import flixel.math.FlxMath;

/**
	Provides an animation source to the animation blender
**/
class FoxBlendSource extends FoxBaseNode {

	public var animName:String = "";
	public var time:Float = 0;
	public var timeScale:Float = 1;
	public var reverse:Bool = false;
	public var loop:Bool = false;
	var __seekIndex:Int = -1;

	/**
		@param anim The name of the animation in the player's library
		@param loop Wheter or not loop the animation
		@param reverse Wheter or not play it in reverse
	**/
	public function new(anim:String, loop:Bool=false, reverse:Bool=false) {
		super();
		animName = anim;
		this.loop = loop;
		this.reverse = reverse;
	}

	public override function process(blender:FoxAnimationBlender) {
		var player = blender.player;
		var animation = player.library.get(animName);
		if(animation == null) return;

		initialize(player.trackData.get(animName));
		
		time = loop ? FlxMath.mod(time, animation.duration) : FlxMath.bound(time, 0, animation.duration);
		player.interpolateTracks(time, reverse ? -1 : 1, animation, data, false, __seekIndex);

		time += (reverse ? -blender.delta : blender.delta) * timeScale;
		if(!reverse && time > animation.duration || reverse && time < 0) { // End hit
			if(loop) __seekIndex = reverse ? 0xFFFFFFF : 0;
		}
		else __seekIndex = -1;
	}
}