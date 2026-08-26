package foxlite.mesh;

import foxlite.math.FoxMathUtil;
import flixel.math.FlxMath;
import foxlite.culling.BoundingBox;
import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMeshBufferType;
import foxlite.polyfill.TypedArray;
import foxlite.renderer.FoxRenderer;
import lime.math.Vector2;
import lime.utils.ArrayBufferView;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.VertexBuffer3D;
import openfl.geom.Vector3D;
#if foxlite_polymod
import lime.graphics.opengl.GL;
import lime.utils.DataPointer;
#end
import lime.utils.Float32Array;

class FoxMesh {

	// GL Data
	public var vertexBuffer:VertexBuffer3D = null;
	public var uvBuffer:VertexBuffer3D = null;
	public var indexBuffer:IndexBuffer3D = null;
	public var normalBuffer:VertexBuffer3D = null;
	public var tangentBuffer:VertexBuffer3D = null;
	public var colorBuffer:VertexBuffer3D = null;
	// For skin
	public var boneWeights:VertexBuffer3D = null;
	public var boneIndices:VertexBuffer3D = null;

	/**
		The buffer usage pattern for optimization purposes.

		__Note:__ This will be applied on the next call to `setArrays()`.
	**/
	public var bufferUsage:Int = 0x88E4; // Only for initialization, corresponds to GL.STATIC_DRAW

	/**
		By default, this mesh will use 3 vertices per face (a triangle),
		but you can change it to 4 (quads) or 2 (lines).

		This will affect how the mesh is processed when drawing.

		__Note:__ To apply it correctly, call `setArrays()` directly afterwards.

		__Note 2:__ This currently needs to be implemented.
	**/
	public var vertexPerFace:Int = 3;

	public var material(default, set):FoxMaterial = null;
	public var assetsKey:String = null;
	public var bounds:BoundingBox = null;

	public var context:Context3D = null;
	public var __isCopy:Bool = false;

	public function new(?mat:FoxMaterial):Void {
		context = FoxRenderer.getContext();
		this.material = mat;
		FoxRenderer.allocationsThisFrame += 1;
	}

	/*
	*  Handy functions to update mesh data
	*/ 
	
	/**
		Writes buffer data on the GPU

		@param type The buffer to write to
		@param data The data array
	**/
	public function setBuffer(type:FoxMeshBufferType, data:Array<Float>) {
		var buffer = getBufferByType(type);
		buffer.uploadFromTypedArray(TypedArray.Float32Array(cast data));
		FoxRenderer.allocationsThisFrame += 1;
	}

	/**
		Same as `setBuffer()` but exclusive to the Index buffer
	**/
	public function setIndexBuffer(data:Array<Int>) {
		indexBuffer.uploadFromTypedArray(TypedArray.UInt16Array(cast data));
		FoxRenderer.allocationsThisFrame += 1;
	}

	/**
		Updates buffer data on the GPU

		Use this to set portions of it or are updating data constantly.
		Tip: Make sure the buffer is set to `GL.DYNAMIC_DRAW` on its usage.

		@param type The buffer to update
		@param data The data array
		@param offset The index of the buffer where to start writing `data`
	**/
	public function updateBuffer(type:FoxMeshBufferType, data:Array<Float>, offset:Int=0) {
		var gl = context.gl;
		offset *= 4; // Offset is actually in bytes
		var buffer = getBufferByType(type);
		context.__bindGLArrayBuffer(buffer.__id);
		var packed = TypedArray.Float32Array(cast data);
		#if foxlite_polymod
		#if lime_webgl
		GL.bufferSubDataWEBGL(gl.ARRAY_BUFFER, offset, packed);
		#else
		GL.bufferSubData(gl.ARRAY_BUFFER, offset, data.length*4, DataPointer.fromArrayBufferView(packed));
		#end
		#else
		gl.bufferSubData(gl.ARRAY_BUFFER, offset, packed);
		#end
		FoxRenderer.allocationsThisFrame += 1;
	}

	/**
		Same as `updateBuffer()` but exclusive to the Index buffer
	**/
	public function updateIndexBuffer(data:Array<Int>, offset:Int=0) {
		var gl = context.gl;
		offset *= 2; // Offset is actually in bytes
		context.__bindGLElementArrayBuffer(indexBuffer.__id);
		var packed = TypedArray.UInt16Array(cast data);
		#if foxlite_polymod
		#if lime_webgl
		GL.bufferSubDataWEBGL(gl.ELEMENT_ARRAY_BUFFER, offset, packed);
		#else
		GL.bufferSubData(gl.ELEMENT_ARRAY_BUFFER, offset, data.length*2, DataPointer.fromArrayBufferView(packed));
		#end
		#else
		gl.bufferSubData(gl.ELEMENT_ARRAY_BUFFER, offset, packed);
		#end
	}

