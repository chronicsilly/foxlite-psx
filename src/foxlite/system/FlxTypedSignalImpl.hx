package foxlite.system;

#if foxlite_polymod

// We can't import FlxTypedSignal in polymod, so we create our polyfill
// Must be dynamic due to the nature of polymod

class FlxTypedSignalImpl {

	private var listeners:Array<FlxTypedSignalImplListener> = [];

	public function new() {}

	public inline function add(func:Any) {
		if(!has(func)) listeners.push(new FlxTypedSignalImplListener(func));
	}

	public inline function addOnce(func:Any) {
		if(!has(func)) listeners.push(new FlxTypedSignalImplListener(func, true));
	}

	public inline function remove(func:Any) {
		listeners.remove(getHandler(func));
	}

	public inline function removeAll() {
		while(listeners.length > 0) {
			listeners.pop().func = null;
		}
	}

	public inline function has(func:Any):Bool {
		return getHandler(func) != null;
	}

	private inline function getHandler(func:Any):FlxTypedSignalImplListener {
		for(l in listeners) if(l.func == func) return l;
		return null;
	}

	public inline function dispatch(?v1, ?v2, ?v3, ?v4) {
		var remove:Array<FlxTypedSignalImplListener> = [];
		for(l in listeners) {
			l.dispatch(v1, v2, v3, v4);
			if(l.once) remove.push(l);
		}
		for(r in remove) listeners.remove(r);
	}
}

class FlxTypedSignalImplListener {
	public var func:Dynamic;
	public var once:Bool;

	public function new(f:Any, o:Bool=false) {
		func = f;
		once = o;
	}

	public inline function dispatch(?v1, ?v2, ?v3, ?v4) {
		func(v1, v2, v3, v4);
	}
}
#else
// For source we just use FlxTypedSignal template
typedef FlxTypedSignalImpl<T> = flixel.util.FlxSignal.FlxTypedSignal<T>
#end

enum Bruh4 {}