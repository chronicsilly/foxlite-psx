package foxlite;

// Interface for transformable classes
// Probably won't add it due to HScript incompatibility
/*
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

interface IFoxTransformable {
	public var parent:FoxObject; 
	public var position:Vector3D;
	public var rotation:Vector3D;
	public var scale:Vector3D;

	// Convenience variables, Flixel-like
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;

	// Note: these convert degrees to radians and viceversa to be used in rotation, so they could be a bit slower
	// They are proxies, meaning you can't do operations such as +=, -=, *=, etc
	// Do this instead: `angleX = angleX + 10`
	public var angleX(get, set):Float;
	public var angleY(get, set):Float;
	public var angleZ(get, set):Float;

	// Internal transforms
	public var transform:Matrix3D;
	// TODO? add a setter and update position/rotation/scale in global space
	public var globalPosition(get, null):Vector3D;
	public var globalRotation(get, null):Vector3D;
	public var globalScale(get, null):Vector3D;
}
*/