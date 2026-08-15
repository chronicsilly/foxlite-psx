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

	var HISTORY = 32;
	var cpuDeltas:Array<Float> = [];
	var gpuDeltas:Array<Float> = [];

	var cpuDeltaIdx:Int = 0;
	var gpuDeltaIdx:Int = 0;

	var cpuLastTime:Float = 0;
	var gpuLastTime:Float = 0;

	var text:FlxText = new FlxText();

	public function new(deltaHistory:Int=32) {
		text.fieldHeight = 16;
		text.size = 16;
		super();

		HISTORY = deltaHistory;
		cpuDeltas.resize(HISTORY);
		gpuDeltas.resize(HISTORY);

		for (i in 0...HISTORY) {
			cpuDeltas[i] = 0;
			gpuDeltas[i] = 0;
		}

		add(text);

		if(!FoxRenderer.onPreDraw.has(displayInfo)) FoxRenderer.onPreDraw.add(displayInfo);
	}

	public override function update(elapsed) {
		super.update(elapsed);
		var cpuTime = Timer.stamp();
		cpuDeltas[cpuDeltaIdx] = Math.round(1 / (cpuTime - cpuLastTime));
		cpuDeltaIdx = (cpuDeltaIdx + 1) % HISTORY;
		cpuLastTime = cpuTime;
	}

	public override function draw() {
		super.draw();
		var gpuTime = Timer.stamp();
		gpuDeltas[gpuDeltaIdx] = Math.round(1 / (gpuTime - gpuLastTime));
		gpuDeltaIdx = (gpuDeltaIdx + 1) % HISTORY;
		gpuLastTime = gpuTime;
	}

	public function displayInfo() {

		var cpuFPS:Float = 0;
		var gpuFPS:Float = 0;

		for(i in 0...HISTORY) {
			cpuFPS += cpuDeltas[i];
			gpuFPS += gpuDeltas[i];
		}
		cpuFPS /= HISTORY;
		gpuFPS /= HISTORY;

		var output:String = template;
		var inst = FoxRenderer.renderedInstances > 0 ? '\n    (x${FoxRenderer.renderedInstances} instance${FoxRenderer.renderedInstances != 1 ? 's' : ''})' : '';
		output = StringTools.replace(output, "$0", '${FoxRenderer.BUILD_NAME} v${FoxRenderer.VERSION}');
		output = StringTools.replace(output, "$1", '${FoxRenderer.drawCalls}');
		output = StringTools.replace(output, "$2", '${FoxRenderer.verticesDrawn} $inst');
		output = StringTools.replace(output, "$3", '${FoxRenderer.stateSwitches}');
		output = StringTools.replace(output, "$4", '${FoxRenderer.frameCount}');
		output = StringTools.replace(output, "$5", '${FoxRenderer.allocationsThisFrame}');
		output = StringTools.replace(output, "$6", '${Math.round(cpuFPS)}');
		output = StringTools.replace(output, "$7", '${Math.round(gpuFPS)}');

		var version = FoxRenderer.getGLVersion();
		output = StringTools.replace(output, "$8", '${FoxRenderer.renderContext} ${version}');
		output = StringTools.replace(output, "$9", '$extraInfo');

		text.text = output;
	}

	public override function destroy() {
		FoxRenderer.onPreDraw.remove(displayInfo);
		text.destroy();
		super.destroy();
	}
}
