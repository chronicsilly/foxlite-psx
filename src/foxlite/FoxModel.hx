package foxlite;

import foxlite.FoxLayer;
import foxlite.FoxObject;
import foxlite.FoxShader;
import foxlite.loaders.FoxJSONLoader;
import foxlite.loaders.FoxOBJLoader;
import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMesh;
import foxlite.renderer.FoxRenderer;
import foxlite.skin.FoxSkinData;
import openfl.display3D.Context3D;
import openfl.geom.Matrix3D;

class FoxModel extends FoxObject {

	public var layers:FoxLayer;
	public var frustumCulling:Bool;

	public var context:Context3D;

	/**
		This is the object's transform from a previous frame, used for motion vector calculations.
		
		Having to calculate previous transforms on empty objects is a bit pointless, so that's why this is here.
	**/
	public var __prevTransform:Matrix3D = new Matrix3D();

	/**
		The draw groups from a scene this object will be drawn on.

		Used mainly to separate meshes in passes in an optimized manner.

		__Note:__ When changing this array manually, always set `FoxRenderer.mustRebuildDrawGroups` to `true`
		to ensure proper updating.

		There are dedicated functions for this below:

		- `addToDrawGroup(group)`
		- `removeFromDrawGroup(group)`
		- `setDrawGroupAt(i, group)`

	**/
	public var groups(default, set):Array<Int> = [0];

	private function set_groups(v:Array<Int>) {
		this.groups = v;
		FoxRenderer.mustRebuildDrawGroups = true;
		return v;
	}

	/**
		Meshes that will be rendered by this model, they
		inherit this model transform.

		__Note:__ When changing this array manually, always set `FoxRenderer.mustRebuildDrawGroups` to `true`
		to ensure proper updating.

		There are dedicated functions for this below:

		- `setMeshAt(i, mesh)`
		- `addMesh(mesh)`
		- `removeMesh(mesh)`
		- `removeMeshByIndex(mesh)`
	**/
	public var meshes(default, set):Array<FoxMesh> = [];

	private function set_meshes(v:Array<FoxMesh>) {
		this.meshes = v;
		FoxRenderer.mustRebuildDrawGroups = true;
		return v;
	}

	/**
		If set, this material will be applied to every mesh of this model when rendering.
	**/
	public var materialOverride:FoxMaterial = null;

	/**
		If set, this material will be applied over every mesh of this model.

		This will draw the meshes again using this material.
	**/
	public var materialOverlay:FoxMaterial = null;

	/**
		The skin associated with this mesh, assigned when added to a `FoxArmature`
	**/
	public var skin:FoxSkinData = null;

	/**
		Wheter or not cast shadows (rendering in the shadow pass)
	**/
	public var castShadows:Bool = true;

	/**
		If true, this model will cast colored shadows, useful
		for tinted transluscent objects (stained glass, liquids, fabric).

		Requires `castShadows` to be true.

		__Note:__ This is not implemented yet.
	**/
	public var castColoredShadows:Bool = false;

	public function new(x:Float=0, y:Float=0, z:Float=0, layers:FoxLayer=0x1, ?groups:Array<Int>, culling:Bool=true):Void {
		super(x, y, z);
		this.layers = layers;
		if(groups != null) this.groups = groups;
		frustumCulling = culling;
		context = FoxRenderer.getContext();
		name = "FoxModel";
	}

	public override function update(dt:Float) {
		if(FoxRenderer.calculateMotionVectors) __prevTransform.copyRawDataFrom(transform.rawData);
		super.update(dt);
	}

	public override function pushDrawData(scene:FoxScene) {
		for(mesh in meshes) {
			var mat = materialOverride ?? mesh.material ?? FoxRenderer.MISSING_MATERIAL;
			if(mat != null) scene.addToDrawGroups(mat, mesh, groups, this);
		}
		// For overlay, add another node
		if(materialOverlay != null) for(mesh in meshes) {
			scene.addToDrawGroups(materialOverlay, mesh, groups, this);
		}
	}

	// Just a proxy to make things easier
	public function renderMesh(mesh:FoxMesh, shader:FoxShader) {
		if(mesh.indexBuffer != null) FoxRenderer.drawMesh(context, mesh, shader);
	}

	public function isInstanced() {
		return false;
	}

	public inline function addMesh(mesh:FoxMesh) {
		meshes.push(mesh);
		FoxRenderer.mustRebuildDrawGroups = true;
	}

	public inline function setMeshAt(index:Int, mesh:FoxMesh) {
		meshes[index] = mesh;
		FoxRenderer.mustRebuildDrawGroups = true;
	}

	public inline function removeMesh(mesh:FoxMesh) {
		FoxRenderer.mustRebuildDrawGroups = meshes.remove(mesh);
	}

	public inline function removeMeshByIndex(index:Int) {
		if(index < 0 || index >= meshes.length) return;
		meshes.splice(index, 1);
		FoxRenderer.mustRebuildDrawGroups = true;
	}

	public inline function addToDrawGroup(group:Int) {
		if(groups.contains(group)) return;
		groups.push(group);
		FoxRenderer.mustRebuildDrawGroups = true;
	}

	public inline function removeFromDrawGroup(group:Int) {
		if(!groups.contains(group)) return;
		groups.remove(group);
		FoxRenderer.mustRebuildDrawGroups = true;
	}

	public inline function setDrawGroupAt(index:Int, group:Int) {
		groups[index] = group;
		FoxRenderer.mustRebuildDrawGroups = true;
	}

	/**
		Shortcut to get a material from a mesh by index
	**/
	public function getMaterial(meshIdx:Int):FoxMaterial {
		return meshes[meshIdx]?.material;
	}

	/**
		Shortcut to assign a material to a mesh by index
	**/
	public function setMaterial(meshIdx:Int, mat:FoxMaterial) {
		var m:FoxMesh = meshes[meshIdx];
		if(m != null) m.material = mat;
	}

	/**
		Loads a FoxLite JSON model
	**/
	public function loadJSON(name:String) {
		var data = FoxJSONLoader.loadModel(name);
		if(data == null) return null;
		this.meshes = data.meshes;
		return data;
	}

	public function loadOBJ(name:String, ?extraShaderFlags:Array<String>, ?customShaderPath:String, ?texturePath:String) {
		var data = FoxOBJLoader.load(name, extraShaderFlags, customShaderPath, texturePath);
		if(data == null) return null;
		meshes = data.meshes;
		return data;
	}

	public override function destroy() {
		meshes = null;
		super.destroy();
	}
}