package foxlite.stencil;

import foxlite.material.FoxTriangleFace;
import foxlite.stencil.FoxStencilActionType;
import foxlite.stencil.FoxStencilCompareMode;

class FoxStencilAction {
	
	/**
		The reference value for this stencil action
	**/
	public var value:Int = 0;

	/**
		If true, configures the action to only read the stencil value

		This sets `write` to `false`

		A stencil operation should not perform read and write at the same time
	**/
	public var read(get, set):Bool;

	/**
		If true, configures the action to only write to the stencil buffer

		This sets `read` to `false`

		A stencil operation should not perform read and write at the same time
	**/
	public var write(get, set):Bool;

	public var readMask:Int = 0x0;
	public var writeMask:Int = 0xFF;

	/**
		The face of the triangle where operations will take place.
	**/
	public var triangleFace:FoxTriangleFace = FoxTriangleFace.FRONT_AND_BACK;

	/**
		Determines if the action should pass or fail depending on the outcome of this
		comparison between `value` and the stencil counter
	**/
	public var compareMode:FoxStencilCompareMode = FoxStencilCompareMode.ALWAYS;

	/**
		Updates the stencil counter if the action passed in both the stencil buffer and depth buffer
	**/
	public var actionOnBothPass:FoxStencilActionType = FoxStencilActionType.KEEP;

	/**
		Updates the stencil counter if the action failed on the depth buffer
	**/
	public var actionOnDepthFail:FoxStencilActionType = FoxStencilActionType.KEEP;

	/**
		Updates the stencil counter if the action passed on the depth buffer, but failed in the stencil buffer
	**/
	public var actionOnFail:FoxStencilActionType = FoxStencilActionType.KEEP;

	// Cached ids for the renderer
	public var referenceValueId:Int = 0;
	public var actionId:Int = 0;

	public function new() {}

	public function setMask(face:FoxTriangleFace=2, read:Int=0xFF, write:Int=0xFF) {
		triangleFace = face;
		readMask = read;
		writeMask = write;
		getReferenceValueID();
		getActionID();
	}

	/**
		Sets the operations for this stencil action: fail, zfail, zpass
	**/
	public function setActions(compare:FoxStencilCompareMode=0, onFail:FoxStencilActionType=5, onDepthFail:FoxStencilActionType=5, onBothPass:FoxStencilActionType=5) {
		compareMode = compare;
		actionOnFail = onFail;
		actionOnDepthFail = onDepthFail;
		actionOnBothPass = onBothPass;
		getReferenceValueID();
		getActionID();
	}

	public function getReferenceValueID() {
		referenceValueId = value | readMask << 8 | writeMask << 16;
		return referenceValueId;
	}

	public function getActionID() {
		actionId = compareMode | triangleFace << 3 | actionOnBothPass << 5 | actionOnDepthFail << 8 | actionOnFail << 11; // 3 bits + 2 bits + 3 bits + 3 bits
		return actionId;
	}

	function get_read():Bool {
		return readMask != 0;
	}

	function set_read(v:Bool):Bool {
		readMask = 0xFF;
		writeMask = 0x0;
		getReferenceValueID();
		return v;
	}

	function get_write():Bool {
		return writeMask != 0;
	}

	function set_write(v:Bool):Bool {
		writeMask = 0xFF;
		readMask = 0x0;
		getReferenceValueID();
		return v;
	}
}