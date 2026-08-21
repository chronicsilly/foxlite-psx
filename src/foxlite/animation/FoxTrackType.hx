package foxlite.animation;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxTrackType #if !foxlite_polymod (Int) from Int to Int #end {
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
	public inline static final FUNCTION = 10;
	public inline static final DEGREES = 11;
	public inline static final COLOR = 12;

	@:from public static function fromString(type:String):FoxTrackType {
		type = type.toLowerCase();
		return switch(type) {
			case "int": FoxTrackType.INT;
			case "angle": FoxTrackType.ANGLE;
			case "vector3d": FoxTrackType.VECTOR3D;
			case "euler_angles": FoxTrackType.EULER_ANGLES;
			case "vector4": FoxTrackType.VECTOR4;
			case "quaternion": FoxTrackType.QUATERNION;
			case "bool": FoxTrackType.BOOL;
			case "vector2": FoxTrackType.VECTOR2;
			case "matrix4": FoxTrackType.MATRIX4;
			case "function": FoxTrackType.FUNCTION;
			case "degrees": FoxTrackType.DEGREES;
			case "color": FoxTrackType.COLOR;
			default: FoxTrackType.FLOAT;
		}
	}

	@:to public static function toString(type:FoxTrackType):String {
		return switch(type) {
			case FoxTrackType.INT: "int";
			case FoxTrackType.ANGLE: "angle";
			case FoxTrackType.VECTOR3D: "vector3d";
			case FoxTrackType.EULER_ANGLES: "euler_angles";
			case FoxTrackType.VECTOR4: "vector4";
			case FoxTrackType.QUATERNION: "quaternion";
			case FoxTrackType.BOOL: "bool";
			case FoxTrackType.VECTOR2: "vector2";
			case FoxTrackType.MATRIX4: "matrix4";
			case FoxTrackType.FUNCTION: "function";
			case FoxTrackType.DEGREES: "degrees";
			case FoxTrackType.COLOR: "color";
			default: "float";
		}
	}
}