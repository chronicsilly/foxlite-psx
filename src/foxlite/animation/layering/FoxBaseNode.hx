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
	
	/**
		If true, the node will initialize data for its tracks at the start of the blend frame.
		This should only be set when the node is ready to be used
		(i.e: After adding tracks, or removing tracks)
		
		If tracks or animations have been updated, you might want to set this property again.
	**/
	public var initRequired = true;

	public function new() {}

	public function process(blender:FoxAnimationBlender) {}
	public function initialize(tracks:StringMap<FoxTrackData>) {
		if(!initRequired) return;
		var td:FoxTrackData = null;
		data.clear();
		for(name=>track in tracks) if(!data.exists(name)) data.set(name, td = new FoxTrackData(track.type));
		if(td != null) initRequired = false;
	}
}