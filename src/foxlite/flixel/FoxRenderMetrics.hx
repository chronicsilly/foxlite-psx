package foxlite.flixel;

import StringTools;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import foxlite.renderer.FoxRenderer;
import haxe.Timer;

class FoxRenderMetrics extends FlxSpriteGroup {

	public var template = StringTools.replace('
	-- FoxLite $0 --
	renderContext: $8
	drawCalls: $1
	vertices: $2
	stateSwitches: $3
	Allocations: $5
	frameCount: $4
	-------------
	CPU FPS: $6
	GPU FPS: $7
	-------------
	$9
	', '\r', '');

	public var extraInfo:String = "";

	public var cpuDelta:Float = 0;
	public var gpuDelta:Float = 0;

	var cpuLastTime:Float = timestamp();
	var gpuLastTime:Float = timestamp();

	var text:FlxText = new FlxText();

	public function new() {
		text.fieldHeight = 16;
		text.size = 16;
		super();

		add(text);

		if(!FoxRenderer.onPreDraw.has(displayInfo)) FoxRenderer.onPreDraw.add(displayInfo);
	}

	public override function update(elapsed) {
		var cpuTime = timestamp();
		cpuDelta = cpuTime - cpuLastTime;
		cpuLastTime = cpuTime;
		super.update(elapsed);
	}

	public override function draw() {
		var gpuTime = timestamp();
		gpuDelta = gpuTime - gpuLastTime;
		gpuLastTime = gpuTime;
		super.draw();
	}

	public function displayInfo() {

		var output:String = template;
		var inst = FoxRenderer.renderedInstances > 0 ? '\n    (x${FoxRenderer.renderedInstances} instance${FoxRenderer.renderedInstances != 1 ? 's' : ''})' : '';
		output = StringTools.replace(output, "$0", '${FoxRenderer.BUILD_NAME} v${FoxRenderer.VERSION}');
		output = StringTools.replace(output, "$1", '${FoxRenderer.drawCalls}');
		output = StringTools.replace(output, "$2", '${FoxRenderer.verticesDrawn} $inst');
		output = StringTools.replace(output, "$3", '${FoxRenderer.stateSwitches}');
		output = StringTools.replace(output, "$4", '${FoxRenderer.frameCount}');
		output = StringTools.replace(output, "$5", '${FoxRenderer.allocationsThisFrame}');
		output = StringTools.replace(output, "$6", '${Math.round(1 / cpuDelta)}');
		output = StringTools.replace(output, "$7", '${Math.round(1 / gpuDelta)}');

		var version = FoxRenderer.getGLVersion();
		output = StringTools.replace(output, "$8", '${FoxRenderer.renderContext} ${version}');
		output = StringTools.replace(output, "$9", '$extraInfo');

		text.text = output;
	}

	public inline function timestamp():Float {
		return Timer.stamp();
	}

	public override function destroy() {
		FoxRenderer.onPreDraw.remove(displayInfo);
		text.destroy();
		super.destroy();
	}
}
