package foxlite.skin;

import foxlite.loaders.FoxJSONLoader;
import foxlite.texture.FoxTextureBuffer;
import foxlite.FoxObject;
import foxlite.polyfill.TypedArray;
import foxlite.polyfill.VectorFactory;
import foxlite.skin.FoxBone;
import haxe.Json;
import haxe.io.Bytes;
import lime.utils.Float32Array;
import openfl.geom.Matrix3D;
import openfl.utils.Assets;

class FoxSkinData {

	public final root:FoxObject = new FoxObject(); // Holder transform
	public var bones:Array<FoxBone> = [];
	public var boneData:FoxTextureBuffer = new FoxTextureBuffer(4, 4);
	public var assetsKey:String;

	// Temporary Matrix3D for joint -> rest space conversion
	var __tempMatrix:Matrix3D = new Matrix3D();

	public function new() {}

	public function addBone(bone:FoxBone, parentIndex:Int=-1) {
		bone.parent = bones[parentIndex] ?? root;
		bone.parentIndex = parentIndex;
		bones.push(bone);
	}

	public function removeBone(bone:FoxBone) {
		if(bones.length > 0 && bone != null) bones.remove(bone);
	}

	public function removeBoneByIndex(index:Int) {
		removeBone(bones[index]);
	}

	public function getBoneByName(name:String):FoxBone {
		for(b in bones) if(b.name == name) return b; 
		return null;
	}

	public function reparentBone(boneIndex:Int, parentIndex:Int=-1) {
		var bone:FoxBone = bones[boneIndex];
		bone.parent = bones[parentIndex] ?? root;
		bone.parentIndex = parentIndex;
	}

	public function reparentBoneByName(boneIndex:Int, parentName:String) {
		var bone:FoxBone = bones[boneIndex];
		var parent:FoxBone = getBoneByName(parentName);
		bone.parent = parent ?? root;
		bone.parentIndex = bones.indexOf(parent);
	}

	public function update(dt:Float) {
		// Update allocation
		var w = bones.length*4;
		if(w == 0) return;
		if(boneData.getLength() != w) {
			boneData.create(w, 4); // reallocate
		}

		for(i => bone in bones.keyValueIterator()) {
			bone.update(dt); // Calculate transform
			// Joint to Rest
			__tempMatrix.copyRawDataFrom(bone.transform.rawData);
			__tempMatrix.prepend(bone.rest); // joint * restInverse
			boneData.setMatrix4(i*16, __tempMatrix); // Write transform
		}
		boneData.updateGPU();
	}

	/**
		Copies this skin data (bones and transforms) to a new instance

		Note that `bonesData` (the texture buffer) will be allocated on its own based on
		the current bones array in the next frame.
		If you need to, you can allocate it right away by calling `update(0)`
	**/
	public function copy():FoxSkinData {
		var data = new FoxSkinData();
		data.root.copyComponentsFrom(root);
		for(bone in bones) {
			var newBone = new FoxBone(bone.rest.clone());
			newBone.copyComponentsFrom(bone);
			data.addBone(newBone, bone.parentIndex);
		}
		return data;
	}

	public inline static function fromJSON(name:String):FoxSkinData {
		return FoxJSONLoader.loadSkinData(name);
	}

	public function destroy() {
		for(b in bones) b.destroy();
		bones = null;
		boneData.destroy();
		FoxCache.skins().remove(assetsKey);
	}
}
