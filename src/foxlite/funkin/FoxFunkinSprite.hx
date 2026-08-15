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

		mesh.updateBuffer(FoxMeshBufferType.UVS, [
			0, 0,
			1, 0,
			1, 1,
			0, 1
		]);
		
		var fX = flipX ? -1 : 1;
		var fY = flipY ? -1 : 1;
		var f0X = (-w+ox) * fX;
		var f1X = ( w+ox) * fX;
		var f0Y = ( h+oy) * fY;
		var f1Y = (-h+oy) * fY;

		var vertices:Array<Float> = [
			f0X, f0Y, 0,
			f1X, f0Y, 0,
			f1X, f1Y, 0,
			f0X, f1Y, 0
		];
		mesh.updateBuffer(FoxMeshBufferType.VERTICES, vertices);

		if(__recalculateBounds) {
			mesh.calculateBounds(vertices); // For frustum culling
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