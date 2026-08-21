package foxlite.funkin;

import flixel.math.FlxMatrix;
import foxlite.flixel.FoxFlxSprite;
import foxlite.material.FoxMaterial;
import foxlite.material.FoxTriangleFace;
import foxlite.mesh.FoxMeshBufferType;
#if (foxlite_polymod || polymod)
import funkin.graphics.FunkinSprite;
#else
typedef FunkinSprite = Dynamic; // Keep haxe happy
#end

/**
	Use your funkin sprites in the 3D renderer!

	Keep in mind, this only works for `FlxAnimate` sprites
	__that have a filter attached to them__ because it makes
	use of their __Render Texture__ instead.

	If the sprite doesn't have a filter attached, the behavior is undefined.
	
	__Note:__ You can create a dummy filter for your sprite like this:
	```haxe
	import openfl.filters.BitmapFilter;

	myAnimateSprite.useRenderTexture = true;
	myAnimateSprite.filters = [new BitmapFilter()];
	```
*/

class FoxFunkinSprite extends FoxFlxSprite {

	public var flipX:Bool = false;
	public var flipY:Bool = false;

	/**
		If true, the mesh will be offset by the sprite's `_matrix`.
		
		Disable it if you want to control it manually
	**/
	public var useMatrixOffsets:Bool = true;

	var __prevGraphicWidth:Int = 0;
	var __prevGraphicHeight:Int = 0;
	var _matrix:FlxMatrix;

	public function new(target:FunkinSprite, ?shader_:FoxShader, ?spritePixelSize:Float) {
		var material_ = FoxMaterial.create(shader_ ?? FoxShader.fromAsset(FoxShader.BASIC));
		material_.shadowCulling = FoxTriangleFace.NONE; // Render shadow for front and back faces
		super(target, material_, spritePixelSize);
	}

	public override function calculateMesh() {
		if(!checkAnimate() || _matrix == null) {
			super.calculateMesh(); // If this is not an animate sprite we do the normal uv animating stuff
			return;
		}

		var mesh = meshes[0];
		var width = __prevGraphicWidth;
		var height = __prevGraphicHeight;
		var w = width / 2 * pixelSize;
		var h = height / 2 * pixelSize;
		var ox = useMatrixOffsets ? w - _matrix.tx * pixelSize : 0;
		var oy = useMatrixOffsets ? -(h - _matrix.ty * pixelSize) : 0;

		if(!__defaultUVs) {
			uvsRaw[0] = 0; uvsRaw[1] = 0;
			uvsRaw[2] = 1; uvsRaw[3] = 0;
			uvsRaw[4] = 1; uvsRaw[5] = 1;
			uvsRaw[6] = 0; uvsRaw[7] = 1;
			mesh.updateBufferRaw(FoxMeshBufferType.UVS, uvsRaw);
			__defaultUVs = true;
		}
		
		var fX = flipX ? -1 : 1;
		var fY = flipY ? -1 : 1;
		var f0X = (-w+ox) * fX;
		var f1X = ( w+ox) * fX;
		var f0Y = ( h+oy) * fY;
		var f1Y = (-h+oy) * fY;

		verticesRaw[0] = f0X; verticesRaw[1] = f0Y; verticesRaw[2] = 0;
		verticesRaw[3] = f1X; verticesRaw[4] = f0Y; verticesRaw[5] = 0;
		verticesRaw[6] = f1X; verticesRaw[7] = f1Y; verticesRaw[8] = 0;
		verticesRaw[9] = f0X; verticesRaw[10] = f1Y; verticesRaw[11] = 0;
		mesh.updateBufferRaw(FoxMeshBufferType.VERTICES, verticesRaw);

		if(__recalculateBounds) {
			mesh.calculateBounds(verticesRaw); // For frustum culling
			__recalculateBounds = false;
		}
	}

	public override function checkBitmap() {
		if(!checkAnimate()) { // If this is not an animate sprite we do the normal bitmap checks
			super.checkBitmap();
			return;
		}
		@:privateAccess var renderTexture = (cast sprite:FunkinSprite)._renderTexture;
		var graphic = renderTexture?.graphic;
		if(graphic == null) return;
		material.textures.get("bitmap")?.take(graphic.bitmap);
		if(__prevGraphicWidth != graphic.width || __prevGraphicHeight != graphic.height) {
			__prevGraphicWidth = graphic.width;
			__prevGraphicHeight = graphic.height;
			@:privateAccess _matrix = renderTexture._matrix;
			calculateMesh();
		}
	}

	public function checkAnimate():Bool {
		return (cast sprite:FunkinSprite)?.isAnimate;
	}

	public override function destroy() {
		_matrix = null;
		super.destroy();
	}
}