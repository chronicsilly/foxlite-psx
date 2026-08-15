package foxlite.material;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxDepthCompareMode #if !foxlite_polymod (Int) from Int to Int #end {
	/**
		The comparison always evaluates as true.
	**/
	public inline static final ALWAYS = 0;

	/**
		Equal (==).
	**/
	public inline static final EQUAL = 1;

	/**
		Greater than (>).
	**/
	public inline static final GREATER = 2;

	/**
		Greater than or equal (>=).
	**/
	public inline static final GREATER_EQUAL = 3;

	/**
		Less than (<).
	**/
	public inline static final LESS = 4;

	/**
		Less than or equal (<=).
	**/
	public inline static final LESS_EQUAL = 5;

	/**
		The comparison never evaluates as true.
	**/
	public inline static final NEVER = 6;

	/**
		Not equal (!=).
	**/
	public inline static final NOT_EQUAL = 7;

	@:from public static function fromString(mode:String):FoxDepthCompareMode {
		mode = mode.toLowerCase();
		return switch(mode) {
			case "equal": FoxDepthCompareMode.EQUAL;
			case "greater": FoxDepthCompareMode.GREATER;
			case "greater_equal": FoxDepthCompareMode.GREATER_EQUAL;
			case "less": FoxDepthCompareMode.LESS;
			case "less_equal": FoxDepthCompareMode.LESS_EQUAL;
			case "never": FoxDepthCompareMode.NEVER;
			default: FoxDepthCompareMode.ALWAYS;
		}
	}

	@:to public static function toString(mode:FoxDepthCompareMode) {
		return switch(mode) {
			case FoxDepthCompareMode.EQUAL: "equal";
			case FoxDepthCompareMode.GREATER: "greater";
			case FoxDepthCompareMode.GREATER_EQUAL: "greater_equal";
			case FoxDepthCompareMode.LESS: "less";
			case FoxDepthCompareMode.LESS_EQUAL: "less_equal";
			case FoxDepthCompareMode.NEVER: "never";
			default: "always";
		}
	}
}