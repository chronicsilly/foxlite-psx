package foxlite.texture;

// How to create abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod abstract #else class #end FoxWrapMode #if !foxlite_polymod (Int) from Int to Int #end {
	/**
		Clamp texture coordinates outside the 0..1 range.

		The function is x = max(min(x,0),1)
	**/
	public inline static final CLAMP = 0;

	/**
		Clamp in U axis but Repeat in V axis.
	**/
	public inline static final CLAMP_U_REPEAT_V = 1;

	/**
		Repeat (tile) texture coordinates outside the 0..1 range.

		The function is x = x<0?1.0-frac(abs(x)):frac(x)
	**/
	public inline static final REPEAT = 2;

	/**
		Repeat in U axis but Clamp in V axis.
	**/
	public inline static final REPEAT_U_CLAMP_V = 3;

	@:from public static function fromString(type:String):FoxWrapMode {
		type = type.toLowerCase();
		return switch(type) {
			case "repeat": FoxWrapMode.REPEAT;
			case "clamp_u_repeat_v": FoxWrapMode.CLAMP_U_REPEAT_V;
			case "repeat_u_clamp_v": FoxWrapMode.REPEAT_U_CLAMP_V;
			default: FoxWrapMode.CLAMP;
		}
	}

	@:to public static function toString(type:FoxWrapMode):String {
		return switch(type) {
			case FoxWrapMode.REPEAT: "repeat";
			case FoxWrapMode.CLAMP_U_REPEAT_V: "clamp_u_repeat_v";
			case FoxWrapMode.REPEAT_U_CLAMP_V: "repeat_u_clamp_v";
			default: "clamp";
		}
	}
}