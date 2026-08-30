package foxlite.animation.layering;

import foxlite.animation.data.FoxTrackData;
import haxe.ds.StringMap;
import foxlite.animation.FoxAnimationBlender;

class FoxBaseNode {

	/**
		This is where interpolated values for this source are stored.
	**/
	public var data:StringMap<FoxTrackData> = new StringMap();
	public var active:Bool = true;

	public function new() {}

	public function process(blender:FoxAnimationBlender) {}
	public function initialize(tracks:StringMap<FoxTrackData>) {
		for(name=>track in tracks) {
			if(!data.exists(name)) data.set(name, new FoxTrackData(track.type));
		}
	}
}