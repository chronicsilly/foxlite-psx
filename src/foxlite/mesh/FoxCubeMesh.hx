package foxlite.mesh;

import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMesh;

class FoxCubeMesh extends FoxMesh {
	public function new(width:Float, height:Float, depth:Float, _material:FoxMaterial=null, ?usage:Int) {
		super();
		material = _material;
		build(width, height, depth, usage);		
	}

	public function build(width:Float, height:Float, depth:Float, ?usage:Int) {
		var w2 = width / 2;
		var h2 = height / 2;
		var d2 = depth / 2;

		var vertices:Array<Float> = [
			// Front face
			-w2, -h2,  d2,  w2, -h2,  d2,  w2,  h2,  d2, -w2,  h2,  d2,
			// Back face
			-w2, -h2, -d2, -w2,  h2, -d2,  w2,  h2, -d2,  w2, -h2, -d2,
			// Top face
			-w2,  h2, -d2, -w2,  h2,  d2,  w2,  h2,  d2,  w2,  h2, -d2,
			// Bottom face
			-w2, -h2, -d2,  w2, -h2, -d2,  w2, -h2,  d2, -w2, -h2,  d2,
			// Right face
			 w2, -h2, -d2,  w2,  h2, -d2,  w2,  h2,  d2,  w2, -h2,  d2,
			// Left face
			-w2, -h2, -d2, -w2, -h2,  d2, -w2,  h2,  d2, -w2,  h2, -d2
		];

		var uvtData:Array<Float> = [
			// Front
			0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0,
			// Back
			0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0,
			// Top
			0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0,
			// Bottom
			0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0,
			// Right
			0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0,
			// Left
			0.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0, 1.0
		];

		var normals:Array<Float> = [
			// Front
			0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0,
			// Back
			0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0,
			// Top
			0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0,
			// Bottom
			0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0,
			// Right
			1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0,
			// Left
			-1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0
		];

		var indices:Array<Int> = [
			0,  1,  2,      0,  2,  3,    // front
			4,  5,  6,      4,  6,  7,    // back
			8,  9,  10,     8,  10, 11,   // top
			12, 13, 14,     12, 14, 15,   // bottom
			16, 17, 18,     16, 18, 19,   // right
			20, 21, 22,     20, 22, 23    // left
		];

		if(usage != null) bufferUsage = usage;
		setArrays(vertices, uvtData, indices, material, normals);
		calculateBounds(vertices);
	}
}