package foxlite.animation.data;

import Reflect;
import foxlite.animation.data.FoxTrackData;
import foxlite.animation.FoxTrackType;
import openfl.geom.Vector3D;
import openfl.geom.Matrix3D;
import lime.math.Vector2;

class FoxTrackLinkData {

	public var object:Dynamic;
	public var property:String;
	public var isFunction:Bool = false;
	public var enabled:Bool = true;

	public function new(obj:Dynamic, prop:String) {
		object = obj;
		property = prop;
		isFunction = Reflect.isFunction(Reflect.getProperty(obj, prop));
	}

	public function process(data:FoxTrackData) {
		switch(data.type) {
			case FoxTrackType.ANGLE,
				 FoxTrackType.DEGREES,
				 FoxTrackType.FLOAT,
				 FoxTrackType.BOOL,
				 FoxTrackType.INT, 
				 FoxTrackType.COLOR: { // For tracks with atomic types we just want to assign
					if(isFunction) Reflect.callMethod(object, Reflect.getProperty(object, property), [data.value]); 
					else Reflect.setProperty(object, property, data.value);
			};
			case FoxTrackType.VECTOR3D, 
				 FoxTrackType.VECTOR4, 
				 FoxTrackType.QUATERNION, 
				 FoxTrackType.EULER_ANGLES: { // For tracks of Vector3D copy
					var v:Dynamic = Reflect.getProperty(object, property);
					final value:Vector3D = data.value;
					if(Std.isOfType(v, Vector3D)) {
						v.copyFrom(value);
						v.w = value.w;
					}
					else if(isFunction) Reflect.callMethod(object, v, [value.x, value.y, value.z, value.w]);
			};
			case FoxTrackType.MATRIX4: { // For tracks of Matrix3D copy
				var v:Dynamic = Reflect.getProperty(object, property);
				final value:Matrix3D = data.value;
				if(Std.isOfType(v, Matrix3D)) {
					v.copyRawDataFrom(value.rawData);
				}
				else if(isFunction) Reflect.callMethod(object, v, [value]);
			};
			case FoxTrackType.VECTOR2: { // For tracks of Vector2 copy
				var v:Dynamic = Reflect.getProperty(object, property);
				final value:Vector2 = data.value;
				if(Std.isOfType(v, Vector2)) {
					v.setTo(value.x, value.y);
				}
				else if(isFunction) Reflect.callMethod(object, v, [value.x, value.y]);
			};
		}
	}
}