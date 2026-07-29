package foxlite.mesh;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxMeshBufferType #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final VERTICES = 0;
	public inline static final UVS = 1;
	public inline static final NORMALS = 2;
	public inline static final TANGENTS = 3;
	public inline static final COLORS = 4;
	public inline static final WEIGHTS = 5;
	public inline static final BONE_INDICES = 6;
	public inline static final INDICES = 7;
}