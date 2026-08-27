package foxlite.texture;

// How to create abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod abstract #else class #end FoxTextureFilter #if !foxlite_polymod (Int) from Int to Int #end {
	/**
		Use anisotropic filter with radio 16 when upsampling textures
	**/
	public inline static final ANISOTROPIC16X = 0;

	/**
		Use anisotropic filter with radio 2 when upsampling textures
	**/
	public inline static final ANISOTROPIC2X = 1;

	/**
		Use anisotropic filter with radio 4 when upsampling textures
	**/
	public inline static final ANISOTROPIC4X = 2;

	/**
		Use anisotropic filter with radio 8 when upsampling textures
	**/
	public inline static final ANISOTROPIC8X = 3;

	/**
		Use linear interpolation when upsampling textures (gives a smooth, blurry look).
	**/
	public inline static final LINEAR = 4;

	/**
		Use nearest neighbor sampling when upsampling textures (gives a pixelated,
		sharp mosaic look).
	**/
	public inline static final NEAREST = 5;

	@:from public static function fromString(type:String):FoxTextureFilter {
		type = type.toLowerCase();
		return switch(type) {
			case "aniso16x": FoxTextureFilter.ANISOTROPIC16X;
			case "aniso2x": FoxTextureFilter.ANISOTROPIC2X;
			case "aniso4x": FoxTextureFilter.ANISOTROPIC4X;
			case "aniso8x": FoxTextureFilter.ANISOTROPIC8X;
			case "nearest": FoxTextureFilter.NEAREST;
			default: FoxTextureFilter.LINEAR;
		}
	}

	@:to public static function toString(type:FoxTextureFilter):String {
		return switch(type) {
			case FoxTextureFilter.ANISOTROPIC16X: "aniso16x";
			case FoxTextureFilter.ANISOTROPIC2X: "aniso2x";
			case FoxTextureFilter.ANISOTROPIC4X: "aniso4x";
			case FoxTextureFilter.ANISOTROPIC8X: "aniso8x";
			case FoxTextureFilter.NEAREST: "nearest";
			default: "linear";
		}
	}
}