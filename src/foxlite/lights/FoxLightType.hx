package foxlite.lights;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxLightType #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final DIRECTIONAL = 0;
	public inline static final POINT = 1;
	public inline static final SPOT = 2;
	public inline static final AREA = 3;
}