package foxlite.skin;

import foxlite.FoxModel;
import foxlite.group.FoxObjectGroup;
import foxlite.skin.FoxSkinData;
#if foxlite_polymod
import foxlite.funkin.PolymodUtils;
#end

class FoxArmature extends FoxObjectGroup {
	
	/**
		Binds for this mesh, affects every model in this group.
	**/
	public var skin(default, set):FoxSkinData = null;

	public function new() {
		super();
		name = "FoxArmature";
	}

	/**
		Checks a model and assigns the skin bindings to it.
	**/
	public function checkModel(member:FoxObject):FoxObject {
		if(member == null) return null;
		var model:FoxModel = cast member; // Check skin
		#if foxlite_polymod
		if(PolymodUtils.instanceHasField(model, "skin")) model.skin = skin;
		#else
		if(Std.isOfType(model, FoxModel)) model.skin = skin;
		#end
		return member;
	}

	public override function add(member:FoxObject):FoxObject {
		member = super.add(member);
		return checkModel(member);
	}

	public override function insert(pos:Int, member:FoxObject):FoxObject {
		member = super.insert(pos, member);
		return checkModel(member);
	}
	
	public override function update(dt:Float) {
		super.update(dt);
		if(skin != null) {
			skin.root.transform = this.transform;
			skin.update(dt);
		}
	}

	private function set_skin(v:FoxSkinData):FoxSkinData {
		if(this.skin == v) return v;
		this.skin = v;
		forEach(m -> this.checkModel(m));
		return v;
	}
}