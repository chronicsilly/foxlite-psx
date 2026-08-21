package foxlite.animation.data;

import lime.math.Vector2;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;
import foxlite.animation.FoxTrackType;

class FoxTrackData {
	public var frameIndex:Int = 0;
	public var prevFrameIndex:Int = -1;
	public var value:Any;
	public var type #if !foxlite_polymod (default, null) #end :FoxTrackType;

	public function new(_type:FoxTrackType) {
		value = switch(_type) {
			case FoxTrackType.ANGLE,
				 FoxTrackType.DEGREES,
				 FoxTrackType.FLOAT: 		0.0;
			case FoxTrackType.BOOL: 		false;
			case FoxTrackType.INT, 			
				 FoxTrackType.COLOR:		0;
			case FoxTrackType.VECTOR3D, 
				 FoxTrackType.VECTOR4, 
				 FoxTrackType.QUATERNION, 
				 FoxTrackType.EULER_ANGLES: new Vector3D();
			case FoxTrackType.MATRIX4: 		new Matrix3D();
			case FoxTrackType.VECTOR2:		new Vector2();
			default: null;
		}
		type = _type;
	}
}