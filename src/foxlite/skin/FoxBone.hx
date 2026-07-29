package foxlite.skin;

import foxlite.math.FoxMathUtil;
import openfl.geom.Matrix3D;

class FoxBone extends FoxObject {

	/**
		If disabled, this bone won't calculate its position/rotation/scale
	**/
	public var poseEnabled:Bool = true;
	
	/**
		The rest pose of this bone.

		This is used as offset (pivot) for bone transform.
	**/
	public var offset:Matrix3D;

	/**
		The index of the parent of this bone.
		
		Currently, this is purely informational.
	**/
	public var parentIndex:Int = -1;
	
	/**
		Creates a new bone for an armature.

		@param rest The rest pose transform for this bone
	**/
	public function new(rest:Matrix3D) {
		super();
		offset = rest;
		name = "FoxBone";
	}

	public override function update(dt:Float) {
		if(poseEnabled) FoxMathUtil.transformMatrix(transform, position, rotation, scale);
		else FoxMathUtil.fastIdentity(transform);
		if(parent != null) transform.append(parent.transform);
	}
}