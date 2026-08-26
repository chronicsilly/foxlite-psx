package foxlite.loaders;

import Reflect;
import haxe.Json;
import haxe.io.Path;
import haxe.io.Bytes;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import foxlite.FoxShader;
import foxlite.animation.FoxAnimation;
import foxlite.culling.BoundingBox;
import foxlite.material.FoxMaterial;
import foxlite.material.FoxTriangleFace;
import foxlite.material.FoxBlendMode;
import foxlite.mesh.FoxMesh;
import foxlite.mesh.FoxMeshBufferType;
import foxlite.renderer.FoxRenderer;
import foxlite.skin.FoxSkinData;
import foxlite.texture.FoxMipFilter;
import foxlite.texture.FoxTextureFilter;
import foxlite.texture.FoxWrapMode;
import foxlite.texture.FoxTexture;

import lime.utils.Float32Array;
import lime.utils.UInt32Array;
import lime.utils.UInt16Array;
import lime.utils.Int16Array;
import lime.utils.Int8Array;
import lime.utils.UInt8ClampedArray;
import lime.utils.ArrayBufferView;

import openfl.Assets;
import openfl.geom.Vector3D;
import openfl.utils.ByteArray;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.IndexBuffer3D;

@dox(hide)
@:noCompletion abstract AccessorComponentType(Int) from Int to Int {
	public inline static final BYTE = 5120;
	public inline static final UNSIGNED_BYTE = 5121;
	public inline static final SHORT = 5122;
	public inline static final UNSIGNED_SHORT = 5123;
	public inline static final UNSIGNED_INT = 5125;
	public inline static final FLOAT = 5126;
}

@dox(hide)
@:noCompletion abstract BufferViewTarget(Int) from Int to Int {
	public inline static final ARRAY_BUFFER = 34962;
	public inline static final ELEMENT_ARRAY_BUFFER = 34963;
}

@dox(hide)
@:noCompletion abstract PrimitiveMode(Int) from Int to Int {
	public inline static final POINTS = 0;
	public inline static final LINES = 1;
	public inline static final LINE_LOOP = 2;
	public inline static final LINE_STRIP = 3;
	public inline static final TRIANGLES = 4;
	public inline static final TRIANGLE_STRIP = 5;
	public inline static final TRIANGLE_FAN = 6;
}

@dox(hide)
@:noCompletion abstract SamplerMagFilter(Int) from Int to Int {
	public inline static final NEAREST = 9728;
	public inline static final LINEAR = 9729;
}

@dox(hide)
@:noCompletion abstract SamplerMinFilter(Int) from Int to Int {
	public inline static final NEAREST = 9728;
	public inline static final LINEAR = 9729;
	public inline static final NEAREST_MIPMAP_NEAREST = 9984;
	public inline static final LINEAR_MIPMAP_NEAREST = 9985;
	public inline static final NEAREST_MIPMAP_LINEAR = 9986;
	public inline static final LINEAR_MIPMAP_LINEAR = 9987;
}

@dox(hide)
@:noCompletion abstract SamplerWrap(Int) from Int to Int {
	public inline static final CLAMP_TO_EDGE = 33071;
	public inline static final MIRRORED_REPEAT = 33648;
	public inline static final REPEAT = 10497;
}

/**
	TODO
**/
class FoxGLTFLoader {

	public static function load(name:String, ?extraShaderFlags:Array<String>, ?customShaderPath:String) {
		var dir:String = Path.directory(name) + '/';

		var gltfJson:Dynamic = FoxLoaderUtil.loadJSON(name);
		
		var buffers:Array<ByteArray> = [];
		for(buf in (gltfJson.buffers:Array<Dynamic>)) {
			var bufPath = FoxLoaderUtil.filePath(dir + buf.uri);
			if(!Assets.exists(bufPath)) {
				buffers.push(null);
				trace('[FoxLite > FoxGLTFLoader]: Warning! buffer $buf not found! (Loading: $bufPath)');
				continue;
			}
			var buffer = Assets.getBytes(bufPath);
			if(buffer == null) {
				trace('[FoxLite > FoxGLTFLoader]: Warning! Could not load buffer $buf! (Loading: $bufPath)');
				buffers.push(null);
				continue;
			}
			buffers.push(buffer);
		}

		if(buffers.length == 0) {
			trace('[FoxLite > FoxGLTFLoader]: Could not load $name. (All buffers are missing)');
			return null;
		}

		return _processData(dir, gltfJson, buffers, extraShaderFlags, customShaderPath);
	}

	public static function loadGLB() {
		return _processData("", null, null);
	}

