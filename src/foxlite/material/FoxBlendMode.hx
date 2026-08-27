package foxlite.material;

// How to create abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod abstract #else class #end FoxBlendMode #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final NONE = 0; // No mixing, faster
	public inline static final MIX = 1;
	public inline static final ADD = 2;
	public inline static final SUBTRACT = 3;
	public inline static final MULTIPLY = 4;
	public inline static final PREMULTIPLIED_ALPHA = 5;

	@:from public static function fromString(blendMode:String):FoxBlendMode {
		blendMode = blendMode.toLowerCase();
		return switch(blendMode) {
			case "mix": FoxBlendMode.MIX;
			case "add": FoxBlendMode.ADD;
			case "subtract": FoxBlendMode.SUBTRACT;
			case "multiply": FoxBlendMode.MULTIPLY;
			case "premultiplied_alpha": FoxBlendMode.PREMULTIPLIED_ALPHA;
			default: FoxBlendMode.NONE;
		}
	}

	@:to public static function toString(blendMode:FoxBlendMode) {
		return switch(blendMode) {
			case FoxBlendMode.MIX: "mix";
			case FoxBlendMode.ADD: "add";
			case FoxBlendMode.SUBTRACT: "subtract";
			case FoxBlendMode.MULTIPLY: "multiply";
			case FoxBlendMode.PREMULTIPLIED_ALPHA: "premultiplied_alpha";
			default: "none";
		}
	}
}
