package foxlite.loaders;

import StringTools;
import haxe.Json;
import haxe.io.Path;
import haxe.io.Bytes;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import haxe.crypto.Base64;
import foxlite.FoxShader;
import foxlite.animation.FoxAnimation;
import foxlite.animation.FoxTrackType;
import foxlite.animation.FoxAnimationTrack;
import foxlite.animation.FoxEaseType;
import foxlite.culling.BoundingBox;
import foxlite.material.FoxMaterial;
import foxlite.material.FoxTriangleFace;
import foxlite.material.FoxBlendMode;
import foxlite.math.FoxMathUtil;
import foxlite.mesh.FoxMesh;
import foxlite.mesh.FoxMeshBufferType;
import foxlite.polyfill.VectorFactory;
import foxlite.renderer.FoxRenderer;
import foxlite.skin.FoxSkinData;
import foxlite.skin.FoxBone;
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
import lime.math.Vector2;
import lime.graphics.Image;
import lime.system.Endian;

import openfl.Assets;
import openfl.geom.Vector3D;
import openfl.geom.Matrix3D;
import openfl.utils.ByteArray;
import openfl.display.BitmapData;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.textures.Texture;

@dox(hide)
@:noCompletion #if !foxlite_polymod abstract #else class #end AccessorComponentType #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final BYTE = 5120;
	public inline static final UNSIGNED_BYTE = 5121;
	public inline static final SHORT = 5122;
	public inline static final UNSIGNED_SHORT = 5123;
	public inline static final UNSIGNED_INT = 5125;
	public inline static final FLOAT = 5126;
}

@dox(hide)
@:noCompletion #if !foxlite_polymod abstract #else class #end BufferViewTarget #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final ARRAY_BUFFER = 34962;
	public inline static final ELEMENT_ARRAY_BUFFER = 34963;
}

@dox(hide)
@:noCompletion #if !foxlite_polymod abstract #else class #end PrimitiveMode #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final POINTS = 0;
	public inline static final LINES = 1;
	public inline static final LINE_LOOP = 2;
	public inline static final LINE_STRIP = 3;
	public inline static final TRIANGLES = 4;
	public inline static final TRIANGLE_STRIP = 5;
	public inline static final TRIANGLE_FAN = 6;
}

@dox(hide)
@:noCompletion #if !foxlite_polymod abstract #else class #end SamplerMagFilter #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final NEAREST = 9728;
	public inline static final LINEAR = 9729;
}

@dox(hide)
@:noCompletion #if !foxlite_polymod abstract #else class #end SamplerMinFilter #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final NEAREST = 9728;
	public inline static final LINEAR = 9729;
	public inline static final NEAREST_MIPMAP_NEAREST = 9984;
	public inline static final LINEAR_MIPMAP_NEAREST = 9985;
	public inline static final NEAREST_MIPMAP_LINEAR = 9986;
	public inline static final LINEAR_MIPMAP_LINEAR = 9987;
}

@dox(hide)
@:noCompletion #if !foxlite_polymod abstract #else class #end SamplerWrap #if !foxlite_polymod (Int) from Int to Int #end {
	public inline static final CLAMP_TO_EDGE = 33071;
	public inline static final MIRRORED_REPEAT = 33648;
	public inline static final REPEAT = 10497;
}

typedef GLTFData = {
	meshes:Array<FoxMesh>, 
	?materials:Map<String, FoxMaterial>, 
	?animations:Map<String, FoxAnimation>, 
	?skins:Array<FoxSkinData>,
	gltfJson:Dynamic
}

class FoxGLTFLoader {

