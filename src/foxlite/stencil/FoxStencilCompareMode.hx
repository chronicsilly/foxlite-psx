package foxlite.stencil;

#if !foxlite_polymod
typedef FoxStencilCompareMode = foxlite.material.FoxDepthCompareMode;
#else
class FoxStencilCompareMode {
	/**
		The comparison always evaluates as true.
	**/
	public inline static final ALWAYS = 0;

	/**
		Equal (==).
	**/
	public inline static final EQUAL = 1;

	/**
		Greater than (>).
	**/
	public inline static final GREATER = 2;

	/**
		Greater than or equal (>=).
	**/
	public inline static final GREATER_EQUAL = 3;

	/**
		Less than (<).
	**/
	public inline static final LESS = 4;

	/**
		Less than or equal (<=).
	**/
	public inline static final LESS_EQUAL = 5;

	/**
		The comparison never evaluates as true.
	**/
	public inline static final NEVER = 6;

	/**
		Not equal (!=).
	**/
	public inline static final NOT_EQUAL = 7;
}
#end