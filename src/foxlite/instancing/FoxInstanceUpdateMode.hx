package foxlite.instancing;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxInstanceUpdateMode #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final ONE_BY_ONE = 0;
	public inline static final CHUNK = 1;
	public inline static final CLUSTERS = 2; // Same as chunks but there can be more than one, not implemented yet
	public inline static final ALL = 3;
}