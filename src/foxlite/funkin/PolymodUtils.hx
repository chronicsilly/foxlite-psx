package foxlite.funkin;

import foxlite.group.FoxTypedGroup.FoxGroup;
import Reflect;

class PolymodUtils {

	/**
		Checks a property of an instance.

		This exists because this does not work in Polymod.
		(In Haxe, can be done via `Reflect.hasField()`, but Polymod always returns null)
	**/
	public static inline function instanceHasField(instance:Dynamic, field:String):Bool {
		return Reflect.getProperty(instance, "_cachedVarDecls")?.exists(field) ?? false;
	}

	public static inline function getFoxGroup():FoxGroup {
		return new FoxGroup();
	}
}