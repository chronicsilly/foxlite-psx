package foxlite.animation;


import haxe.ds.StringMap;
import foxlite.FoxBasic;
import foxlite.group.FoxTypedGroup;
import foxlite.animation.FoxAnimationPlayer;
import foxlite.animation.data.FoxTrackData;
import foxlite.animation.layering.FoxBlendSource;
import foxlite.animation.layering.FoxBaseNode;

/**
	Animation layering! Play animations at the same time, animating different models/joints at once!
**/
class FoxAnimationBlender extends FoxBasic {

	public var player:FoxAnimationPlayer;

	/**
		Set this animation blender to be active or not, if set to true this
		also disables the connected `FoxAnimationPlayer`
	**/
	public var enabled(default, set):Bool;
	
	@:dox(hide)
	@:noCompletion public var delta:Float = 0;

	function set_enabled(v:Bool):Bool {
		if(v && player != null) player.active = false;
		return v;
	}

	public var nodes:StringMap<FoxBaseNode> = new StringMap();

	/**
		The blend output, this is the end result that will affect the linked variables.
		Assign a node to it for it to take effect
	**/
	public var output:FoxBaseNode;

	/**
		Instantiates a new animation blender for an animation player.
		Needed for interpolating different animations and managing links.

		Adding an animation player here will disable it and the blender will take over.
	**/
	public function new(animPlayer:FoxAnimationPlayer) {
		super();
		name = "FoxAnimationBlender";
		player = animPlayer;
		enabled = true;
	}

	public override function update(dt:Float) {
		super.update(dt);
		if(player == null) return;
		delta = dt;
		for(node in nodes) if(node.active) node.process(this);
		if(output != null) player.updateLink(output.data);
	}
}