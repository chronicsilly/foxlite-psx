package foxlite.texture;

// How to create abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod abstract #else class #end FoxCubemapSide #if !foxlite_polymod (Int) from Int to Int #end {
	/**
		Positive X side of the cubemap
	**/
	public inline static final RIGHT = 0;

	/**
		Negative X side of the cubemap
	**/
	public inline static final LEFT = 1;

	/**
		Positive Y side of the cubemap
	**/
	public inline static final TOP = 2;

	/**
		Negative Y side of the cubemap
	**/
	public inline static final BOTTOM = 3;

	/**
		Positive Z side of the cubemap
	**/
	public inline static final BACK = 4;

	/**
		Negative Z side of the cubemap
	**/
	public inline static final FRONT = 5;

	@:from public static function fromString(side:String):FoxCubemapSide {
		side = side.toLowerCase();
		return switch(side) {
			case "right": FoxCubemapSide.RIGHT;
			case "left": FoxCubemapSide.LEFT;
			case "top": FoxCubemapSide.TOP;
			case "bottom": FoxCubemapSide.BOTTOM;
			case "back": FoxCubemapSide.BACK;
			case "front": FoxCubemapSide.FRONT;
			default: throw "Invalid string value";
		}
	}

	@:to public static function toString(side:FoxCubemapSide):String {
		return switch(side) {
			case FoxCubemapSide.RIGHT: "right";
			case FoxCubemapSide.LEFT: "left";
			case FoxCubemapSide.TOP: "top";
			case FoxCubemapSide.BOTTOM: "bottom";
			case FoxCubemapSide.BACK: "back";
			case FoxCubemapSide.FRONT: "front";
			default: throw "Invalid enum type";
		}
	}
}