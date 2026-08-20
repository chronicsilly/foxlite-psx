package foxlite;

import foxlite.flixel.FoxExtendableBasic;
import foxlite.group.FoxTypedGroup.FoxGroup;

/**
	Like `FoxScene`, but it only updates a `FoxGroup` (no rendering ever happens).

	Use this if you only want classes that require updating by foxlite (such as `FoxAnimationPlayer`)-
**/
class FoxOfflineScene extends FoxExtendableBasic {

	public var members:FoxGroup = new FoxGroup();

	public override function update(elapsed:Float) {
		members.update(elapsed);
	}

	public inline function add(member:FoxBasic) {
		members.add(member);
	}

	public inline function insert(pos:Int, member:FoxBasic) {
		members.insert(pos, member);
	}

	public inline function remove(member:FoxBasic) {
		members.remove(member);
	}

	public override function destroy() {
		members.destroy();
		super.destroy();
	}
}