	/**
		Loads models, animations and lights from a `.gltf` file, this also includes the `.bin` buffers and textures.

		GLTF models are scenes, this means they have an unique structure models should follow.

		You can use the meshes array, but all meshes will be positioned at the origin. Instead, call
		`FoxObjectGroup.fromGLTF()`, this takes a gltf json structure and parses the respective objects with
		their respective parent, skin data, animations and so on

		__Note:__ Cache is applied only to foxlite resources such as textures, materials and so on. The gltf aswell as
		its binary buffers will be loaded every time you call this function to refresh the cache if something is missing.
	**/
	public static function load(name:String, ?extraShaderFlags:Array<String>, ?customShaderPath:String):GLTFData {
		var dir:String = Path.directory(name) + '/';

		var gltfJson:Dynamic = FoxLoaderUtil.loadJSON(name);
		if(gltfJson == null) {
			trace('[FoxLite > FoxGLTFLoader]: Could not load $name (Not found.)');
			return null;
		}
		if(gltfJson.asset.version == null || gltfJson.asset.version < "2.0") {
			trace('[FoxLite > FoxGLTFLoader]: GLTF version < 2.0 is not supported! ($name)');
			return null;
		}
		gltfJson.assetsKey = name;
		
		var buffers:Array<ByteArray> = [];
		for(i=>buf in (gltfJson.buffers:Array<Dynamic>)) {
			var isDataUrl = StringTools.startsWith(buf.uri, "data:");
			var bufPath = isDataUrl ? buf.uri : FoxLoaderUtil.filePath(dir + buf.uri);

			var buffer:ByteArray = null;
			if(!isDataUrl) {
				if(!Assets.exists(bufPath)) {
					buffers.push(null);
					trace('[FoxLite > FoxGLTFLoader]: Warning! buffer $i not found! (Loading: $bufPath)');
					continue;
				}
				buffer = Assets.getBytes(bufPath);
				if(buffer == null) {
					trace('[FoxLite > FoxGLTFLoader]: Warning! Could not load buffer $i! (Loading: $bufPath)');
					buffers.push(null);
					continue;
				}
			}
			else { // Load embedded
				var bytes:Bytes = Base64.decode(bufPath.split(',')[1]); 
				buffer = ByteArray.fromBytes(bytes);
			}
			buffers.push(buffer);
		}

		if(false && buffers.filter(f -> f == null).length == buffers.length) {
			trace('[FoxLite > FoxGLTFLoader]: Could not load "$name". (All buffers are missing)');
			return null;
		}

		var data = _processData(name, gltfJson, buffers, extraShaderFlags, customShaderPath);
		for(b in buffers) b.clear(); // Free memory
		return data;
	}

	/**
		Loads models, animations and lights from a GLTF binary file `.glb`. This method is identical to `load()`

		__Note:__ Cache is applied only to foxlite resources such as textures, materials and so on. The gltf aswell as
		its binary buffers will be loaded every time you call this function to refresh the cache if something is missing.
	**/
	public static function loadBinary(name:String, ?extraShaderFlags:Array<String>, ?customShaderPath:String):GLTFData {
		var path = FoxLoaderUtil.filePath(name);
		if(!Assets.exists(path)) {
			trace('[FoxLite > FoxGLTFLoader]: Could not load "$name" (Not found.)');
			return null;
		}
		
		var glb:ByteArray = Assets.getBytes(path);
		if(glb == null) {
			trace('[FoxLite > FoxGLTFLoader]: Could not load "$name" (Load error.)');
			return null;
		}

		// GLB header checks
		if(glb.readUTFBytes(4) != "glTF") {
			trace('[FoxLite > FoxGLTFLoader]: GLB header error! ($name)');
			return null;
		}
		if(glb.readUnsignedInt() < 2) {
			trace('[FoxLite > FoxGLTFLoader]: GLTF version < 2.0 is not supported! ($name)');
			return null;
		}

		// JSON + Binary buffers
		var length:UInt = glb.readUnsignedInt();
		var jsonLength:UInt = glb.readUnsignedInt();
		glb.position += 4; // Skip JSON header

		if(glb.bytesAvailable < jsonLength) {
			trace('[FoxLite > FoxGLTFLoader]: Could not load "$name". Not enough bytes for json chunk. (${glb.bytesAvailable} < $jsonLength)');
			return null;
		}

		var gltfJson:Dynamic = Json.parse(glb.readUTFBytes(jsonLength));
		
		var binLength:UInt = glb.readUnsignedInt(); // embedded .bin size
		glb.position += 4; // Skip BIN header

		if(glb.bytesAvailable < binLength) {
			trace('[FoxLite > FoxGLTFLoader]: Could not load "$name". Not enough bytes for binary buffer. (${glb.bytesAvailable} < $binLength)');
			return null;
		}

		var dataArray = Bytes.alloc(binLength);
		glb.readBytes(dataArray, 0, binLength);

		var buffers:Array<ByteArray> = [dataArray];

		var data = _processData(name, gltfJson, buffers, extraShaderFlags, customShaderPath);
		
		for(b in buffers) b.clear(); // Free memory
		return data;
	}

