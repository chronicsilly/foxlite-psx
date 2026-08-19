package foxlite.lights.packed;

import openfl.geom.Vector3D;

class PackedPointLight {
	public var color:Vector3D = new Vector3D();
	public var position:Vector3D = new Vector3D();
	public var casterIndex:Int = -1;

	public function new() {}
}