package foxlite.mesh;

// How to create abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod abstract #else class #end FoxQuadFace #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final X = 0;
	public inline static final Y = 1;
	public inline static final Z = 2;

	@:from public static function fromString(face:String):FoxQuadFace {
		face = face.toUpperCase();
		return switch(face) {
			case 'x': FoxQuadFace.X;
			case 'y': FoxQuadFace.Y;
			case 'z': FoxQuadFace.Z;
			default: throw "Invalid string value";
		}
	}

	@:to public static function toString(face:FoxQuadFace):String {
		return switch(face) {
			case FoxQuadFace.X: 'x';
			case FoxQuadFace.Y: 'y';
			case FoxQuadFace.Z: 'z';
			default: throw "Invalid enum type";
		}
	}
}