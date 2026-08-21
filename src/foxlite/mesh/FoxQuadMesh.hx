package foxlite.mesh;

import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMesh;
import foxlite.mesh.FoxQuadFace;

/**
	Helper to create a simple quad facing an orientation
**/
class FoxQuadMesh extends FoxMesh {
	public function new(width:Float, height:Float, material_:FoxMaterial=null, face:FoxQuadFace=#if !foxlite_polymod FoxQuadFace.Z #else 2 #end, ?usage:Int) {
		super();
		material = material_;
		build(width, height, face, usage);
	}

	public function build(width:Float, height:Float, face:FoxQuadFace, ?usage:Int) {
		var w2 = width / 2;
		var h2 = height / 2;

		var vertices:Array<Float> = switch(face) {
			case FoxQuadFace.X: [
				0, -w2,  h2,
				0,  w2,  h2,
				0,  w2, -h2,
				0, -w2, -h2
			];
			case FoxQuadFace.Y: [
				-w2, 0,  h2,
				 w2, 0,  h2,
				 w2, 0, -h2,
				-w2, 0, -h2
			];
			case FoxQuadFace.Z: [
				-w2,  h2, 0,
				 w2,  h2, 0,
				 w2, -h2, 0,
				-w2, -h2, 0
			];
			case _: [];
		}

		var normals:Array<Float> = switch(face) {
			case FoxQuadFace.X: [
				1, 0, 0,
				1, 0, 0,
				1, 0, 0,
				1, 0, 0
			];
			case FoxQuadFace.Y: [
				0, 1, 0,
				0, 1, 0,
				0, 1, 0,
				0, 1, 0
			];
			case FoxQuadFace.Z: [
				0, 0, 1,
				0, 0, 1,
				0, 0, 1,
				0, 0, 1
			];
			case _: [];
		}

		var uvtData:Array<Float> = [
			0, 0,
			1, 0,
			1, 1,
			0, 1
		];

		var indices = [
			0, 1, 2, 
			0, 2, 3
		];

		if(usage != null) bufferUsage = usage;
		setArrays(vertices, uvtData, indices, material, normals);
	}
}