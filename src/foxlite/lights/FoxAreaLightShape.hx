package foxlite.lights;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxAreaLightShape #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final SPHERE = 0;
	public inline static final BOX = 1;
	public inline static final TORUS = 2;
	public inline static final CAPPED_TORUS = 3;
	public inline static final LINK = 4;
	public inline static final HEXAGONAL_PRISM = 5;

	public static function fromString(shape:String):FoxAreaLightShape {
		shape = shape.toLowerCase();
		return switch(shape) {
			case "box": FoxAreaLightShape.BOX;
			case "torus": FoxAreaLightShape.TORUS;
			case "capped_torus": FoxAreaLightShape.CAPPED_TORUS;
			case "link": FoxAreaLightShape.LINK;
			case "hexagonal_prism": FoxAreaLightShape.HEXAGONAL_PRISM;
			default: FoxAreaLightShape.SPHERE;
		}
	}

	public static function toString(shape:FoxAreaLightShape):String {
		return switch(shape) {
			case FoxAreaLightShape.BOX: "box";
			case FoxAreaLightShape.TORUS: "torus";
			case FoxAreaLightShape.CAPPED_TORUS: "capped_torus";
			case FoxAreaLightShape.LINK: "link";
			case FoxAreaLightShape.HEXAGONAL_PRISM: "hexagonal_prism";
			default: "sphere";
		}
	}
}