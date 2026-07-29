package foxlite.material;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxTriangleFace #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final BACK = 0;
	public inline static final FRONT = 1;
	public inline static final FRONT_AND_BACK = 2;
	public inline static final NONE = 3;

	public static function fromString(face:String):FoxTriangleFace {
		face = face.toLowerCase();
		return switch(face) {
			case "back": FoxTriangleFace.BACK;
			case "front": FoxTriangleFace.FRONT;
			case "front_and_back": FoxTriangleFace.FRONT_AND_BACK;
			default: FoxTriangleFace.NONE;
		}
	}
}