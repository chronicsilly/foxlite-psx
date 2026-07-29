package foxlite.mesh;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxQuadFace #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final X = 0;
	public inline static final Y = 1;
	public inline static final Z = 2;
}