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

	public function new(?material:FoxMaterial, ?tex:FoxTexture) {
		super();
		name = "FoxPanoramaSky";
		if(material == null) {
			material = FoxMaterial.create(FoxShader.fromAsset(FoxShader.SKY), tex != null ? ["skyTexture" => tex] : null);
			material.params.set("skyOffset", offset);
		}
		material.depthTest = false; 
		material.blendMode = FoxBlendMode.NONE;
		material.depthWrite = false;
		material.renderPriority = -1000; // Render before anything

		var quad = new FoxQuadMesh(2, 2, material); // Origin is at 0,0
		addMesh(quad);
	}

	public override function update(dt:Float) {}// Skip transform operations

	public override function draw(camera:FoxCamera) {
		// Set environment sky texture with ours
		var env = scene.environment;
		env.skyTexture = #if !foxlite_polymod cast #end texture;
		env.skyOffset.setTo(offset.x, offset.y);
	}

	private function set_texture(tex:FoxTexture) {
		meshes[0]?.material?.textures?.set("skyTexture", tex);
		return tex;
	}

	private function get_texture():FoxTexture {
		return meshes[0]?.material?.textures?.get("skyTexture");
	}

	private function set_offset(v:Vector2) {
		this.offset = v;
		this.meshes[0]?.material?.params.set("skyOffset", v);
		return v;
	}
}