	/**
		Same as `updateBuffer()` and `updateIndexBuffer()`, but there's no data copying to a typed array,
		instead, you provide it.

		This method is faster than the other ones, but needs more setup.
	**/
	public function updateBufferRaw(type:FoxMeshBufferType, data:ArrayBufferView, offset:Int=0) {
		var gl = context.gl;
		if(type == FoxMeshBufferType.INDICES) {
			context.__bindGLElementArrayBuffer(indexBuffer.__id);
			#if foxlite_polymod
			#if lime_webgl
			GL.bufferSubDataWEBGL(gl.ELEMENT_ARRAY_BUFFER, offset, packed);
			#else
			GL.bufferSubData(gl.ELEMENT_ARRAY_BUFFER, offset, data.length, DataPointer.fromArrayBufferView(data));
			#end
			#else
			gl.bufferSubData(gl.ELEMENT_ARRAY_BUFFER, offset, data);
			#end
		}
		else {
			var buffer = getBufferByType(type);
			context.__bindGLArrayBuffer(buffer.__id);
			#if foxlite_polymod
			#if lime_webgl
			GL.bufferSubDataWEBGL(gl.ARRAY_BUFFER, offset, packed);
			#else
			GL.bufferSubData(gl.ARRAY_BUFFER, offset, data.length, DataPointer.fromArrayBufferView(data));
			#end
			#else
			gl.bufferSubData(gl.ARRAY_BUFFER, offset, data);
			#end
		}
	}

	/**
		Creates buffers and uploads data to the GPU.

		__Note:__ The influences array type is not a typo, the values are
		processed as integers in the shader, this prevents internal casts.
	**/
	public function setArrays(?vertices:Array<Float>, ?uvtData:Array<Float>, ?indices:Array<Int>, ?material_:FoxMaterial, ?normals:Array<Float>, ?colors:Array<Float>, ?weights:Array<Float>, ?influences:Array<Float>) {
		if(material_ != null) material = material_;

		if(vertices?.length > 0) {
			vertexBuffer?.dispose();
			vertexBuffer = context.createVertexBuffer(Std.int(vertices.length / 3), 3);
			vertexBuffer.__usage = bufferUsage;
			setBuffer(FoxMeshBufferType.VERTICES, vertices); // Upload to GPU
			FoxRenderer.allocationsThisFrame += 1;
		}

		if(uvtData?.length > 0) {
			uvBuffer?.dispose();
			uvBuffer = context.createVertexBuffer(Std.int(uvtData.length / 2), 2);
			uvBuffer.__usage = bufferUsage;
			setBuffer(FoxMeshBufferType.UVS, uvtData); // Upload to GPU
			FoxRenderer.allocationsThisFrame += 1;
		}

		if(indices?.length > 0) {
			indexBuffer?.dispose();
			indexBuffer = context.createIndexBuffer(indices.length);
			setIndexBuffer(indices); // Upload to GPU
			FoxRenderer.allocationsThisFrame += 1;
		}

		if(normals?.length > 0) {
			normalBuffer?.dispose();
			tangentBuffer?.dispose();

			normalBuffer = context.createVertexBuffer(Std.int(normals.length / 3), 3);
			tangentBuffer = context.createVertexBuffer(Std.int(normals.length / 3), 4);
			FoxRenderer.allocationsThisFrame += 2;

			normalBuffer.__usage = bufferUsage;
			tangentBuffer.__usage = bufferUsage;

			// Upload to GPU
			setBuffer(FoxMeshBufferType.NORMALS, normals);
			var tangents = FoxMesh.computeTangents(vertices, uvtData, normals, indices);
			if(tangents != null) setBuffer(FoxMeshBufferType.TANGENTS, tangents);
		}

		if(colors?.length > 0) {
			colorBuffer?.dispose();
			colorBuffer = context.createVertexBuffer(Std.int(colors.length / 4), 4);
			colorBuffer.__usage = bufferUsage;
			setBuffer(FoxMeshBufferType.COLORS, colors); // Upload to GPU
			FoxRenderer.allocationsThisFrame += 1;
		}
		
		// For skinning

		if(weights?.length > 0) {
			boneWeights?.dispose();
			boneWeights = context.createVertexBuffer(Std.int(weights.length / 4), 4);
			boneWeights.__usage = bufferUsage;
			setBuffer(FoxMeshBufferType.WEIGHTS, weights); // Upload to GPU
			FoxRenderer.allocationsThisFrame += 1;
		}

		if(influences?.length > 0) {
			boneIndices?.dispose();
			boneIndices = context.createVertexBuffer(Std.int(influences.length / 4), 4);
			boneIndices.__usage = bufferUsage;
			setBuffer(FoxMeshBufferType.BONE_INDICES, influences); // Upload to GPU
			FoxRenderer.allocationsThisFrame += 1;
		}
	}

