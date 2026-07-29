package foxlite.texture;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxCubemapSide #if !foxlite_polymod (Int) from Int to Int #end {
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
}