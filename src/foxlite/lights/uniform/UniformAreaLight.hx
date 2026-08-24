package foxlite.lights.uniform;

import openfl.geom.Vector3D;

class UniformAreaLight {
	public var color:Vector3D = new Vector3D();
	public var position:Vector3D = new Vector3D();
	public var direction:Vector3D = new Vector3D();
	public var sdfData:Vector3D = new Vector3D();
	public var casterIndex:Int = -1;

	public function new() {}
}