package foxlite.lights;

// How to create abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod abstract #else class #end FoxLightType #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final DIRECTIONAL = 0;
	public inline static final POINT = 1;
	public inline static final SPOT = 2;
	public inline static final AREA = 3;

	@:from public static function fromString(type:String):FoxLightType {
		type = type.toLowerCase();
		return switch(type) {
			case "directional": FoxLightType.DIRECTIONAL;
			case "point": FoxLightType.POINT;
			case "spot": FoxLightType.SPOT;
			case "area": FoxLightType.AREA;
			default: throw "Invalid string value"; // We want to error here because this type check is critical
		}
	}

	@:to public static function toString(type:FoxLightType):String {
		return switch(type) {
			case FoxLightType.DIRECTIONAL: "directional";
			case FoxLightType.POINT: "point";
			case FoxLightType.SPOT: "spot";
			case FoxLightType.AREA: "area";
			default: throw "Invalid enum value"; // We want to error here because this type check is critical
		}
	}
}