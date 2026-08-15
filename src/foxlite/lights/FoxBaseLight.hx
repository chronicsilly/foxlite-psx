package foxlite.lights;

import foxlite.FoxObject;
import foxlite.math.FoxMathUtil;
import foxlite.renderer.FoxRenderer;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class FoxBaseLight extends FoxObject {

	public var color:Vector3D = new Vector3D(1, 1, 1);
	public var energy:Float = 1;
	public var direction:Vector3D = new Vector3D(0, 0, -1); // Cache light direction

	/**
		Extra data used for SDFs, but can be used to pass extra values to the shader
	**/
	public var sdfData:Vector3D = new Vector3D();
	
	// For shadow calculations

	/**
		If true, this light will cast shadows

		__Note:__ If this is set to true, a new texture will be created for this light,
		this is its shadow map, and it's currently a fixed resolution of 1024x1024
	**/
	public var shadow:Bool = false;

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

	public function new() {
		super();
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