package foxlite.animation;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxAnimationTrackType #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final FLOAT = 0;
	public inline static final INT = 1;
	public inline static final ANGLE = 2;
	public inline static final VECTOR3D = 3;
	public inline static final EULER_ANGLES = 4; // Vector3D of angles
	public inline static final VECTOR4 = 5; // Color
	public inline static final QUATERNION = 6; // Vector4 of Quaternion
	public inline static final BOOL = 7; 
	public inline static final VECTOR2 = 8;
	public inline static final MATRIX4 = 9;

	public static function fromString(type:String):FoxAnimationTrackType {
		type = type.toLowerCase();
		return switch(type) {
			case "int": FoxAnimationTrackType.FLOAT;
			case "angle": FoxAnimationTrackType.ANGLE;
			case "vector3d": FoxAnimationTrackType.VECTOR3D;
			case "euler_angles": FoxAnimationTrackType.EULER_ANGLES;
			case "vector4": FoxAnimationTrackType.VECTOR4;
			case "quaternion": FoxAnimationTrackType.QUATERNION;
			case "bool": FoxAnimationTrackType.BOOL;
			case "vector2": FoxAnimationTrackType.VECTOR2;
			case "matrix4": FoxAnimationTrackType.MATRIX4;
			default: FoxAnimationTrackType.FLOAT;
		}
	}
}