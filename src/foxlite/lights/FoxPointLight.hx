package foxlite.lights;

import flixel.util.FlxColor;
import foxlite.FoxCamera;
import foxlite.lights.FoxBaseLight;
import foxlite.lights.FoxLightType;
import foxlite.math.FoxMathUtil;
import foxlite.renderer.FoxRenderer;
import openfl.geom.Vector3D;

class FoxPointLight extends FoxBaseLight {

	public var attenuation:Float;
	public var range(default, set):Float;

	function set_range(v:Float):Float {
		if(v == this.range) return v;
		this.range = v;
		FoxMathUtil.perspectiveMatrix(this.projectionMatrix, 90, 1, 0.05, v);
		return v;
	}

	public function new(x:Float=0, y:Float=0, z:Float=0, color:FlxColor=0xFFFFFFFF, energy:Float=1, range:Float=5, attenuation:Float=1, shadow:Bool=false) {
		super(x, y, z, color, energy, shadow);
		this.range = range;
		this.attenuation = attenuation;
		name = "FoxPointLight";
		range = 5;
	}

	public override function getType():FoxLightType {
		return FoxLightType.POINT;
	}

	public override function update(dt:Float) {
		super.update(dt);
		// Calculate view-projection transform, this is the POV of the light
		if(shadow) {
			//FoxMathUtil.viewMatrixFromTransform(viewMatrix, transform);
			FoxMathUtil.fastIdentity(viewMatrix);
			var p = transform.position;
			// Move light, just don't rotate or scale
			viewMatrix.appendTranslation(-p.x, -p.y, -p.z);
			//viewMatrix.rawData.set(15, 1);
			viewProjection.copyRawDataFrom(viewMatrix.rawData);
			// We don't need to append projection if we're using dual paraboloid
			//viewProjection.append(projectionMatrix);
		}
	}

	public override function draw(camera:FoxCamera) {
		super.draw(camera);
		setToLightData(camera);
	}

	public override function setToLightData(camera:FoxCamera) {
		var lightData = camera.lightData;
		var distance = Vector3D.distance(globalPosition, camera.globalPosition);
		lightData.orderedPointLights.set(distance, this);
		FoxRenderer.allocationsThisFrame += 1; // Account for tree node
	}
}