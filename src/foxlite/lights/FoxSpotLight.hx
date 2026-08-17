package foxlite.lights;

import foxlite.FoxCamera;
import foxlite.lights.FoxBaseLight;
import foxlite.lights.FoxLightType;
import foxlite.math.FoxMathUtil;
import foxlite.renderer.FoxRenderer;
import openfl.geom.Vector3D;

class FoxSpotLight extends FoxBaseLight {

	public var angle(default, set):Float;
	public var attenuation:Float = 1;
	public var range(default, set):Float;

	/**
		The blur of the spot light at the edges. 0 means hard-cut light.
	**/
	public var blur:Float = 1;

	public function new() {
		super();
		name = "FoxSpotLight";

		angle = 45;
		range = 5;
	}

	public override function getType():FoxLightType {
		return FoxLightType.SPOT;
	}

	function set_angle(v:Float):Float {
		if(v == this.angle) return v;
		this.angle = v;
		FoxMathUtil.perspectiveMatrix(this.projectionMatrix, Math.min(v*2.3, 175), 1, 0.05, this.range);
		return v;
	}

	function set_range(v:Float):Float {
		if(v == this.range) return v;
		this.range = v;
		FoxMathUtil.perspectiveMatrix(this.projectionMatrix, Math.min(this.angle*2.3, 175), 1, 0.05, v);
		return v;
	}

	public override function update(dt:Float) {
		super.update(dt);
		// Calculate view-projection transform, this is the POV of the light
		if(shadow) {
			FoxMathUtil.viewMatrixFromTransform(viewMatrix, transform);
			// Projection * View
			viewProjection.copyRawDataFrom(viewMatrix.rawData);
			viewProjection.append(projectionMatrix);
		}
	}

	public override function draw(camera:FoxCamera) {
		super.draw(camera);
		setToLightData(camera);
	}

	public override function setToLightData(camera:FoxCamera) {
		var lightData = camera.lightData;
		var distance = Vector3D.distance(globalPosition, camera.globalPosition);
		lightData.orderedSpotLights.set(distance, this);
		FoxRenderer.allocationsThisFrame += 1; // Account for tree node
	}
}