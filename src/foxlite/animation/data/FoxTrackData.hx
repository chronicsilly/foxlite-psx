package foxlite.animation.data;

import foxlite.animation.FoxTrackType;
import foxlite.polyfill.VectorFactory;
import lime.math.Vector2;
import openfl.geom.Matrix3D;
import openfl.geom.Vector3D;

class FoxTrackData {
	public var frameIndex:Int = 0;
	public var prevFrameIndex:Int = -1;
	public var value:Any;
	public var type #if !foxlite_polymod (default, null) #end :FoxTrackType;

	public function new(_type:FoxTrackType) {
		value = FoxTrackData.getValueForType(_type);
		type = _type;
	}

	/**
		Returns an object that will

		@param def (Optional) Provides custom default values. For non-atomic types, must supply an array.
	**/
	public static function getValueForType(type:FoxTrackType, ?def:Dynamic):Any {
		return switch(type) {
			case FoxTrackType.ANGLE,
				 FoxTrackType.DEGREES,
				 FoxTrackType.FLOAT: 		def ?? 0.0;
			case FoxTrackType.BOOL: 		def ?? false;
			case FoxTrackType.INT, 			
				 FoxTrackType.COLOR:		def ?? 0;
			case FoxTrackType.VECTOR3D, 
				 FoxTrackType.VECTOR4, 
				 FoxTrackType.QUATERNION, 
				 FoxTrackType.EULER_ANGLES: def == null ? new Vector3D() : new Vector3D(def[0], def[1], def[2], def[3] ?? 0);
			case FoxTrackType.MATRIX4: 		def == null ? new Matrix3D() : new Matrix3D(VectorFactory.Float(def));
			case FoxTrackType.VECTOR2:		def == null ? new Vector2() : new Vector2(def[0], def[1]);
			case FoxTrackType.FUNCTION:		def ?? ([]:Array<Dynamic>);
			default: null;
		}
	}
}