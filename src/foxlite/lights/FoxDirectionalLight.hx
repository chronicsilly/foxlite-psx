package foxlite.lights;

import foxlite.FoxCamera;
import foxlite.lights.FoxBaseLight;
import foxlite.lights.FoxLightType;
import foxlite.math.FoxMathUtil;
import foxlite.renderer.FoxRenderer;

class FoxDirectionalLight extends FoxBaseLight {

	/**
		The distance in world units that the shadow will cover.
	**/
	public var shadowDistance(default, set):Float = 0;

	public function new() {
		super();
		name = "FoxDirectionalLight";
		shadowDistance = 100;
	}

	public override function getType():FoxLightType {
		return FoxLightType.DIRECTIONAL;
	}

	public override function getShadowMapType():FoxLightType {
		return FoxLightType.DIRECTIONAL;
	}

	function set_shadowDistance(v:Float):Float {
		if(v == this.shadowDistance) return v;
		FoxMathUtil.orthogonalMatrix(this.projectionMatrix, v, 1, 0.05, 512);
		return v;
	}

	public override function draw(camera:FoxCamera) {
		super.draw(camera);
		setToLightData(camera);
	}

	public override function setToLightData(camera:FoxCamera) {
		// Calculate view-projection transform, this is the POV of the light
		if(shadow) {
			FoxMathUtil.fastIdentity(viewMatrix);
			viewMatrix.pointAt(FoxMathUtil.ZERO, direction, FoxMathUtil.UP);
			viewMatrix.appendScale(-1, 1, -1);
			viewMatrix.appendTranslation(0, 0, -256);
			FoxRenderer.allocationsThisFrame += 2; // Scale and pointAt
			var p = camera.globalPosition;
			// Move in steps to reduce aliasing warping
			viewMatrix.prependTranslation(-Math.ffloor(p.x), Math.ffloor(p.y), -Math.ffloor(p.z));
			//viewMatrix.prependTranslation(-p.x, p.y, -p.z);

			// Projection * View
			viewProjection.copyRawDataFrom(viewMatrix.rawData);
			viewProjection.append(projectionMatrix);
		}
		
		camera.lightData.directionalLights.push(this);
	}
}