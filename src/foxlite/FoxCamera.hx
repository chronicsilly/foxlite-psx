package foxlite;

import foxlite.FoxLayer;
import foxlite.animation.FoxLerp;
import foxlite.culling.FrustumCone;
import foxlite.lights.FoxLightData;
import foxlite.math.FoxMathUtil;
import foxlite.renderer.FoxRenderPass;
import foxlite.renderer.FoxRenderer;
import foxlite.system.FoxDrawTree;
import foxlite.texture.FoxFramebuffer;
import lime.math.Vector2;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class FoxCamera extends FoxObject {

	//public var position(default, set):Vector3D = new Vector3D();
	//public var rotation(default, set):Vector3D = new Vector3D();
	public var fov(default, set):Float = 90;
	public var near(default, set):Float = 0.05;
	public var far(default, set):Float = 1000.0;
	public var aspect(default, set):Float = 1;
	public var orthogonal(default, set):Bool = false;
	public var bgColor = 0x00000000;
	public var __aspect:Float = 1; // Target aspect
	//public var __destroyed:Bool = false;
	public var __updateProjection:Bool = true;

	/**
		Model visibility layers	
	**/
	public var modelLayers:FoxLayer = 0x1;

	//public var active:Bool = true;
	//public var visible:Bool = true;
	
	/**
		 Any custom pass you want for this camera, add them here.

		 By default, there's one pass that will render everything in group 0 on the "default" render target.

		 __Warning!__ If you create two cameras, make sure to change the output or else it'll overwrite the previous camera render!
	**/
	public var passes:Array<FoxRenderPass> = [new FoxRenderPass([0], "default")];
	
	// Camera transforms
	public var viewMatrix:Matrix3D = new Matrix3D();
	public var __invViewMatrix:Matrix3D = new Matrix3D();
	public var projectionMatrix:Matrix3D = new Matrix3D();
	public var __invProjectionMatrix:Matrix3D = new Matrix3D(); // For raytracing effects

	// Temporary matrix for space coordinate transforms
	public final __tempMatrix = new Matrix3D();

	// Frustum culling

	public var doFrustumCulling:Bool = true;
	public var frustumCone:FrustumCone = new FrustumCone();

	/**
		The light data associated with this camera.

		This handles all dynamic lighting that's visible by this camera,
		including ambient light.

		Normally, this is handled by the camera itself and the lights on the scene,
		so you don't need to touch this unless you know what you're doing!
	**/
	public var lightData:FoxLightData = new FoxLightData();

	public function new() {
		super();
		name = "FoxCamera";
		passes[0].useCameraColor = true;
	}

	public override function draw(camera:FoxCamera) {}

	public override function update(dt:Float) {
		super.update(dt);
		if(scene == null) return;
		// Create from transform so other influences can affect the camera
		FoxMathUtil.viewMatrixFromTransform(viewMatrix, transform);

		if(__updateProjection) {
			__aspect = scene != null ? scene.__width / scene.__height : 1;
			__aspect *= aspect;
			
			if(!orthogonal) {
				FoxMathUtil.perspectiveMatrix(projectionMatrix, fov, __aspect, near, far);
			}
			else {
				FoxMathUtil.orthogonalMatrix(projectionMatrix, fov, __aspect, near, far);
			}
			
			__updateProjection = false;
		}

		// Always update view matrices, this takes a bit more hscript operations per frame
		// But fixes lights not updating accordingly

		// Do operations in-place
		__invProjectionMatrix.copyRawDataFrom(projectionMatrix.rawData);//.copyFrom(projectionMatrix); 
		__invProjectionMatrix.invert();

		__invViewMatrix.copyRawDataFrom(viewMatrix.rawData);
		__invViewMatrix.invert();
		__invViewMatrix.transpose();

		frustumCone.setFromCamera(this);

	}

	public function render(drawGroups:Array<FoxDrawTree>) {
		if(scene == null) return;
		
		// Process passes
		for(pass in passes) {
			if(!pass.enabled) continue;

			// Get render target
			var framebuffer:FoxFramebuffer = scene.renderTargets.get(pass.target);
			if(framebuffer == null) {
				trace('[FoxLite > FoxCamera]: WARNING: Scene does not have target "${pass.target}"');
				continue;
			}
			if(pass.groups.length == 0) {
				//trace('[FoxLite > FoxCamera]: WARNING: Pass "${pass.name}" does not have groups to draw! Consider disabling this pass!');
				continue;
			}

			// Do shadow pass for all shadow lights
			pass.passShadowLights(lightData, this, drawGroups);
			
			// Do normal render pass
			pass.pass(this, drawGroups, framebuffer);
		}
	}

	public override function destroy() {
		transform = null;
		projectionMatrix = null;
		lightData.destroy();
		super.destroy();
	}

	/**
		Projects a world-space 3D point to Normalized Device Coordinate (NDC, aka Screen-Space Position).
		
		__Note:__ the center is at (0,0) instead of (0.5, 0.5). If you need flixel coordinates, use `toFlixelScreenPoint()`
		
		__Note 2:__ The values are unclamped! Make sure to clamp them if needed.
	**/
	public function getScreenPoint(point:Vector3D):Vector3D {
		__tempMatrix.copyRawDataFrom(projectionMatrix.rawData);
		__tempMatrix.prepend(viewMatrix);
		var v = __tempMatrix.transformVector(point); // projectionMatrix * viewMatrix * point
		v.project(); // proj.xyz /= proj.w -> NDC
		FoxRenderer.allocationsThisFrame += 1;
		return v;
	}

	public function toFlixelScreenPoint(point:Vector3D, screenWidth:Float, screenHeight:Float, ?output:Vector2):Vector2 {
		final HW = screenWidth*.5;
		final HH = screenHeight*.5;

		if(output == null) {
			output = new Vector2();
			FoxRenderer.allocationsThisFrame += 1;
		}
		output.setTo(
			HW + point.x * HW,
			screenHeight - (HH + point.y * HH)
		);
		return output;
	}

	/**
		Re-projects a screen-space point to world space, useful for point and click in 3D with raycast.
	**/
	public function getWorldSpace(point:Vector3D):Vector3D {
		__tempMatrix.copyRawDataFrom(__invProjectionMatrix.rawData);
		__tempMatrix.append(__invViewMatrix);
		var v = __tempMatrix.transformVector(point);
		FoxRenderer.allocationsThisFrame += 1;
		return v;
	}

	public function loadPassesFromAsset(name:String):Void {
		passes = FoxRenderPass.fromAsset(name) ?? [];
	}

	private function set_fov(v:Float) {
		this.fov = v;
		__updateProjection = true;
		return v;
	}

	private function set_aspect(v:Float) {
		this.aspect = v;
		__updateProjection = true;
		return v;
	}

	private function set_far(v:Float) {
		this.far = v;
		__updateProjection = true;
		return v;
	}

	private function set_near(v:Float) {
		this.near = v;
		__updateProjection = true;
		return v;
	}

	private function set_orthogonal(v:Bool) {
		this.orthogonal = v;
		__updateProjection = true;
		return v;
	}
}