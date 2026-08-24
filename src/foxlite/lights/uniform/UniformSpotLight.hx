package foxlite.lights.uniform;

import openfl.geom.Vector3D;

class UniformSpotLight {
	public var color:Vector3D = new Vector3D();
	public var position:Vector3D = new Vector3D();
	public var direction:Vector3D = new Vector3D();
	public var shadowRegion:Vector3D; // Pointer to the light's shadowAtlasUV
	public var casterIndex:Int = -1;

	public function new() {}
}