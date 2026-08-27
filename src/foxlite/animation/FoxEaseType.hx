package foxlite.animation;

// How to create abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod abstract #else class #end FoxEaseType #if !foxlite_polymod (Int) from Int to Int #end {
	// Default godot ease
	public inline static final LINEAR = 0;
	public inline static final QUAD_IN = 1;
	public inline static final QUAD_OUT = 2;
	public inline static final QUAD_INOUT = 3;
	public inline static final ZERO = 4;
	// More ease types based on FlxEase
	public inline static final BACK_IN = 5;
	public inline static final BACK_INOUT = 6;
	public inline static final BACK_OUT = 7;
	public inline static final BOUNCE_IN = 8;
	public inline static final BOUNCE_INOUT = 9;
	public inline static final BOUNCE_OUT = 10;
	public inline static final CIRC_IN = 11;
	public inline static final CIRC_INOUT = 12;
	public inline static final CIRC_OUT = 13;
	public inline static final CUBE_IN = 14;
	public inline static final CUBE_INOUT = 15;
	public inline static final CUBE_OUT = 16;
	public inline static final ELASTIC_IN = 17;
	public inline static final ELASTIC_INOUT = 18;
	public inline static final ELASTIC_OUT = 19;
	public inline static final EXPO_IN = 20;
	public inline static final EXPO_INOUT = 21;
	public inline static final EXPO_OUT = 22;
	public inline static final QUART_IN = 23;
	public inline static final QUART_INOUT = 24;
	public inline static final QUART_OUT = 25;
	public inline static final QUINT_IN = 26;
	public inline static final QUINT_INOUT = 27;
	public inline static final QUINT_OUT = 28;
	public inline static final SINE_IN = 29;
	public inline static final SINE_INOUT = 30;
	public inline static final SINE_OUT = 31;
	public inline static final SMOOTHSTEP_IN = 32;
	public inline static final SMOOTHSTEP_INOUT = 33;
	public inline static final SMOOTHSTEP_OUT = 34;
	public inline static final SMOOTHERSTEP_IN = 35;
	public inline static final SMOOTHERSTEP_INOUT = 36;
	public inline static final SMOOTHERSTEP_OUT = 37;

	@:from public static function fromString(type:String):FoxEaseType {
		type = type.toLowerCase();
		return switch(type) {
			case "zero": FoxEaseType.ZERO;
			case "quadIn": FoxEaseType.QUAD_IN;
			case "quadInOut": FoxEaseType.QUAD_INOUT;
			case "quadOut": FoxEaseType.QUAD_OUT;
			case "backIn": FoxEaseType.BACK_IN;
			case "backInOut": FoxEaseType.BACK_INOUT;
			case "backOut": FoxEaseType.BACK_OUT;
			case "bounceIn": FoxEaseType.BOUNCE_IN;
			case "bounceInOut": FoxEaseType.BOUNCE_INOUT;
			case "bounceOut": FoxEaseType.BOUNCE_OUT;
			case "circIn": FoxEaseType.CIRC_IN;
			case "circInOut": FoxEaseType.CIRC_INOUT;
			case "circOut": FoxEaseType.CIRC_OUT;
			case "cubeIn": FoxEaseType.CUBE_IN;
			case "cubeInOut": FoxEaseType.CUBE_INOUT;
			case "cubeOut": FoxEaseType.CUBE_OUT;
			case "elasticIn": FoxEaseType.ELASTIC_IN;
			case "elasticInOut": FoxEaseType.ELASTIC_INOUT;
			case "elasticOut": FoxEaseType.ELASTIC_OUT;
			case "expoIn": FoxEaseType.EXPO_IN;
			case "expoInOut": FoxEaseType.EXPO_INOUT;
			case "expoOut": FoxEaseType.EXPO_OUT;
			case "quartIn": FoxEaseType.QUART_IN;
			case "quartInOut": FoxEaseType.QUART_INOUT;
			case "quartOut": FoxEaseType.QUART_OUT;
			case "sineIn": FoxEaseType.SINE_IN;
			case "sineInOut": FoxEaseType.SINE_INOUT;
			case "sineOut": FoxEaseType.SINE_OUT;
			case "smoothStepIn": FoxEaseType.SMOOTHSTEP_IN;
			case "smoothStepInOut": FoxEaseType.SMOOTHSTEP_INOUT;
			case "smoothStepOut": FoxEaseType.SMOOTHSTEP_OUT;
			case "smootherStepIn": FoxEaseType.SMOOTHERSTEP_IN;
			case "smootherStepInOut": FoxEaseType.SMOOTHERSTEP_INOUT;
			case "smootherStepOut": FoxEaseType.SMOOTHERSTEP_OUT;
			default: FoxEaseType.LINEAR;
		}
	}

	@:to public static function toString(type:FoxEaseType):String {
		return switch(type) {
			case FoxEaseType.ZERO: "zero";
			case FoxEaseType.QUAD_IN: "quadIn";
			case FoxEaseType.QUAD_INOUT: "quadInOut";
			case FoxEaseType.QUAD_OUT: "quadOut";
			case FoxEaseType.BACK_IN: "backIn";
			case FoxEaseType.BACK_INOUT: "backInOut";
			case FoxEaseType.BACK_OUT: "backOut";
			case FoxEaseType.BOUNCE_IN: "bounceIn";
			case FoxEaseType.BOUNCE_INOUT: "bounceInOut";
			case FoxEaseType.BOUNCE_OUT: "bounceOut";
			case FoxEaseType.CIRC_IN: "circIn";
			case FoxEaseType.CIRC_INOUT: "circInOut";
			case FoxEaseType.CIRC_OUT: "circOut";
			case FoxEaseType.CUBE_IN: "cubeIn";
			case FoxEaseType.CUBE_INOUT: "cubeInOut";
			case FoxEaseType.CUBE_OUT: "cubeOut";
			case FoxEaseType.ELASTIC_IN: "elasticIn";
			case FoxEaseType.ELASTIC_INOUT: "elasticInOut";
			case FoxEaseType.ELASTIC_OUT: "elasticOut";
			case FoxEaseType.EXPO_IN: "expoIn";
			case FoxEaseType.EXPO_INOUT: "expoInOut";
			case FoxEaseType.EXPO_OUT: "expoOut";
			case FoxEaseType.QUART_IN: "quartIn";
			case FoxEaseType.QUART_INOUT: "quartInOut";
			case FoxEaseType.QUART_OUT: "quartOut";
			case FoxEaseType.SINE_IN: "sineIn";
			case FoxEaseType.SINE_INOUT: "sineInOut";
			case FoxEaseType.SINE_OUT: "sineOut";
			case FoxEaseType.SMOOTHSTEP_IN: "smoothStepIn";
			case FoxEaseType.SMOOTHSTEP_INOUT: "smoothStepInOut";
			case FoxEaseType.SMOOTHSTEP_OUT: "smoothStepOut";
			case FoxEaseType.SMOOTHERSTEP_IN: "smootherStepIn";
			case FoxEaseType.SMOOTHERSTEP_INOUT: "smootherStepInOut";
			case FoxEaseType.SMOOTHERSTEP_OUT: "smootherStepOut";
			default: "linear";
		}
	}
}