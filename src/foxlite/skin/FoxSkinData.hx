package foxlite.skin;

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
	public var boneData:Float32Array;
	public var assetsKey:String;

	public function new() {}

	public function addBone(bone:FoxBone, parentIndex:Int=-1) {
		bone.parent = bones[parentIndex] ?? root;
		bone.parentIndex = parentIndex;
		bones.push(bone);
	}

	public inline function removeBone(bone:FoxBone) {
		if(bones.length > 0 && bone != null) bones.remove(bone);
	}

	public inline function removeBoneByIndex(index:Int) {
		removeBone(bones[index]);
	}

	public inline function getBoneByName(name:String):FoxBone {
		for(b in bones) if(b.name == name) return b; 
		return null;
	}

	public function update(dt:Float) {
		// Update allocation
		var w = bones.length * 16; // 16 floats per bone
		if(boneData?.length != w) reallocate(w);

		for(i => bone in bones.keyValueIterator()) {
			bone.update(dt); // Calculate transform
			setTransformAt(i*16, bone.transform); // Write transform 
		}
	}

	public function setTransformAt(pos:Int, matrix:Matrix3D) {
		var bytes:Bytes = #if !foxlite_polymod cast #end boneData.buffer;
		var array = matrix.rawData.__array;
		for(i in 0...16) {
			#if (js || !foxlite_polymod)
			boneData[pos+i] = array[i];
			#else
			bytes.setFloat((pos+i)<<1, array[i]);
			#end
		}
	}

	private function reallocate(size:Int) {
		var mem:Array<Float> = new Array();
		mem.resize(size);
		boneData = TypedArray.Float32Array(mem);
	}

	public static function loadJSON(name:String):FoxSkinData {
		if(!Assets.exists(name)) return null;
		var data:Array<Dynamic> = Json.parse(Assets.getText(name));
		var skin = new FoxSkinData();
		skin.assetsKey = name;

		for(bd in data) {
			var pose = bd.pose;
			var rest = new Matrix3D(VectorFactory.Float(bd.rest));
			var bone = new FoxBone(rest);
			bone.name = bd.name;
			
			if(pose?.position != null) bone.position.setTo(bd.pose.position[0], bd.pose.position[1], bd.pose.position[2]);
			if(pose?.rotation != null) bone.rotation.setTo(bd.pose.rotation[0], bd.pose.rotation[1], bd.pose.rotation[2]);
			if(pose?.scale != null) bone.scale.setTo(bd.pose.scale[0], bd.pose.scale[1], bd.pose.scale[2]);
			skin.addBone(bone, bd.parent);
		}

		return skin;
	}
}
