package foxlite.post;

import foxlite.FoxModel;
import foxlite.FoxShader;
import foxlite.material.FoxBlendMode;
import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxQuadMesh;
import foxlite.texture.FoxTexture;

class FoxPostProcess extends FoxModel {

	public var renderPriority(get, set):Int;
	public var input(get, set):FoxTexture;
	public var samplers(get, never):Map<String, FoxTexture>;
	public var shader(get, set):FoxShader;

	public function new(shader_:FoxShader, priority:Int=1000) {
		super();
		name = "FoxPostProcess";

		var material = FoxMaterial.create(shader_);
		material.depthTest = false; // Also disables depth write
		material.depthWrite = false; // Also disables depth write
		material.depthFunc = 0; // never
		material.blendMode = FoxBlendMode.NONE;

		var quad = new FoxQuadMesh(2, 2, material); // Origin is at 0,0
		addMesh(quad);
		renderPriority = priority;
	}

	public override function update(dt:Float) {} // Skip transform operations

	private function get_input():FoxTexture {
		return meshes[0].material.textures.get("bitmap");
	}

	private function set_input(v:FoxTexture):FoxTexture {
		meshes[0].material.textures.set("bitmap", v);
		return v;
	}

	private function get_renderPriority():Int {
		return meshes[0].material.renderPriority;
	}

	private function set_renderPriority(v:Int):Int {
		meshes[0].material.renderPriority = v;
		return v;
	}

	private function get_samplers():Map<String, FoxTexture> {
		return meshes[0].material.textures;
	}

	private function get_shader():FoxShader {
		return meshes[0].material.shader;
	}

	private function set_shader(v:FoxShader):FoxShader {
		meshes[0].material.shader = v;
		return v;
	}
}