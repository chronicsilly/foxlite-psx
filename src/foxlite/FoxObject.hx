package foxlite;

import foxlite.FoxBasic;
import foxlite.math.FoxMathUtil;
import foxlite.renderer.FoxRenderer;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class FoxObject extends FoxBasic {
	
	/**
		If set, will adapt parent transform. Make sure the parent has a higher priority so it updates in order
	**/
	public var parent:FoxObject; 
	public var position:Vector3D = new Vector3D();
	public var rotation:Vector3D = new Vector3D();
	public var scale:Vector3D = new Vector3D(1, 1, 1);

	// Convenience variables, Flixel-like
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;

	// Note: these convert degrees to radians and viceversa to be used in rotation, so they could be a bit slower
	// They are proxies, meaning you can't do operations such as +=, -=, *=, etc
	// Do this instead: `angleX = angleX + 10`
	public var angleX(get, set):Float;
	public var angleY(get, set):Float;
	public var angleZ(get, set):Float;

	// Internal transforms
	public var transform:Matrix3D = new Matrix3D();
	// TODO? add a setter and update position/rotation/scale in global space
	public var globalPosition(get, null):Vector3D = new Vector3D(); 
	public var globalRotation(get, null):Vector3D = new Vector3D(); 
	public var globalScale(get, null):Vector3D = new Vector3D(); 

	public function new() {
		super();
		name = "FoxObject";
		FoxRenderer.allocationsThisFrame += 8;
	}

	public override function update(dt) {
		super.update(dt);
		// Calculations must happen for parent every time
		FoxMathUtil.transformMatrix(transform, position, rotation, scale);
		if(parent != null) {
			if(!parent.__destroyed) transform.append(parent.transform);
			else parent = null;
		}
	}

	public override function destroy() {
		parent = null;
		super.destroy();
	}

	private override function set_visible(v:Bool):Bool {
		if(v == this.visible) return v;
		this.visible = v;
		FoxRenderer.mustRebuildDrawGroups = true;
		return v;
	}

	private function get_globalPosition() {
		var a = transform.rawData.__array;
		this.globalPosition.setTo(a[12], a[13], a[14]);
		return this.globalPosition;
	}

	private function get_globalRotation() {
		FoxMathUtil.eulerFromMatrix(transform, this.globalRotation, this.globalScale);
		return this.globalRotation;
	}

	private function get_globalScale() {
		FoxMathUtil.scaleFromMatrix(transform, this.globalScale);
		return this.globalScale;
	}

	private function get_x():Float {
		return position.x;
	}

	private function get_y():Float {
		return position.y;
	}

	private function get_z():Float {
		return position.z;
	}

	private inline function set_x(v:Float):Float {
		return position.x = v;
	}

	private inline function set_y(v:Float):Float {
		return position.y = v;
	}

	private inline function set_z(v:Float):Float {
		return position.z = v;
	}

	private function set_angleX(v:Float):Float {
		rotation.x = FoxMathUtil.degToRad * v;
		return v;
	}

	private function set_angleY(v:Float):Float {
		rotation.y = FoxMathUtil.degToRad * v;
		return v;
	}

	private function set_angleZ(v:Float):Float {
		rotation.z = FoxMathUtil.degToRad * v;
		return v;
	}

	private function get_angleX():Float {
		return rotation.x * FoxMathUtil.radToDeg;
	}

	private function get_angleY():Float {
		return rotation.y * FoxMathUtil.radToDeg;
	}

	private function get_angleZ():Float {
		return rotation.z * FoxMathUtil.radToDeg;
	}
}