	@:noCompletion public static function _processData(name:String, gltfJson:Dynamic, buffers:Array<ByteArray>, ?extraShaderFlags:Array<String>, ?customShaderPath:String):GLTFData {
		var directory = Path.directory(name) + '/';
		if(extraShaderFlags == null) extraShaderFlags = [];
		if(customShaderPath == null) customShaderPath = FoxShader.BASIC;

		var accessors:Array<Dynamic> = gltfJson.accessors;
		var bufferViews:Array<Dynamic> = gltfJson.bufferViews;

		var meshes:Array<FoxMesh> = FoxCache.meshes().get(name) ?? [];
		var materials:Map<String, FoxMaterial> = FoxCache.materialLibs().get(name);
		var textures:Array<FoxTexture> = [];
		var materialArray:Array<FoxMaterial> = [];

		function addFlag(f:String) {
			if(!extraShaderFlags.contains(f)) extraShaderFlags.push(f);
		}

		// Preload
		if(gltfJson.textures != null) for(tex in (gltfJson.textures:Array<Dynamic>)) {
			var image:Dynamic = gltfJson.images[tex.source];

			var isBuffer = Std.isOfType(image?.bufferView, Int);
			var isDataUrl = image?.uri != null && StringTools.startsWith(image.uri, "data:");
			
			if(image?.uri != null || isBuffer) {
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

				var texture:FoxTexture = null;
				if(!isBuffer) {
					var imagePath = isDataUrl ? image.uri : FoxLoaderUtil.filePath(directory + Std.string(image.uri));
					texture = FoxTexture.fromImageRaw(imagePath, mipmaps, cast 1, params) ?? FoxRenderer.MISSING_TEXTURE;
				}
				else if(!FoxCache.textures().exists(directory + image.name)) {
					texture = new FoxTexture();
					texture.assetsKey = directory + image.name;
					texture.wrapMode = params.wrapMode;
					texture.filter = params.filter;
					texture.mipFilter = params.mipFilter;
					trace("[FoxLite > FoxGLTFLoader]: Add buffer texture to cache: " + texture.assetsKey);
					FoxCache.textures().set(directory + image.name, texture);

					var view = bufferViews[image.bufferView];
					var buffer = buffers[view.buffer];
					var imageBytes = Bytes.alloc(view.byteLength);
					imageBytes.blit(0, buffer, view.byteOffset, view.byteLength);
					
					Image.loadFromBytes(imageBytes).onComplete(image -> {
						(imageBytes:ByteArray).clear();
						if(image == null) return;
						// Upload image directly to the GPU
						// This method is completely detached from openfl's BitmapData operations
						// Unless we find a better method, we'll stick with this
						texture.glTexture = FoxRenderer.createTextureStorage(image.width, image.height, image.transparent ? "rgba" : "rgb");
						(cast texture.glTexture:Texture).uploadFromTypedArray(image.buffer.data);
					});
				}
				else texture = FoxCache.textures().get(directory + image.name);
				textures.push(texture);
			}
			else textures.push(null);
		}

		if(gltfJson.materials != null && materials == null) {
			materials = new StringMap();
			for(idx=>mat in (gltfJson.materials:Array<Dynamic>)) {
				if(!Std.isOfType(mat.name, String)) mat.name = 'Material.${StringTools.lpad(Std.string(idx), '0', 3)}';
				mat.name = directory + mat.name;
				var material:FoxMaterial = materials?.get(mat.name);

				if(material != null) {
					materialArray.push(material);
					continue;
				}

				material = new FoxMaterial();
				material.assetsKey = mat.name;
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
					var f:Array<Float> = mat.emissiveFactor;
					material.params.set("uEmissive", f.copy());
				}
				else material.params.set("uEmissive", [0, 0, 0]);

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

				if(pbr?.baseColorTexture != null) {
					var tex = textures[pbr.baseColorTexture.index];
					if(tex != null) material.textures.set("bitmap", tex);
					extraShaderFlags.remove("SOLID");
				}
				else addFlag("SOLID");

				// Extensions
				var KHR_materials_specular:Dynamic = mat.extensions?.KHR_materials_specular;
				var KHR_materials_emissive_strength:Dynamic = mat.extensions?.KHR_materials_emissive_strength;

				if(KHR_materials_specular?.specularColorFactor != null) {
					var spec = KHR_materials_specular.specularColorFactor;
					material.setSpecularLevels(spec[0], spec[1], spec[2]);
				}

				var hasEmissiveStrength = Std.isOfType(KHR_materials_emissive_strength?.emissiveStrength, Float) || Std.isOfType(KHR_materials_emissive_strength?.emissiveStrength, Int);
				var em = material.params.get("uEmissive");
				if(em != null) {
					if(hasEmissiveStrength) {
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
			FoxCache.materialLibs().set(name, materials);
		}
		else for(m in materials) materialArray.push(m);

		if(meshes.length == 0) {
			for(mesh in (gltfJson.meshes:Array<Dynamic>)) {
				for(i=>prim in (mesh.primitives:Array<Dynamic>)) {
					var mesh = new FoxMesh();
					var meshAccessors:IntMap<String> = new IntMap();
					var skip = false;

					for(attrib in Reflect.fields(prim.attributes)) meshAccessors.set(Reflect.field(prim.attributes, attrib), attrib.toUpperCase());
					meshAccessors.set(prim.indices, "INDICES");
					
					for(accessorIndex=>attrib in meshAccessors) {
						var accessor:Dynamic = accessors[accessorIndex];
						var view:Dynamic = bufferViews[accessor.bufferView];
						var buffer:ByteArray = buffers[view.buffer];
						if(buffer == null) {
							trace('Warning! Buffer ${view.buffer} not found for mesh $i/$attrib, skipping!');
							skip = true;
							break;
						}

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
							case AccessorComponentType.BYTE: new Int8Array(count);
							case AccessorComponentType.UNSIGNED_BYTE: new UInt8ClampedArray(count);
							case AccessorComponentType.SHORT: new Int16Array(count);
							case AccessorComponentType.UNSIGNED_SHORT: new UInt16Array(count);
							case AccessorComponentType.UNSIGNED_INT: new UInt32Array(count);
							case AccessorComponentType.FLOAT: new Float32Array(count);
							default: null;
						}

						// Write data
						#if js
						var blitBuffer:Bytes = Bytes.ofData(dataArray.buffer);
						#else
						var blitBuffer:Bytes = dataArray.buffer;
						#end

						blitBuffer.blit(0, buffer, (view.byteOffset ?? 0) + (accessor.byteOffset ?? 0), dataArray.byteLength);
						
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
							case "JOINTS_0": {
								mesh.boneIndices = gpuBuffer;
								mesh.boneIndices.__stride = 4; // Fix OpenFL stride bugs
							}
							case "WEIGHTS_0": mesh.boneWeights = gpuBuffer;
							case "COLOR_0": mesh.colorBuffer = gpuBuffer;
							case "INDICES": mesh.indexBuffer = gpuBuffer;
							default: (gpuBuffer:Dynamic)?.dispose(); // In case we have an invalid attribute
						}
					}
					if(skip) break;
					if(Std.isOfType(prim.material, Int)) mesh.material = materialArray[prim.material];
					// TODO: maybe move render mode to mesh instead of material?
					//if(Std.isOfType(prim.mode, Int)) ;
					meshes.push(mesh);
				}
			}
			FoxCache.meshes().set(name, meshes);
		}
		
		var nodes:Array<Dynamic> = gltfJson.nodes;
		var parent:Array<Null<Int>> = [];
		parent.resize(nodes.length);

		// Cache parent indices
		for(i=>node in nodes) if(Std.isOfType(node.children, Array)) for(c in (node.children:Array<Int>)) {
			if(parent[c] != null) trace('Warning! node ${parent[c]} ($c) already has a parent!');
			parent[c] = i;
		}

		var skins:Array<FoxSkinData> = FoxCache.skins().get(name) ?? [];
		// Skinning
		if(gltfJson.skins != null && skins.length == 0) {
			// Temporary vectors for Quaternion -> Euler conversion
			#if foxlite_polymod
			var tempMatrix = new Matrix3D();
			var tempVectors = tempMatrix.decompose().__array;
			#end
			for(skin in (gltfJson.skins:Array<Dynamic>)) {
				var accessor:Dynamic = accessors[skin.inverseBindMatrices];
				var view:Dynamic = bufferViews[accessor.bufferView];
				var buffer:ByteArray = buffers[view.buffer];
				if(buffer == null) {
					trace('Warning! Buffer ${view.buffer} not found for skin ${skin.name}, skipping!');
					break;
				}

				var skinData = new FoxSkinData();

				var gltfJoints:Array<Int> = skin.joints;
				for(idx=>joint in gltfJoints) {
					var inverseMat = new Matrix3D();

					var a = inverseMat.rawData.__array;
					for(i in 0...16) {
						buffer.position = view.byteOffset + (i+idx*16)*4;
						a[i] = buffer.readFloat();
					}
					var bone = new FoxBone(inverseMat);
					var node:Dynamic = nodes[joint];
					bone.name = node.name;
					if(Std.isOfType(node.translation, Array)) bone.setPosition(node.translation[0], node.translation[1], node.translation[2]);
					if(Std.isOfType(node.scale, Array)) bone.setScale(node.scale[0], node.scale[1], node.scale[2]);
					if(Std.isOfType(node.rotation, Array)) {
						#if foxlite_polymod
						// Rotations are stored as quaternions, we have to turn them into euler angles
						tempVectors[1].setTo(node.rotation[0], node.rotation[1], node.rotation[2]);
						tempVectors[1].w = node.rotation[3];

						tempMatrix.recompose(tempVectors, cast 2);
						FoxMathUtil.eulerFromMatrix(tempMatrix, bone.rotation);
						#else
						bone.rotation.setTo(node.rotation[0], node.rotation[1], node.rotation[2]);
						bone.rotation.w = node.rotation[3];
						FoxMathUtil.eulerFromQuaternion(bone.rotation, bone.rotation);
						#end
					}
					skinData.addBone(bone, -1);
					skinData.reparentBoneByName(idx, nodes[parent[joint]]?.name ?? "");
				}
				skins.push(skinData);
			}
			FoxCache.skins().set(name, skins);
		}

		var animations:StringMap<FoxAnimation> = FoxCache.animationLibs().get(name);

		if(gltfJson.animations != null && animations == null) {
			animations = new StringMap();
			for(anim in (gltfJson.animations:Array<Dynamic>)) {
				var animation = new FoxAnimation(anim.name);
				var trackType:FoxTrackType = -1;
				for(channel in (anim.channels:Array<Dynamic>)) {
					var sampler:Dynamic = anim.samplers[channel.sampler];
					var interpolation:FoxEaseType = sampler.interpolation == "STEP" ? FoxEaseType.ZERO : FoxEaseType.LINEAR;
					var node:Dynamic = nodes[channel.target.node];
					var path:String = channel.target.path;

					var accessorIn:Dynamic = accessors[sampler.input];	// Times
					var accessorOut:Dynamic = accessors[sampler.output]; // Values

					var viewIn:Dynamic = bufferViews[accessorIn.bufferView];
					var viewOut:Dynamic = bufferViews[accessorOut.bufferView];

					var bufferIn:ByteArray = buffers[viewIn.buffer];
					var bufferOut:ByteArray = buffers[viewOut.buffer];

					if(bufferIn == null || bufferOut == null) {
						trace('Warning! Buffers ${viewIn.buffer} and/or ${viewOut.buffer} not found for animation track "${node.name}:$path", skipping!');
						if(viewIn.buffer == viewOut.buffer) break;
						else continue;
					}

					animation.duration = Math.max(animation.duration, accessorIn.max[0]);

					trackType = switch(accessorOut.type:String) {
						case "SCALAR": FoxTrackType.FLOAT;
						case "VEC2": FoxTrackType.VECTOR2;
						case "VEC3": FoxTrackType.VECTOR3D;
						case "VEC4": path == "rotation" ? FoxTrackType.QUATERNION : FoxTrackType.VECTOR4;
						//case "MAT2": FoxTrackType.MATRIX2;
						//case "MAT3": FoxTrackType.MATRIX3;
						case "MAT4": FoxTrackType.MATRIX4;
						default: continue;
					};
					
					path = StringTools.replace(path, "translation", "position");
					path = StringTools.replace(path, "rotation", "quaternion"); // We'll be using quat interpolation
					var track:FoxAnimationTrack<Any> = animation.addTrack('${node.name}:$path', trackType);
					for(i in 0...accessorIn.count) {
						bufferIn.position = viewIn.byteOffset + i*4;
						var time:Float = bufferIn.readFloat();
						switch(trackType) {
							case FoxTrackType.FLOAT: {
								bufferOut.position = viewOut.byteOffset + i*4;
								track.addFrame(time, bufferOut.readFloat(), interpolation);
							};
							case FoxTrackType.VECTOR2: {
								bufferOut.position = viewOut.byteOffset + i*8;
								var x = bufferOut.readFloat();
								var y = bufferOut.readFloat();
								track.addFrame(time, new Vector2(x, y), interpolation);
							};
							case FoxTrackType.VECTOR3D: {
								bufferOut.position = viewOut.byteOffset + i*12;
								var x = bufferOut.readFloat();
								var y = bufferOut.readFloat();
								var z = bufferOut.readFloat();
								track.addFrame(time, new Vector3D(x, y, z), interpolation);
							};
							case FoxTrackType.VECTOR4, FoxTrackType.QUATERNION: {
								bufferOut.position = viewOut.byteOffset + i*16;
								var v = new Vector3D(
									bufferOut.readFloat(),
									bufferOut.readFloat(),
									bufferOut.readFloat(),
									bufferOut.readFloat()
								);
								track.addFrame(time, v, interpolation);
							};
							case FoxTrackType.MATRIX4: {
								bufferOut.position = viewOut.byteOffset + i*64;
								var matrix = new Matrix3D();
								var a = matrix.rawData.__array;
								for(i in 0...16) a[i] = bufferOut.readFloat();
								track.addFrame(time, matrix, interpolation);
							};
						}
					}
				}

				animations.set(anim.name, animation);
			}
			FoxCache.animationLibs().set(name, animations);
		}

		return {
			meshes: meshes,
			materials: materials,
			skins: skins,
			animations: animations,
			gltfJson: gltfJson
		};
	}
}