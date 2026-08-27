package foxlite.texture;

// How to create abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod abstract #else class #end FoxMipFilter #if !foxlite_polymod (Int) from Int to Int #end {
	/**
		Select the two closest MIP levels and linearly blend between them (the highest
		quality mode, but has some performance cost).
	**/
	public inline static final MIPLINEAR = 0;

	/**
		Use the nearest neighbor metric to select MIP levels (the fastest rendering method).
	**/
	public inline static final MIPNEAREST = 1;

	/**
		Always use the top level texture (has a performance penalty when downscaling).
	**/
	public inline static final MIPNONE = 2;

	@:from public static function fromString(type:String):FoxMipFilter {
		type = type.toLowerCase();
		return switch(type) {
			case "miplinear": FoxMipFilter.MIPLINEAR;
			case "mipnearest": FoxMipFilter.MIPNEAREST;
			default: FoxMipFilter.MIPNONE;
		}
	}

	@:to public static function toString(type:FoxMipFilter) {
		return switch(type) {
			case FoxMipFilter.MIPLINEAR: "miplinear";
			case FoxMipFilter.MIPNEAREST: "mipnearest";
			default: "mipnone";
		}
	}
}