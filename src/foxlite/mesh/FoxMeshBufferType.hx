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

	@:from public static function fromString(bufType:String):FoxMeshBufferType {
		bufType = bufType.toLowerCase();
		return switch(bufType) {
			case "vertices": FoxMeshBufferType.VERTICES;
			case "uvs": FoxMeshBufferType.UVS;
			case "normals": FoxMeshBufferType.NORMALS;
			case "tangents": FoxMeshBufferType.TANGENTS;
			case "colors": FoxMeshBufferType.COLORS;
			case "weights": FoxMeshBufferType.WEIGHTS;
			case "bone_indices": FoxMeshBufferType.BONE_INDICES;
			case "indices": FoxMeshBufferType.INDICES;
			default: throw "Invalid string value";
		}
	}

	@:to public static function toString(bufType:FoxMeshBufferType):String {
		return switch(bufType) {
			case FoxMeshBufferType.VERTICES: "vertices";
			case FoxMeshBufferType.UVS: "uvs";
			case FoxMeshBufferType.NORMALS: "normals";
			case FoxMeshBufferType.TANGENTS: "tangents";
			case FoxMeshBufferType.COLORS: "colors";
			case FoxMeshBufferType.WEIGHTS: "weights";
			case FoxMeshBufferType.BONE_INDICES: "bone_indices";
			case FoxMeshBufferType.INDICES: "indices";
			default: throw "Invalid enum type";
		}
	}
}