	@:noCompletion public static function _processData(directory:String, gltfJson:Dynamic, buffers:Array<ByteArray>, ?extraShaderFlags:Array<String>, ?customShaderPath:String):{arrayMeshes:Array<Array<FoxMesh>>, ?materials:Map<String, FoxMaterial>, ?animationLibs:Array<Map<String, FoxAnimation>>} {
		if(extraShaderFlags == null) extraShaderFlags = [];
		if(customShaderPath == null) customShaderPath = FoxShader.BASIC;

		var accessors:Array<Dynamic> = gltfJson.accessors;
		var bufferViews:Array<Dynamic> = gltfJson.bufferViews;

		var meshData:Array<Array<FoxMesh>> = [];
		var materials:Map<String, FoxMaterial> = new StringMap();
		var textures:Array<FoxTexture> = [];
		var materialArray:Array<FoxMaterial> = [];

		function addFlag(f:String) {
			if(!extraShaderFlags.contains(f)) extraShaderFlags.push(f);
		}

		// Preload
		if(gltfJson.textures != null) for(tex in (gltfJson.textures:Array<Dynamic>)) {
			var image:Dynamic = gltfJson.images[tex.source];

			if(image?.uri != null) {
				var sampler:Dynamic = gltfJson.samplers[tex.sampler];
				
				var mipmaps:Bool = 
					!(sampler.minFilter == SamplerMinFilter.LINEAR || 
					sampler.minFilter == SamplerMinFilter.NEAREST);

				var params = {
					wrapMode: FoxWrapMode.REPEAT,
					filter: sampler.magFilter == SamplerMagFilter.NEAREST ? FoxTextureFilter.NEAREST : FoxTextureFilter.LINEAR,
					mipFilter: switch(sampler.minFilter:Int) {
						case SamplerMinFilter.LINEAR_MIPMAP_LINEAR,
							 SamplerMinFilter.LINEAR_MIPMAP_NEAREST:
							 	FoxMipFilter.MIPLINEAR;
						case SamplerMinFilter.NEAREST_MIPMAP_LINEAR,
							 SamplerMinFilter.NEAREST_MIPMAP_NEAREST:
							 	FoxMipFilter.MIPNEAREST;
						default: FoxMipFilter.MIPNONE;
					}
				};

				if(sampler.wrapS != null && sampler.wrapT != null) {
					var repeatU = sampler.wrapS != SamplerWrap.CLAMP_TO_EDGE;
					var repeatV = sampler.wrapT != SamplerWrap.CLAMP_TO_EDGE;
					
					if(repeatU && repeatV) params.wrapMode = FoxWrapMode.REPEAT;
					else if(repeatU) params.wrapMode = FoxWrapMode.REPEAT_U_CLAMP_V;
					else if(repeatV) params.wrapMode = FoxWrapMode.CLAMP_U_REPEAT_V;
					else params.wrapMode = FoxWrapMode.CLAMP;
				}

				var texture = FoxTexture.fromImageRaw(FoxLoaderUtil.filePath(directory + Std.string(image.uri)), mipmaps, cast 1, params) ?? FoxRenderer.MISSING_TEXTURE;
				textures.push(texture);
			}
			else textures.push(null);
		}

		if(gltfJson.materials != null) for(mat in (gltfJson.materials:Array<Dynamic>)) {
			var material = new FoxMaterial();
			if(Std.isOfType(mat.doubleSided, Bool)) material.culling = mat.doubleSided ? FoxTriangleFace.NONE : FoxTriangleFace.BACK;
			
			if(Std.isOfType(mat.alphaMode, String)) switch(mat.alphaMode:String) {
				case "OPAQUE": addFlag("NO_ALPHA_SCISSOR");
				case "BLEND": material.blendMode = FoxBlendMode.MIX;
			}

			if(Std.isOfType(mat.alphaCutoff, Float) || Std.isOfType(mat.alphaCutoff, Int))
				material.alphaScissor = mat.alphaCutoff;
			
			if(mat.emissiveTexture != null) {
				addFlag("EMISSIVE_MAP");
				var tex = textures[mat.emissiveTexture.index];
				if(tex != null) material.textures.set("emissiveMap", tex);
			}

			if(Std.isOfType(mat.emissiveFactor, Array)) {
				material.params.set("uEmissive", mat.emissiveFactor.copy());
			}

			if(mat.normalTexture != null) {
				addFlag("NORMAL_MAP");
				var tex = textures[mat.normalTexture.index];
				if(tex != null) material.textures.set("normalMap", tex);
			}

			var pbr:Dynamic = mat.pbrMetallicRoughness;

			if(pbr?.metallicFactor != null) material.setMetallic(pbr.metallicFactor);
			if(pbr?.roughnessFactor != null) material.setRoughness(pbr.roughnessFactor);

			if(pbr?.baseColorFactor != null) {
				var c = pbr?.baseColorFactor;
				material.params.set("color", c);
			}

			if(pbr?.metallicRoughnessTexture != null) {
				addFlag("ORM_MAP");
				var tex = textures[pbr.metallicRoughnessTexture.index];
				if(tex != null) material.textures.set("ormMap", tex);
			}

			if(pbr.baseColorTexture != null) {
				var tex = textures[pbr.baseColorTexture.index];
				if(tex != null) material.textures.set("bitmap", tex);
			}
			else addFlag("SOLID");

			// Extensions
			var KHR_materials_specular:Dynamic = mat.extensions?.KHR_materials_specular;
			var KHR_materials_emissive_strength:Dynamic = mat.extensions?.KHR_materials_emissive_strength;

			if(KHR_materials_specular?.specularColorFactor != null) {
				var spec = KHR_materials_specular.specularColorFactor;
				material.setSpecularLevels(spec[0], spec[1], spec[2]);
			}

			if(Std.isOfType(KHR_materials_emissive_strength?.emissiveStrength, Float) || Std.isOfType(KHR_materials_emissive_strength?.emissiveStrength, Int)) {
				var em = material.params.get("uEmissive");
				if(em != null) {
					var s:Float = KHR_materials_emissive_strength.emissiveStrength;
					em[0] *= s;
					em[1] *= s;
					em[2] *= s;
				}
			}

			// Compile shader
			material.shader = FoxShader.fromAsset(customShaderPath, extraShaderFlags);

			materials.set(mat.name, material);
			materialArray.push(material);
		}

		for(mesh in (gltfJson.meshes:Array<Dynamic>)) {
			var meshes:Array<FoxMesh> = [];
			for(i=>prim in (mesh.primitives:Array<Dynamic>)) {
				var mesh = new FoxMesh();
				var meshAccessors:IntMap<String> = new IntMap();

				for(attrib in Reflect.fields(prim.attributes)) meshAccessors.set(Reflect.field(prim.attributes, attrib), attrib.toUpperCase());
				meshAccessors.set(prim.indices, "INDICES");
				
				for(accessorIndex=>attrib in meshAccessors) {
					var accessor:Dynamic = accessors[accessorIndex];
					var view:Dynamic = bufferViews[accessor.bufferView];
					var buffer:ByteArray = buffers[view.buffer];

					var count:Int = accessor.count;
					var data32PerVertex:Int = switch(accessor.type:String) {
						case "SCALAR": 1;
						case "VEC2": 2;
						case "VEC3": 3;
						case "VEC4", "MAT2": 4;
						case "MAT3": 9;
						case "MAT4": 16;
						default: 1;
					};
					count *= data32PerVertex;

					var dataArray:ArrayBufferView = switch(accessor.componentType:Int) {
						case AccessorComponentType.BYTE: new UInt8ClampedArray(count);
						case AccessorComponentType.UNSIGNED_BYTE: new Int8Array(count);
						case AccessorComponentType.SHORT: new Int16Array(count);
						case AccessorComponentType.UNSIGNED_SHORT: new UInt16Array(count);
						case AccessorComponentType.UNSIGNED_INT: new UInt32Array(count);
						case AccessorComponentType.FLOAT: new Float32Array(count);
						default: null;
					}

					// Write data
					dataArray.buffer.blit(0, buffer, view.byteOffset, view.byteLength);
					
					var gpuBuffer:Any = null;
					
					switch(view.target:Int) {
						case BufferViewTarget.ARRAY_BUFFER: {
							gpuBuffer = mesh.context.createVertexBuffer(accessor.count, data32PerVertex);
							(gpuBuffer:VertexBuffer3D).uploadFromTypedArray(dataArray);
						};
						case BufferViewTarget.ELEMENT_ARRAY_BUFFER: {
							gpuBuffer = mesh.context.createIndexBuffer(accessor.count);
							(gpuBuffer:IndexBuffer3D).uploadFromTypedArray(dataArray);
						};
					}
					
					switch(attrib) {
						case "POSITION": {
							// Add precalculated bounds aswell
							if(mesh.bounds == null) {
								var min:Array<Float> = accessor.min;
								var max:Array<Float> = accessor.max;
								mesh.bounds = new BoundingBox();
								mesh.bounds.fromExtents(
									new Vector3D(min[0], min[1], min[2]),
									new Vector3D(max[0], max[1], max[2])
								);
							}
							mesh.vertexBuffer = gpuBuffer;
						}
						case "NORMAL": mesh.normalBuffer = gpuBuffer;
						case "TANGENT": mesh.tangentBuffer = gpuBuffer;
						case "TEXCOORD_0": mesh.uvBuffer = gpuBuffer;
						case "COLOR_0": mesh.colorBuffer = gpuBuffer;
						case "INDICES": mesh.indexBuffer = gpuBuffer;
						default: (gpuBuffer:Dynamic)?.dispose(); // In case we have an invalid attribute
					}
				}
				if(Std.isOfType(prim.material, Int)) mesh.material = materialArray[prim.material];
				// TODO: maybe move render mode to mesh instead of material?
				//if(Std.isOfType(prim.mode, Int)) ;
				meshes.push(mesh);
			}
			meshData.push(meshes);
		}

		return {
			arrayMeshes: meshData,
			materials: materials
		};
	}
}