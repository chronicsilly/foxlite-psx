package foxlite.lights;

import foxlite.color.FoxColorUtil;
import flixel.util.FlxColor;
import foxlite.FoxObject;
import foxlite.math.FoxMathUtil;
import foxlite.renderer.FoxRenderer;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class FoxBaseLight extends FoxObject {

	public var color:Vector3D = new Vector3D(1, 1, 1);
	
	/**
		The light color as a `FlxCOlor`
	**/
	public var colorHex(get, set):FlxColor;

	/**
		Applies a small depth offset for the shadow casted by this light to prevent Shadow Acne.

		Too high values will cause the shadow to look disconnected from the mesh, tweak this value accordingly
	**/
	public var shadowBias:Float = 0.00025;

	/**
		Applies an offset slided by the normal for the shadow casted by this light.

		Helps to reduce Shadow Acne.

		__Note:__ This currently isn't implemented yet
	**/
	public var shadowNormalBias:Float = 1.0;

	/**
		Controls the blurring of the shadow, gives them a softer or harder look

		Too high values will cause noticeable blurring artifacts

		__Note:__ This value corresponds to the pixel area of the shadowmap
	**/
	public var shadowBlur:Float = 1.5;

	function get_colorHex():FlxColor {
		return FoxColorUtil.toFlxColor(this.color);
	}

	function set_colorHex(v:FlxColor):FlxColor {
		FoxColorUtil.fromFlxColor(v, this.color);
		return v;
	}

	public var energy:Float;
	public var direction:Vector3D = new Vector3D(0, 0, -1); // Cache light direction
	
	// For shadow calculations

	/**
		If true, this light will cast shadows

		__Note:__ If this is set to true, a new texture will be created for this light,
		this is its shadow map, and it's currently a fixed resolution of 1024x1024
	**/
	public var shadow:Bool;

	/**
		Temporary value to store the region of the shadowmap for this light.

		This is handled automatically by `FoxLightData`

		__Note:__ This is a `Vector3D` instead of a `Rectangle` for fast scaling operations in HScript
	**/
	public var shadowAtlasRect:Vector3D = new Vector3D(0, 0, 1, 1);
	
	/**
		Same as `shadowAtlasRect` but as UV coordinates for the shader.
	**/
	public var shadowAtlasUV:Vector3D = new Vector3D(0, 0, 1, 1);

	/**
		The projection matrix for this light

		A Directional Light has an Orthogonal projection, this means
		the rays are always parallel to the surface, this is used to simulate the sun shadows.

		A Point light has a Perspective projection, this means
		the rays have a depth to them the farther away they are from the light source.
		This is used to simulate point light source shadows.
	**/
	public var projectionMatrix:Matrix3D = new Matrix3D();

	/**
		The view matrix for this light

		This is its transform for its POV
	**/
	public var viewMatrix:Matrix3D = new Matrix3D();

	/**
		The Transform of this light with its Projection

		This is necessary for shadow calculations in the fragment shader, as
		it's the POV of the light
	**/
	public var viewProjection:Matrix3D = new Matrix3D();

	public function new(x:Float=0, y:Float=0, z:Float=0, color:FlxColor=0xFFFFFFFF, energy:Float=1, shadow:Bool=false) {
		super(x, y, z);
		this.energy = energy;
		this.shadow = shadow;
		FoxColorUtil.fromFlxColor(color, this.color);
		name = "FoxBaseLight";
		FoxRenderer.allocationsThisFrame += 9;
	}

	public function getType():FoxLightType {
		return -1;
	}

	public override function update(dt) {
		super.update(dt);
		FoxMathUtil.directionOfToOutput(transform, direction);
		direction.negate();
	}

	public function setToLightData(camera:FoxCamera) {}

	public override function destroy() {
		projectionMatrix = null;
		viewProjection = null;
		color = null;
		direction = null;
		super.destroy();
	}
}