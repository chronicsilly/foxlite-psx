package foxlite.instancing;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxInstanceUpdateMode #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final ONE_BY_ONE = 0;
	public inline static final CHUNK = 1;
	public inline static final CLUSTERS = 2; // Same as chunks but there can be more than one, not implemented yet
	public inline static final ALL = 3;

	@:from public static function fromString(mode:String):FoxInstanceUpdateMode {
		mode = mode.toLowerCase();
		return switch(mode) {
			case "one_by_one": FoxInstanceUpdateMode.ONE_BY_ONE;
			case "clusters": FoxInstanceUpdateMode.CLUSTERS;
			case "all": FoxInstanceUpdateMode.ALL;
			default: FoxInstanceUpdateMode.CHUNK;
		}
	}

	@:to public static function toString(mode:FoxInstanceUpdateMode):String {
		return switch(mode) {
			case FoxInstanceUpdateMode.ONE_BY_ONE: "one_by_one";
			case FoxInstanceUpdateMode.CLUSTERS: "clusters";
			case FoxInstanceUpdateMode.ALL: "all";
			default: "chunk";
		}
	}
}