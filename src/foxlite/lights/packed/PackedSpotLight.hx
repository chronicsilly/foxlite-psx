package foxlite.lights.packed;

import openfl.geom.Vector3D;

class PackedSpotLight {
	public var color:Vector3D = new Vector3D();
	public var position:Vector3D = new Vector3D();
	public var direction:Vector3D = new Vector3D();
	public var shadowRegion:Vector3D; // Pointer to the light's shadowAtlasUV
	public var casterIndex:Int = -1;

	public function new() {}
}