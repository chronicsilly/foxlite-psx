package foxlite.animation;

import haxe.ds.StringMap;
import foxlite.animation.data.FoxTrackData;
import foxlite.animation.data.FoxTrackLinkData;
import foxlite.animation.FoxAnimation;
import foxlite.animation.FoxTrackType;
import foxlite.skin.FoxSkinData;
import foxlite.FoxBasic;

class FoxAnimationLinker extends FoxBasic {

	public var linkData:Map<String, Array<FoxTrackLinkData>> = new StringMap();
	
	/**
		Links an object's property to an animation track, thus causing it to animate.

		Functions work aswell! In that case, the number of components of a vector will serve as arguments:
		For example `FlxSprite.setPosition()` will recieve the `Vector2` `x` and `y`.
		
		The only exception to this is tracks of type `Matrix3D`, they will recieve the matrix object instead.

		__Note:__ For non-functions, make sure the property type and the track type are equal, else the link will not work.

		@returns The index of the link in the track
	**/
	public function link(trackName:String, object:Dynamic, property:String):Int {
		var data:Array<FoxTrackLinkData> = linkData.get(trackName);
		
		if(data == null) {
			linkData.set(trackName, [new FoxTrackLinkData(object, property)]);
			return 0;
		}
		
		var idx = findLink(trackName, object, property);
		if(idx == -1) {
			data.push(new FoxTrackLinkData(object, property));
			return data.length-1;
		}
		return idx;
	}

	/**
		Removes an object's property from a linked animation track.
	**/
	public function unlink(trackName:String, object:Dynamic, property:String) {
		var data:Array<FoxTrackLinkData> = linkData.get(trackName);
		if(data == null) return;

		var toRemove:FoxTrackLinkData = null;
		for(link in data) {
			if(link.object == object && link.property == property) {
				toRemove = link;
				break;
			}
		}
		if(toRemove != null) data.remove(toRemove);
	}

	/**
		Removes a link from an animation track by its index
	**/
	public function unlinkByIndex(trackName:String, index:Int) {
		var data = linkData.get(trackName);
		if(data == null) return;

		if(index >= 0 && index < data.length) data?.splice(index, 1);
	}

	/**
		Removes all links of an object from the linker.

		@param property (Optional) A property name which will act as a filter, and
		will only remove links affecting that property.
		@param trackName (Optional) If set, it will remove all links from that track only.
	**/
	public function unlinkAllOf(object:Dynamic, ?property:String, ?trackName:String) {
		var removals:Array<FoxTrackLinkData> = [];
		if(trackName == null) for(data in linkData) {
			removals.resize(0);
			for(link in data) if(link.object == object && (property == null || link.property == property)) removals.push(link);
			while(removals.length > 0) data.remove(removals.pop());
		}
		else {
			var data = linkData.get(trackName);
			if(data == null) return;
			for(link in data) if(link.object == object && (property == null || link.property == property)) removals.push(link);
			while(removals.length > 0) data.remove(removals.pop());
		}
	}

	/**
		Links all supported tracks to a `FoxSkinData`

		Tracks with the name following the format `boneName:property` will be linked.
		Supported properties are `position`, `rotation` and `scale`
	**/
	public function linkSkin(skin:FoxSkinData) {
		for(bone in skin.bones) {
			link('${bone.name}:quaternion', bone, "setRotationQuaternion");
			link('${bone.name}:scale', bone, "setScale");
			link('${bone.name}:position', bone, "setPosition");
		}
	}

	public function unlinkSkin(skin:FoxSkinData) {
		for(bone in skin.bones) {
			unlink('${bone.name}:quaternion', bone, "setRotationQuaternion");
			unlink('${bone.name}:scale', bone, "setScale");
			unlink('${bone.name}:position', bone, "setPosition");
		}
	}

	/**
		Links a `FoxObject`'s transforms to this track data
	**/
	public function linkObject(trackPrefix:String, object:FoxObject) {
		link('$trackPrefix:quaternion', object, "setRotationQuaternion");
		link('$trackPrefix:scale', object, "setScale");
		link('$trackPrefix:position', object, "setPosition");
	}

	public function unlinkObject(trackPrefix:String, object:FoxObject) {
		unlink('$trackPrefix:quaternion', object, "setRotationQuaternion");
		unlink('$trackPrefix:scale', object, "setScale");
		unlink('$trackPrefix:position', object, "setPosition");
	}

	/**
		Searches for a link for a track and returns its index on the linker
	**/
	public function findLink(trackName:String, object:Dynamic, property:String):Int {
		var data = linkData.get(trackName);
		if(data == null) return -1;
		for(i=>link in data) if(link.object == object && link.property == property) return i;
		return -1;
	}

	public function clearLinks() {
		linkData.clear();
	}

	/**
		Sends tracks value to the objects with linked properties

		@param trackSrc The tracks source
	**/
	public function updateLink(trackSrc:Map<String, FoxTrackData>) {
		for(trackName=>array in linkData) {
			var data = trackSrc.get(trackName);
			if(data == null) continue;
			for(link in array) if(link.enabled) link.process(data);
		}
	}

	public override function destroy() {
		linkData = null;
		super.destroy();
	}
}