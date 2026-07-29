package foxlite.animation;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxAnimationEaseType #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final LINEAR = 0;
	public inline static final EASE_IN = 1;
	public inline static final EASE_OUT = 2;
	public inline static final EASE_INOUT = 3;
	public inline static final ZERO = 4;
}