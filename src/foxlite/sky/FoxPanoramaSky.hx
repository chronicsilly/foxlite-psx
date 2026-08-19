package foxlite.sky;

import foxlite.FoxModel;
import foxlite.FoxShader;
import foxlite.material.FoxBlendMode;
import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxQuadMesh;
import foxlite.texture.FoxTexture;
import lime.math.Vector2;

class FoxPanoramaSky extends FoxModel {

	public var offset(default, set):Vector2 = new Vector2(0, 0);
	public var texture(get, set):FoxTexture;
	public var material(get, set):FoxMaterial;

	public function new(?material:FoxMaterial, ?tex:FoxTexture) {
		super();
		name = "FoxPanoramaSky";
		if(material == null) {
			material = FoxMaterial.createSky(tex);
		}
		else if(tex != null) material.textures.set("skyTexture", tex);
		material.params.set("skyOffset", offset);

		castShadows = false; // Do not render in shadowmaps
		var quad = new FoxQuadMesh(2, 2, material); // Origin is at 0,0
		addMesh(quad);
	}

	public override function update(dt:Float) {}// Skip transform operations

	public override function draw(camera:FoxCamera) {
		// Set environment sky texture with ours
		var env = scene.environment;
		env.skyTexture = cast texture;
		env.skyOffset.setTo(offset.x, offset.y);
	}

	private function set_texture(tex:FoxTexture) {
		meshes[0]?.material?.textures?.set("skyTexture", tex);
		return tex;
	}

	private function get_texture():FoxTexture {
		return meshes[0]?.material?.textures?.get("skyTexture");
	}

	private function set_material(mat:FoxMaterial) {
		if(meshes[0] != null) meshes[0].material = mat;
		return meshes[0]?.material;
	}

	private function get_material():FoxMaterial {
		return meshes[0]?.material;
	}

	private function set_offset(v:Vector2) {
		this.offset = v;
		this.meshes[0]?.material?.params.set("skyOffset", v);
		return v;
	}
}