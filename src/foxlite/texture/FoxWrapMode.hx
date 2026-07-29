package foxlite.texture;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxWrapMode #if !foxlite_polymod (Int) from Int to Int #end {
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
}