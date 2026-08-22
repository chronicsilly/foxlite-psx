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

import flixel.math.FlxRect;
import flixel.FlxSprite;
import foxlite.FoxModel;
import foxlite.material.FoxBlendMode;
import foxlite.material.FoxMaterial;
import foxlite.material.FoxTriangleFace;
import foxlite.math.FoxMathUtil;
import foxlite.mesh.FoxMeshBufferType;
import foxlite.mesh.FoxQuadMesh;
import foxlite.polyfill.TypedArray;
import foxlite.texture.FoxTexture;
import lime.graphics.opengl.GL;
import lime.utils.Float32Array;
import openfl.display.BitmapData;

class FoxFlxSprite extends FoxModel {

	public var sprite:FlxSprite = null;
	public var pixelSize:Float = 0.01; // Size of the pixels in the world
	
	/**
		If enabled, the 3D sprite will adopt the color tint and color offsets

		__Note:__ This alters the material parameters
	**/
	public var useColorTransform:Bool = false;

	var __prevFrame:String = "null";
	var __prevRect:FlxRect;
	var __prevBitmap:BitmapData = null;
	var __recalculateBounds:Bool = true;

	// Shortcuts
	public var material(get, set):FoxMaterial;
	public var texture(get, set):FoxTexture;
	public var shader(get, set):FoxShader;

	// Raw buffers for performance
	public var verticesRaw:Float32Array = TypedArray.Float32Array([0,0,0, 0,0,0, 0,0,0, 0,0,0]);
	public var uvsRaw:Float32Array = TypedArray.Float32Array([0,0, 1,0, 1,1, 0,1]);
	var __defaultUVs:Bool = false;

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

		var mesh = new FoxQuadMesh(target.width * pixelSize, target.height * pixelSize, material_, 2, context.gl.DYNAMIC_DRAW);
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

			// No idea if whis will work in polymod hscript
			if(!__defaultUVs) {
				uvsRaw[0] = 0; uvsRaw[1] = 0;
				uvsRaw[2] = 1; uvsRaw[3] = 0;
				uvsRaw[4] = 1; uvsRaw[5] = 1;
				uvsRaw[6] = 0; uvsRaw[7] = 1;
				mesh.updateBufferRaw(FoxMeshBufferType.UVS, uvsRaw);
				__defaultUVs = true;
			}

			verticesRaw[0] = -w; verticesRaw[1] =  h; //verticesRaw[2] = 0;
			verticesRaw[3] =  w; verticesRaw[4] =  h; //verticesRaw[5] = 0;
			verticesRaw[6] =  w; verticesRaw[7] = -h; //verticesRaw[8] = 0;
			verticesRaw[9] = -w; verticesRaw[10] = -h; //verticesRaw[11] = 0;
			mesh.updateBufferRaw(FoxMeshBufferType.VERTICES, verticesRaw);
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
			__defaultUVs = false;

			uvsRaw[0] = u;  uvsRaw[1] = v;
			uvsRaw[2] = uw; uvsRaw[3] = v;
			uvsRaw[4] = uw; uvsRaw[5] = vh;
			uvsRaw[6] = u;  uvsRaw[7] = vh;
			mesh.updateBufferRaw(FoxMeshBufferType.UVS, uvsRaw);
			
			var ps = pixelSize * 0.5;
			u = offset.x * ps;
			v = -offset.y * ps;
			uw = frame.width * ps;
			vh = frame.height * ps;

			verticesRaw[0] = -uw + u; verticesRaw[1] =  vh + v; //verticesRaw[2] = 0;
			verticesRaw[3] =  uw + u; verticesRaw[4] =  vh + v; //verticesRaw[5] = 0;
			verticesRaw[6] =  uw + u; verticesRaw[7] = -vh + v; //verticesRaw[8] = 0;
			verticesRaw[9] = -uw + u; verticesRaw[10] = -vh + v; //verticesRaw[11] = 0;
			mesh.updateBufferRaw(FoxMeshBufferType.VERTICES, verticesRaw);
		}
		if(__recalculateBounds) {
			mesh.calculateBounds(verticesRaw); // For frustum culling
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
			var r = sprite.frame.frame;
			if(__prevFrame != sprite.frame.name || (r != null && __prevRect != null && !r.equals(__prevRect))) {
				calculateMesh();
				__prevFrame = sprite.frame.name;
				__prevRect = r;
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

		if(useColorTransform) {
			var tmp = FoxMathUtil.__tempVector;
			var c = sprite.colorTransform;
			tmp.setTo(c.redOffset, c.greenOffset, c.blueOffset);
			material.setColor(sprite.color);
			material.setEmissiveColorFromVector(tmp);
		}
	}

	public override function destroy() {
		__prevBitmap = null;
		verticesRaw = null;
		uvsRaw = null;
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