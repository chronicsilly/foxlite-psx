/*
*    ___           __ _ _       
*   / __\____  __ / /(_) |_ ___ 
*  / _\/ _ \ \/ // / | | __/ _ \
* / / | (_) >  </ /__| | ||  __/
* \/   \___/_/\_\____/_|\__\___| by dwdvIl
*                              
* 	     -- FoxFlxSprite --
* 
* Use your flixel sprites in the 3D renderer!
* It only supports whole bitmaps and atlases
* For FlxAnimate sprites, use FoxFunkinSprite!!!
*
*/

package foxlite.flixel;

import flixel.FlxSprite;
import foxlite.FoxModel;
import foxlite.material.FoxBlendMode;
import foxlite.material.FoxMaterial;
import foxlite.material.FoxTriangleFace;
import foxlite.mesh.FoxMeshBufferType;
import foxlite.mesh.FoxQuadMesh;
import foxlite.texture.FoxTexture;
import lime.graphics.opengl.GL;
import openfl.display.BitmapData;

class FoxFlxSprite extends FoxModel {

	public var sprite:FlxSprite = null;
	public var pixelSize:Float = 0.01; // Size of the pixels in the world

	var __prevFrame:String = "null";
	var __prevBitmap:BitmapData = null;
	var __recalculateBounds:Bool = true;

	// Shortcuts
	public var material(get, set):FoxMaterial;
	public var texture(get, set):FoxTexture;
	public var shader(get, set):FoxShader;

	public function new(target:FlxSprite, ?material_:FoxMaterial, ?spritePixelSize:Float) {
		super();
		name = "FoxFlxSprite";
		if(target.pixels == null) return;
		if(spritePixelSize == null) spritePixelSize = pixelSize;
		pixelSize = spritePixelSize;
		sprite = target;

		var tex = FoxTexture.wrap(target.pixels);

		if(material_ == null) {
			material_ = FoxMaterial.create(FoxShader.fromAsset(FoxShader.BASIC), ["bitmap" => tex]);
			material_.shadowCulling = FoxTriangleFace.NONE; // Render shadow for front and back faces
		}
		else {
			material_.textures.set("bitmap", tex);
			material_.params.set("uScattering", 1.0); // Light all the plane regardless of normals
		}
		material_.blendMode = FoxBlendMode.MIX; 
		material_.alphaScissor = 0.05; // Cutout invisible pixels

		var mesh = new FoxQuadMesh(target.width * pixelSize, target.height * pixelSize, material_, 2, GL.DYNAMIC_DRAW);
		addMesh(mesh);
		//calculateMesh(); // Calculate on 1st frame instead
	}

	public inline function getWidth():Float {
		return sprite.width * pixelSize;
	}

	public inline function getHeight():Float {
		return sprite.height * pixelSize;
	}

	public function calculateMesh() {
		var mesh = meshes[0];
		var vertices:Array<Float>;

		if(sprite.frame == null) { // No frame
			var w = sprite.width / 2 * pixelSize;
			var h = sprite.height / 2 * pixelSize;
			mesh.updateBuffer(FoxMeshBufferType.UVS, [
				0, 0,
				1, 0,
				1, 1,
				0, 1
			]);

			vertices = [
				-w,  h, 0,
				 w,  h, 0,
				 w, -h, 0,
				-w, -h, 0
			];
			mesh.updateBuffer(FoxMeshBufferType.VERTICES, vertices);
		}
		else {
			var width = sprite.pixels.width;
			var height = sprite.pixels.height;
			var frame = sprite.frame.frame;
			var offset = sprite.frame.offset;
			var u = frame.x / width;
			var v = frame.y / height;
			var uw = (frame.x + frame.width) / width;
			var vh = (frame.y + frame.height) / height;

			mesh.updateBuffer(FoxMeshBufferType.UVS, [
				u,  v,
				uw, v,
				uw, vh,
				u, vh
			]);
			
			var ps = pixelSize * 0.5;
			u = offset.x * ps;
			v = -offset.y * ps;
			uw = frame.width * ps;
			vh = frame.height * ps;

			vertices = [
				-uw + u,  vh + v, 0,
				 uw + u,  vh + v, 0,
				 uw + u, -vh + v, 0,
				-uw + u, -vh + v, 0
			];

			mesh.updateBuffer(FoxMeshBufferType.VERTICES, vertices);
		}
		if(__recalculateBounds) {
			mesh.calculateBounds(vertices); // For frustum culling
			__recalculateBounds = false;
		}
	}

	public override function update(dt) {
		super.update(dt);
		
		if(sprite.frame == null && __prevFrame != null) {
			// Just a plain ol bitmap
			__prevFrame = null;
			calculateMesh();
		}
		else { // UV Animated sprite
			if(__prevFrame != sprite.frame.name) {
				calculateMesh();
				__prevFrame = sprite.frame.name;
			}
		}
		checkBitmap();
	}

	public function checkBitmap() {
		// Check bitmap changes
		if(sprite.pixels == null) return;
		if(__prevBitmap != sprite.pixels) {
			material.textures.get("bitmap")?.take(sprite.pixels);
			__prevBitmap = sprite.pixels;
			__recalculateBounds = true;
		}
	}

	public override function destroy() {
		__prevBitmap = null;
		super.destroy();
	}

	function get_material():FoxMaterial {
		return meshes[0]?.material;
	}

	function set_material(v:FoxMaterial):FoxMaterial {
		meshes[0].material = v;
		return v;
	}

	function get_texture():FoxTexture {
		return this.material?.textures?.get("bitmap");
	}

	function set_texture(v:FoxTexture):FoxTexture {
		this.material?.textures?.set("bitmap", v);
		return v;
	}

	function get_shader():FoxShader {
		return this.material?.shader;
	}

	function set_shader(v:FoxShader):FoxShader {
		this.material.shader = v;
		return v;
	}
}