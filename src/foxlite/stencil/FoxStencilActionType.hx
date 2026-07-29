package foxlite.stencil;

// How to create enum abstracts in Polymod: You don't!
// Surprisingly, this is valid in Haxe
#if !foxlite_polymod enum abstract #else class #end FoxStencilActionType #if !foxlite_polymod (Int) from Int to Int #end {
	/**
		Decrement the stencil buffer value, clamping at 0, the minimum value.
	**/
	public inline static final DECREMENT_SATURATE = 0;

	/**
		Decrement the stencil buffer value. If the result is less than 0, the minimum
		value, then the buffer value is "wrapped around" to 255.
	**/
	public inline static final DECREMENT_WRAP = 1;

	/**
		Increment the stencil buffer value, clamping at 255, the maximum value.
	**/
	public inline static final INCREMENT_SATURATE = 2;

	/**
		Increment the stencil buffer value. If the result exceeds 255, the maximum
		value, then the buffer value is "wrapped around" to 0.
	**/
	public inline static final INCREMENT_WRAP = 3;

	/**
		Invert the stencil buffer value, bitwise.

		For example, if the 8-bit binary number in the stencil buffer is: 11110000, then
		the value is changed to: 00001111.
	**/
	public inline static final INVERT = 4;

	/**
		Keep the current stencil buffer value.
	**/
	public inline static final KEEP = 5;

	/**
		Replace the stencil buffer value with the reference value.
	**/
	public inline static final SET = 6;

	/**
		Set the stencil buffer value to 0.
	**/
	public inline static final ZERO = 7;

	public static function fromString(action:String):FoxStencilActionType {
		action = action.toLowerCase();
		return switch(action) {
			case "decrement_saturate": FoxStencilActionType.DECREMENT_SATURATE;
			case "decrement_wrap": FoxStencilActionType.DECREMENT_WRAP;
			case "increment_saturate": FoxStencilActionType.INCREMENT_SATURATE;
			case "increment_wrap": FoxStencilActionType.INCREMENT_WRAP;
			case "invert": FoxStencilActionType.INVERT;
			case "set": FoxStencilActionType.SET;
			case "zero": FoxStencilActionType.ZERO;
			default: FoxStencilActionType.KEEP;
		}
	}
}