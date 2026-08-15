package foxlite.animation;

import foxlite.animation.FoxEaseType;

class FoxKeyframe #if !foxlite_polymod <T> #end {
	public var time:Float = 0;
	public var ease:FoxEaseType;
	public var value:T;

	public function new(time_:Float, value_:T, easing:Int=0) {
		// Polymod doesn't like this.<property> in the constructor
		time = time_;
		value = value_;
		ease = easing;
	}
}