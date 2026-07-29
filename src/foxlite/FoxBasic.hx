package foxlite;

import foxlite.FoxCamera;
import foxlite.FoxScene;

class FoxBasic {
	
	public var _name:String = "FoxBasic";
	public var name(get, set):String;
	public var visible:Bool = true;
	public var active:Bool = true;
	public var priority:Int = 0;
	public var scene:FoxScene = null;
	public var __destroyed:Bool = false;

	public function new():Void {}

	public function update(dt:Float) {}

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
	}

	// Render events

	public function onScenePreDraw():Void {}
	public function onScenePostDraw():Void {}

	private function get_name():String {
		return _name;
	}
	// Handle name changes when added to scene
	private function set_name(v:String) {
		if(this.scene != null) this.scene.rename(this, v); // We need to do some extra operations if we're on a scene
		else this._name = v;
		return v;
	}
}