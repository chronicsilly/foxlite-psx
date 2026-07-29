package foxlite.culling;

import foxlite.FoxCamera;
import foxlite.culling.BoundingBox;
import foxlite.math.FoxMathUtil;
import foxlite.renderer.FoxRenderer;
import openfl.geom.Vector3D;

class FrustumCone {
	
	public var origin:Vector3D = new Vector3D();
	public var direction:Vector3D = new Vector3D(0, 1, 0);
	public var bottomRadius:Float = 0;
	public var height:Float = 0;

	public var slope:Float = 0;
	public var angle:Float = 0;
	public var reciprocSine:Float = 0;

	var v:Vector3D = new Vector3D(); // For calculations

	public function new():Void {
		FoxRenderer.allocationsThisFrame += 4;
	}

	public function setFromCamera(camera:FoxCamera):FrustumCone {		
		origin.copyFrom(camera.position);

		FoxMathUtil.directionOfToOutput(camera.viewMatrix, direction);
		direction.z *= -1; // To camera forward

		var fovY = camera.fov * FoxMathUtil.degToRad;
		var slope = Math.tan(fovY * 0.5) * camera.__aspect;
		bottomRadius = camera.far * slope;
		height = camera.far;

		angle = Math.atan(slope);
		reciprocSine = Math.sin(Math.PI*.5 - angle);

		return this;
	}

	// Ultrafast 3D Cone-sphere intersection check
	// It's not accurate on the edge base, but it's good enough for our case
	public function fastIntersects(box:BoundingBox, globalPosition:Vector3D):Bool {
		v.copyFrom(globalPosition);
		v.incrementBy(box.center);
		v.decrementBy(origin);
		var dot = v.dotProduct(direction);
		
		// Check if sphere is beyond far plane
		if(dot - box.radius > height) return false;

		dot = Math.min(dot, height);

		// Check if sphere intersects cone edges and is inside cone
		return (Math.sqrt(v.lengthSquared - dot*dot) - dot*slope) * reciprocSine < box.radius;
	}

	/*
	Fast cone check explanation:
	
	// Cone side intersection

	// Do some trigonometry to restore the horizontal:
	//      |\
	//  dot |  \ dist
	//      |____\
	//        x
	// This is necessary because our cone rotates in 3 dimensions
		
	var x = Math.sqrt(v.lengthSquared - dot*dot);

	// Closest horizontal point to the sphere, sliding on the cone side
	//     /
	//    /
	//   X-----(Sphere) 
	//  /
	var edgePoint = dot * slope;

	// Distance from sphere center to cone edge
	// Derived from the formula C = A / sin(a)
	var distance = (x - edgePoint) * reciprocSine;

	return distance <= box.radius;
	*/
}