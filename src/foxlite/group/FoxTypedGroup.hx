package foxlite.group;

import foxlite.FoxBasic;
import foxlite.FoxCamera;
import foxlite.flixel.FlxTypedSignalImpl;
import foxlite.renderer.FoxRenderer;
#if foxlite_polymod
import foxlite.funkin.PolymodUtils;
#end

/**
	A very simple group implementation.
**/
class FoxTypedGroup #if !foxlite_polymod <T:FoxBasic> #end extends FoxBasic {
	
	public var members:Array<T> = [];

	public final onMemberAdded:FlxTypedSignalImpl<(member:FoxBasic)->Void> = new FlxTypedSignalImpl();
	public final onMemberRemoved:FlxTypedSignalImpl<(member:FoxBasic)->Void> = new FlxTypedSignalImpl();

	public var length(get, never):Int;

	public function new() {
		super();
		name = "FoxGroup";
	}

	public function add(member:T):T {
		if(members.contains(member)) return null;
		//if(member.parent == null) member.parent = this;
		member.scene = this.scene;
		var nullIdx = members.indexOf(null);
		if(nullIdx == -1) members.push(member);
		else members[nullIdx] = member;
		FoxRenderer.mustRebuildDrawGroups = true;
		onMemberAdded.dispatch(member);
		return member;
	}

	public function insert(pos:Int, member:T):T {
		if(member == null || members.contains(member)) return null;

		if(pos < length && members[pos] == null) {
			members[pos] = member;
			//if(member.parent == null) member.parent = this;
			member.scene = this.scene;
			FoxRenderer.mustRebuildDrawGroups = true;
			return member;
		}
		else members.insert(pos, member);
		//if(member.parent == null) member.parent = this;
		member.scene = this.scene;
		onMemberAdded.dispatch(member);
		FoxRenderer.mustRebuildDrawGroups = true;

		return member;
	}

	public function remove(member:T, splice:Bool=false):T {
		var memIdx = members.indexOf(member);
		if(memIdx == -1) return null;
		if(!splice) {
			members[memIdx] = null;
			//if(member.parent == this) member.parent = null;
			member.scene = null;
		}
		else members.splice(memIdx, 1);
		FoxRenderer.mustRebuildDrawGroups = true;
		onMemberRemoved(member);
		return member;
	}

	public inline function forEach(func:(member:T) -> Void, recurse:Bool=false) {
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