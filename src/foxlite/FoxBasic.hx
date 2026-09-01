package foxlite;

import foxlite.FoxCamera;
import foxlite.FoxScene;
import foxlite.group.FoxGroup;

class FoxBasic {
	
	public var name:String = "FoxBasic";
	public var visible(default, set):Bool = true;
	public var active:Bool = true;
	public var scene:FoxScene = null;
	public var __destroyed:Bool = false;

	/**
		A group of FoxBasic that can do stuff from this basic.
		Use this to store animation players, blenders, and other stuff you may find useful for your needs!
	**/
	public var managers:FoxGroup;

	public function new():Void {}

	public function update(dt:Float) {
		if(managers?.active == true) managers?.update(dt);
	}

	/**
		Intended for transforms, actual drawing happens in the camera render pass
	**/
	public function draw(camera:FoxCamera):Void {}

	/**
		This function gets called when the scene starts building draw groups.

		It should call the scene's `addToDrawGroups()` function for every drawable of this object.

		Override this with your custom draw data function.

		Note: Internal use only, it is a performance critical operation, keep it fast.
	**/
	public function pushDrawData(scene:FoxScene) {}

	public function destroy() {
		if(scene != null && !__destroyed) scene.remove(this);
		__destroyed = true;
		scene = null;
		managers = null;
	}

	private function set_visible(v:Bool):Bool {
		return this.visible = v;
	}
}