package foxlite.lights;

import flixel.util.FlxColor;
import foxlite.lights.FoxLightType;
import foxlite.math.FoxMathUtil;
import foxlite.renderer.FoxRenderer;
import openfl.geom.Vector3D;

class FoxAreaLight extends FoxPointLight {

	/**
		The internal data for the light, mostly shape parameters set via this class functions.
	**/
	public var sdfData:Vector3D = new Vector3D();

	public var shape(get, never):FoxAreaLightShape;
	var __sdfRange:Float = 0;

	override function set_range(v:Float):Float {
		if(v == this.range) return v;
		this.range = v;
		FoxMathUtil.perspectiveMatrix(this.projectionMatrix, 90, 1, 0.05, this.getSdfRange());
		return v;
	}

	function get_shape():FoxAreaLightShape {
		return Std.int(Math.max(this.sdfData.w, 0));
	}

	public function new(x:Float=0, y:Float=0, z:Float=0, color:FlxColor=0xFFFFFFFF, energy:Float=1, shape:FoxAreaLightShape= #if !foxlite_polymod FoxAreaLightShape.BOX #else 1 #end, range:Float=5, attenuation:Float=1, shadow:Bool=false) {
		super(x, y, z, color, energy, range, attenuation, shadow);
		name = "FoxAreaLight";
		FoxRenderer.allocationsThisFrame += 2;
	}

	public override function getType():FoxLightType {
		return FoxLightType.AREA;
	}

	public override function setToLightData(camera:FoxCamera) {
		var lightData = camera.lightData;
		var distance = Vector3D.distance(globalPosition, camera.globalPosition);
		lightData.orderedAreaLights.set(distance, this);
		FoxRenderer.allocationsThisFrame += 1; // Account for tree node
	}

	// SDF Shapes

	public function setBox(sizeX:Float, sizeY:Float, sizeZ:Float) {
		sdfData.setTo(sizeX, sizeY, sizeZ);
		sdfData.w = FoxAreaLightShape.BOX;
		__sdfRange = Math.max(sizeX, Math.max(sizeY, sizeZ));
		FoxMathUtil.perspectiveMatrixClipFast(projectionMatrix, 0.05, getSdfRange());
	}

	public function setTorus(radius:Float, thickness:Float) {
		sdfData.setTo(radius, thickness, 0);
		sdfData.w = FoxAreaLightShape.TORUS;
		__sdfRange = radius+thickness;
		FoxMathUtil.perspectiveMatrixClipFast(projectionMatrix, 0.05, getSdfRange());
	}

	public function setCappedTorus(radius:Float, thickness:Float, angle:Float) {
		sdfData.setTo(radius, thickness, angle);
		sdfData.w = FoxAreaLightShape.CAPPED_TORUS;
		__sdfRange = radius+thickness;
		FoxMathUtil.perspectiveMatrixClipFast(projectionMatrix, 0.05, getSdfRange());
	}

	public function setLink(radius:Float, thickness:Float, length:Float) {
		sdfData.setTo(radius, thickness, length);
		sdfData.w = FoxAreaLightShape.LINK;
		__sdfRange = Math.max(radius+thickness, length);
		FoxMathUtil.perspectiveMatrixClipFast(projectionMatrix, 0.05, getSdfRange());
	}

	public function setHexagonalPrism(thickness:Float, length:Float) {
		sdfData.setTo(thickness, length, 0);
		sdfData.w = FoxAreaLightShape.HEXAGONAL_PRISM;
		__sdfRange = Math.max(thickness, length);
		FoxMathUtil.perspectiveMatrixClipFast(projectionMatrix, 0.05, getSdfRange());
	}

	public function setSphere(radius:Float) {
		sdfData.x = radius;
		sdfData.w = FoxAreaLightShape.SPHERE;
		__sdfRange = radius;
		FoxMathUtil.perspectiveMatrixClipFast(projectionMatrix, 0.05, getSdfRange());
	}

	public function getSdfRange():Float {
		return range + __sdfRange * Math.PI;
	}
}