package foxlite.mesh;

import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMesh;
import foxlite.renderer.FoxRenderer;
import haxe.ds.IntMap;
import lime.math.Vector4;
import openfl.geom.Vector3D;

/**
	A helper to create lines for a mesh.

	Supports updating efficiently on the GPU.

	Lines don't support UV mapping, instead, the data represents values as follows:
	- `U` is set to the line lerp points, it will interpolate between 0 and 1 from
	the line start point to the line end point
	- `V` is set to the length of the line in local space

	However, lines can still use vertex colors, just make sure your material supports it.
**/
class FoxLineMesh extends FoxMesh {

	public var linePositions:Array<Float> = [];
	public var lineColors:Array<Float> = [];
	public var lineUVs:Array<Float> = [];
	public var indices:Array<Int> = [];
	public var lineCount:Int = 0;

	private var __vertexUpdates:Map<Int, Array<Float>> = new IntMap();
	private var __colorsUpdates:Map<Int, Array<Float>> = new IntMap();
	private var __uvsUpdates:Map<Int, Array<Float>> = new IntMap();

	public function new(?lineMaterial:FoxMaterial) {
		super();
		material = lineMaterial;
	}

	/**
		Adds a line to the mesh. Call `build()` when you're done

		__Note:__ This method will allocate memory each time,
		to update lines efficiently in real time, check `updateLine()`

		@param from The position where the line will start
		@param end The position where the line will end
		@param color Optional: The line color
	**/
	public function addLine(from:Vector3D, to:Vector3D, ?startColor:Vector4, ?endColor:Vector4) {
		if(startColor == null) startColor = new Vector4(1,1,1,1);
		if(endColor == null) endColor = startColor;
		linePositions.push(from.x);
		linePositions.push(from.y);
		linePositions.push(from.z);
		linePositions.push(to.x);
		linePositions.push(to.y);
		linePositions.push(to.z);

		lineColors.push(startColor.x);
		lineColors.push(startColor.y);
		lineColors.push(startColor.z);
		lineColors.push(startColor.w);
		lineColors.push(endColor.x);
		lineColors.push(endColor.y);
		lineColors.push(endColor.z);
		lineColors.push(endColor.w);

		var len = Vector3D.distance(from, to);
		lineUVs.push(0);
		lineUVs.push(len);
		lineUVs.push(1);
		lineUVs.push(len);

		var idx = lineCount*2;
		indices.push(idx);
		indices.push(idx+1);
		lineCount += 1;
		FoxRenderer.allocationsThisFrame += 1;
	}

	/**
		Callocates added lines to the GPU.
		Call this after creating lines with `addLine()`
	**/
	public function build() {
		bufferUsage = context.gl.DYNAMIC_DRAW;
		setArrays(linePositions, lineUVs, indices, null, null, lineColors);
	}

	/**
		Pushes all updated lines to the GPU.
		Call this after updating lines with `updateLine()`
	**/
	public function flushUpdates() {
		for(offset => data in __vertexUpdates) updateBuffer(FoxMeshBufferType.VERTICES, data, offset);
		for(offset => data in __colorsUpdates) updateBuffer(FoxMeshBufferType.COLORS, data, offset);
		for(offset => data in __uvsUpdates) updateBuffer(FoxMeshBufferType.UVS, data, offset);
		__vertexUpdates.clear();
		__colorsUpdates.clear();
		__uvsUpdates.clear();
	}

	public function updateLine(index:Int, from:Vector3D, to:Vector3D, ?startColor:Vector4, ?endColor:Vector4) {
		var posIdx = index * 6;
		var colorIdx = index * 8;
		var uvIdx = index * 4;
		
		linePositions[posIdx  ] = from.x;
		linePositions[posIdx+1] = from.y;
		linePositions[posIdx+2] = from.z;
		
		linePositions[posIdx+3] = to.x;
		linePositions[posIdx+4] = to.y;
		linePositions[posIdx+5] = to.z;

		__vertexUpdates.set(posIdx, linePositions.slice(posIdx, posIdx+6));

		var len = Vector3D.distance(from, to);
		lineUVs[uvIdx+1] = len;
		lineUVs[uvIdx+3] = len;

		__uvsUpdates.set(uvIdx, lineUVs.slice(uvIdx, uvIdx+4));
		
		if(startColor != null) {
			lineColors[colorIdx  ] = startColor.x;
			lineColors[colorIdx+1] = startColor.y;
			lineColors[colorIdx+2] = startColor.z;
			lineColors[colorIdx+3] = startColor.w;

			__colorsUpdates.set(colorIdx, lineColors.slice(colorIdx, colorIdx+4));
		}
		if(endColor != null) {
			lineColors[colorIdx+4] = endColor.x;
			lineColors[colorIdx+5] = endColor.y;
			lineColors[colorIdx+6] = endColor.z;
			lineColors[colorIdx+7] = endColor.w;

			__colorsUpdates.set(colorIdx+4, lineColors.slice(colorIdx+4, colorIdx+8));
		}
	}

	public function clear() {
		linePositions.resize(0);
		lineColors.resize(0);
		lineUVs.resize(0);
		indices.resize(0);
		lineCount = 0;
	}
}