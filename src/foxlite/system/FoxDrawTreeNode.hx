package foxlite.system;

import List;
import foxlite.FoxModel;
import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMesh;
import foxlite.renderer.FoxRenderer;

/**
* A FoxDrawTreeNode that stores `FoxMaterial` and a list of `FoxMesh` along with `FoxObject`s for transform.
*/
class FoxDrawTreeNode {

	public var material:FoxMaterial;
	public var meshes:List<FoxMesh> = new List();
	public var models:List<FoxModel> = new List();

	public function new(mat:FoxMaterial) {
		FoxRenderer.allocationsThisFrame += 3;
		material = mat;
	}
}