	/**
		Calculates tangents for a set of mesh data.

		Tangents are used along normals for accurate lighting effects using normal maps.

		Note: The output returns a 4-component array. This is XYZ = Tangent and W = Binormal handedness.

		This method is based on a simplified version of the MikkTSpace algorithm  from [This StackOverflow Answer](https://stackoverflow.com/a/66918075)
	**/
	public static function computeTangents(vertices:Array<Float>, uvtData:Array<Float>, normals:Array<Float>, indices:Array<Int>, normalize:Bool=false):Array<Float> {
		if(uvtData == null || uvtData.length == 0) return null;
		
		var tangents:Array<Float> = [];
		var tl = Std.int(vertices.length/3*4);
		tangents.resize(tl); // Make 4-component per vertex
		for(i in 0...tl) tangents[i] = 0; // I really wish fill() method existed here...

		var n:Vector3D = new Vector3D();

		var v1:Vector3D = new Vector3D();
		var v2:Vector3D = new Vector3D();

		var t1:Vector2 = new Vector2();
		var t2:Vector2 = new Vector2();
		
		// Auxiliary
		var v0:Vector3D = new Vector3D();
		var t0:Vector2 = new Vector2();

		FoxRenderer.allocationsThisFrame += 8;
		
		for(l in 0...indices.length) {
			var m:Int = Std.int(l/3) * 3;
			var o:Int = l % 3; 
			var i = indices[l];
    		var j = indices[(o + 1) % 3 + m];
    		var k = indices[(o + 2) % 3 + m];

			var vi = i*3, vj = j*3, vk = k*3;
			var ti = i*2, tj = j*2, tk = k*2;
			var tg = i*4;

			n.setTo(normals[vi], normals[vi+1], normals[vi+2]);
			
			// Aux vectors
			v0.setTo(vertices[vi], vertices[vi+1], vertices[vi+2]);
			t0.setTo(uvtData[ti], uvtData[ti+1]);

			// vec3 v1 = positions[j] - positions[i]
			v1.setTo(vertices[vj], vertices[vj+1], vertices[vj+2]);
			v1.decrementBy(v0);

			// vec3 v2 = positions[k] - positions[i]
			v2.setTo(vertices[vk], vertices[vk+1], vertices[vk+2]);
			v2.decrementBy(v0);

			// vec2 t1 = texCoords[j] - texCoords[i]
			t1.setTo(uvtData[tj], uvtData[tj+1]);
			t1.subtract(t0, t1);

			// vec2 t2 = texCoords[k] - texCoords[i]
			t2.setTo(uvtData[tk], uvtData[tk+1]);
			t2.subtract(t0, t2);

			// Is the texture flipped?
			var uv2xArea = t1.x * t2.y - t1.y * t2.x; // Cross product, not available in Vector2
			if(Math.abs(uv2xArea) < 1e-8) continue;
			
			var flip = FlxMath.signOf(uv2xArea);

			// 'flip' or '-flip'; depends on the handedness of the space.
			//if(tangents[ti+3] != 0 && tangents[ti+3] != -flip) inconsistentUVs += 1;
			tangents[tg+3] = -flip;

			// Project triangle onto tangent plane
			v0.copyFrom(n); // aux normal
			v0.scaleBy(v1.dotProduct(n));
			v1.decrementBy(v0); // v1 -= n * dot(v1, n);

			v0.copyFrom(n); // aux normal
			v0.scaleBy(v2.dotProduct(n));
			v2.decrementBy(v0); // v2 -= n * dot(v2, n);

			// Tangent is object space direction of texture coordinates
			v0.copyFrom(v1);
			v0.scaleBy(t2.y);  // v1 * t2.y
			n.copyFrom(v2);    // We don't need n anymore so use it as temp variable
			n.scaleBy(t1.y);   // v2* t1.y
			v0.decrementBy(n); // v1 * t2.y - v2 * t1.y
			v0.scaleBy(flip);
			v0.normalize();

			// Use angle between projected v1 and v2 as weight
			var angle:Float = Math.acos(v1.dotProduct(v2) / (v1.length * v2.length));
			v0.scaleBy(angle);
			// Initialize (for dynamic targets)
			tangents[tg  ] += v0.x;
			tangents[tg+1] += v0.y;
			tangents[tg+2] += v0.z;
		}
		// To save performance in HScript, normalization happens in the vertex shader instead
		// Set normalize to true to use this
		if(normalize) {
			for(i in 0...indices.length) {
				var tg = indices[i] * 4;
				n.setTo(tangents[tg], tangents[tg+1], tangents[tg+2]);
				n.normalize(); // normalize xyz, keep w

				tangents[tg  ] = n.x;
				tangents[tg+1] = n.y;
				tangents[tg+2] = n.z;
			}
		}

		return tangents;
	}

