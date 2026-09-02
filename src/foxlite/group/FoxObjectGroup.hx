package foxlite.group;

import foxlite.FoxObject;
import foxlite.flixel.FlxTypedSignalImpl;
import foxlite.renderer.FoxRenderer;

/**
	This group accepts `FoxObject` exclusively for parent transform

	Think of it as being a layer you can move, and other objects will move with it inside
**/

// This would've been better with an interface but HScript doesn't support it
// So we need to copy everything again . . .
class FoxObjectGroup extends FoxObject {
	
	public var members:Array<FoxObject> = [];

	public final onMemberAdded:FlxTypedSignalImpl<(member:FoxObject)->Void> = new FlxTypedSignalImpl();
	public final onMemberRemoved:FlxTypedSignalImpl<(member:FoxObject)->Void> = new FlxTypedSignalImpl();

	public var length(get, never):Int;

	public function new() {
		super();
		name = "FoxGroup";
	}

	public function add(member:FoxObject):FoxObject {
		if(members.contains(member)) return null;
		if(member.parent == null) member.parent = this;
		member.scene = this.scene;
		var nullIdx = members.indexOf(null);
		if(nullIdx == -1) members.push(member);
		else members[nullIdx] = member;
		FoxRenderer.mustRebuildDrawGroups = true;
		onMemberAdded.dispatch(member);
		return member;
	}

	public function insert(pos:Int, member:FoxObject):FoxObject {
		if(member == null || members.contains(member)) return null;

		if(pos < length && members[pos] == null) {
			members[pos] = member;
			if(member.parent == null) member.parent = this;
			member.scene = this.scene;
			FoxRenderer.mustRebuildDrawGroups = true;
			return member;
		}
		else if(members[pos] == member) return member;
		else members.insert(pos, member);
		if(member.parent == null) member.parent = this;
		member.scene = this.scene;
		FoxRenderer.mustRebuildDrawGroups = true;
		onMemberAdded.dispatch(member);

		return member;
	}

	public function remove(member:FoxObject, splice:Bool=false):FoxObject {
		var memIdx = members.indexOf(member);
		if(memIdx == -1) return null;
		if(!splice) {
			members[memIdx] = null;
			if(member.parent == this) member.parent = null;
			member.scene = null;
		}
		else members.splice(memIdx, 1);
		FoxRenderer.mustRebuildDrawGroups = true;
		onMemberRemoved.dispatch(member);
		return member;
	}

	/**
		Changes the index of a member so it's processed before or after other members

		If index is smaller than 0, the member will move to the start of the list.

		If the index exceeds member count, the member will move to the end of the list.

		__Note:__ If there index is a free `null` space, the object will occupy it.

		__Note 2:__ This doesn't affect anything visually aside from transformations,
		if you want members to show over other members, configure their materials or render passes
	**/
	public function setOrder(member:FoxObject, index:Int=-1):FoxObject {
		if(!members.contains(member)) return null;
		remove(member);
		return insert(index < 0 ? 0 : (index >= length ? length-1 : index), member);
	}

	public function getByName(name:String):Array<FoxObject> {
		return members.filter(f -> f != null && f.name == name);
	}

	public function getFirstByName(name:String):FoxObject {
		for(m in members) if(m != null && m.name == name) return m;
		return null;
	}

	public inline function forEach(func:(member:FoxObject) -> Void, recurse:Bool=false) {
		for(m in members) if(m != null) {
			if(recurse) {
				#if !foxlite_polymod
				(cast m)?.forEach(func, recurse);
				#else
				if(PolymodUtils.instanceHasField(m, "forEach")) m.forEach(func, recurse);
				#end
			}
			func(m);
		}
	}

	public inline function iterator() {
		return members.iterator();
	}

	public inline function keyValueIterator() {
		return members.keyValueIterator();
	}

	public override function update(dt:Float) {
		super.update(dt);
		for(m in members) if(m != null && m.active) m.update(dt);
	}

	public override function draw(camera:FoxCamera) {
		super.draw(camera);
		for(m in members) if(m != null && m.visible) m.draw(camera);
	}

	public override function pushDrawData(scene:FoxScene) {
		for(m in members) if(m != null && m.visible) m.pushDrawData(scene);
	}

	public override function destroy() {
		while(members.length > 0) {
			members.pop()?.destroy();
		}
		members = null;
		super.destroy();
	}

	private function get_length():Int {
		return members.length;
	}
}