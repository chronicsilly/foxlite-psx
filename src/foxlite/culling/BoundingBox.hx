package foxlite.culling;

import foxlite.renderer.FoxRenderer;
import openfl.geom.Vector3D;

class BoundingBox {
	
	public var center:Vector3D = new Vector3D();
	public var extents:Vector3D = new Vector3D();
	public var radius:Float = 0; // Sphere enclosing the box

	public function new():Void {
		FoxRenderer.allocationsThisFrame += 3;
	}

	public function fromExtents(min:Vector3D, max:Vector3D):BoundingBox {
		// (min + max) / 2
		center.copyFrom(min);
		center.incrementBy(max);
		center.scaleBy(0.5);

		// (max - min) / 2
		extents.copyFrom(max);
		extents.decrementBy(min);
		extents.scaleBy(0.5);

		radius = Math.max(Math.max(extents.x, extents.y), extents.z);

		return this;
	}

	public function expand(box:BoundingBox) {
		center.incrementBy(box.center);
		center.scaleBy(0.5);

		extents.incrementBy(box.extents);
		extents.scaleBy(0.5);
	}

	public function zero() {
		center.setTo(0, 0, 0);
		extents.setTo(0, 0, 0);
	}
}