	/**
		Returns a vertex buffer of this mesh.

		@param type The buffer type. See `FoxMeshBufferType`
	**/
	public function getBufferByType(type:FoxMeshBufferType):VertexBuffer3D {
		return switch(type) {
			case FoxMeshBufferType.VERTICES: return vertexBuffer;
			case FoxMeshBufferType.UVS: return uvBuffer;
			case FoxMeshBufferType.NORMALS: return normalBuffer;
			case FoxMeshBufferType.TANGENTS: return tangentBuffer;
			case FoxMeshBufferType.COLORS: return colorBuffer;
			case FoxMeshBufferType.WEIGHTS: return boneWeights;
			case FoxMeshBufferType.BONE_INDICES: return boneIndices;
			default: null;
		}
	}

	/*
	* Calculates the bounding box for this mesh, for frusutm culling
	*/
	public function calculateBounds(vertices:Dynamic):BoundingBox {
		if(bounds == null) {
			bounds = new BoundingBox();
			FoxRenderer.allocationsThisFrame += 1;
		}

		var point:Vector3D = FoxMathUtil.__tempVector;
		var min:Vector3D = FoxMathUtil.__tempVector2;
		var max:Vector3D = FoxMathUtil.__tempVector3;

		var isArray:Bool = Std.isOfType(vertices, Array);
		var i:Int = 0;
		while(i < vertices.length) {
			if(isArray) 
				point.setTo((vertices:Array<Float>)[i], (vertices:Array<Float>)[i+1], (vertices:Array<Float>)[i+2]);
			else
				point.setTo((vertices:Float32Array)[i], (vertices:Float32Array)[i+1], (vertices:Float32Array)[i+2]);

			min.x = Math.min(min.x, point.x);
			min.y = Math.min(min.y, point.y);
			min.z = Math.min(min.z, point.z);

			max.x = Math.max(max.x, point.x);
			max.y = Math.max(max.y, point.y);
			max.z = Math.max(max.z, point.z);
			i += 3;
		}

		bounds.fromExtents(min, max);
		
		return bounds;
	}

	/** Copies this mesh object, does not create new data on GPU.
	* Use this to use different materials or mix different buffers.
	*
	* Warning! destroying this copy won't free memory on the GPU unless the original is destroyed!
	**/
	public function copy():FoxMesh {
		var mesh = new FoxMesh();
		mesh.vertexBuffer = vertexBuffer;
		mesh.uvBuffer = uvBuffer;
		mesh.indexBuffer = indexBuffer;
		mesh.normalBuffer = normalBuffer;
		mesh.tangentBuffer = tangentBuffer;
		mesh.colorBuffer = colorBuffer;
		mesh.boneWeights = boneWeights;
		mesh.boneIndices = boneIndices;
		mesh.material = material;
		mesh.assetsKey = null;
		mesh.bounds = bounds;
		mesh.__isCopy = true;
		return mesh;
	}

	public function destroy() {
		if(__isCopy) return;
		vertexBuffer?.dispose();
		uvBuffer?.dispose();
		indexBuffer?.dispose();
		normalBuffer?.dispose();
		tangentBuffer?.dispose();
		colorBuffer?.dispose();
		boneWeights?.dispose();
		boneIndices?.dispose();

		if(assetsKey == null) return;
		var cache = FoxCache.meshes().get(assetsKey);
		if(cache != null) {
			cache.remove(this);
			if(cache.length == 0) FoxCache.meshes().remove(assetsKey);
		}
	}

	private function set_material(v:FoxMaterial):FoxMaterial {
		if(v == this.material) return v;
		this.material = v;
		FoxRenderer.mustRebuildDrawGroups = true;
		return v;
	}
}

