package foxlite.loaders;

import foxlite.animation.data.FoxTrackData;
import Reflect;
import Array;
import foxlite.animation.FoxAnimation;
import foxlite.animation.FoxTrackType;
import foxlite.animation.FoxAnimationTrack;
import foxlite.animation.FoxEaseType;
import foxlite.skin.FoxSkinData;
import foxlite.skin.FoxBone;
import foxlite.polyfill.VectorFactory;
import foxlite.FoxCache;
import foxlite.loaders.FoxLoaderUtil;
import foxlite.material.FoxMaterial;
import foxlite.mesh.FoxMesh;
import haxe.Json;
import haxe.ds.StringMap;
import openfl.geom.Matrix3D;

class FoxJSONLoader {
	
	/**
		Loads a model and material from their foxlite `.json` file.
	**/
	public static function loadModel(name:String):{meshes:Array<FoxMesh>, materials:Map<String, FoxMaterial>} {
		// Check cache
		if(FoxCache.meshes().exists(name)) {
			var meshes = FoxCache.meshes().get(name);
			var materials:Map<String, FoxMaterial> = new StringMap();
			for(m in meshes) {
				if(!materials.exists(m.material.name)) materials.set(m.material.name, m.material);
			}
			return {meshes:meshes, materials: materials};
		}
		
		var modelData:Array<Dynamic> = FoxLoaderUtil.loadJSON(name);
		if((modelData?.length ?? 0) == 0) return null;

		var meshes:Array<FoxMesh> = [];
		var materials:Map<String, FoxMaterial> = new StringMap();

		var path:String = FoxLoaderUtil.path(name);

		for(model in modelData) {
			var material:FoxMaterial = null;
			if(model.material != null) {
				trace("[FoxLite > FoxJSONLoader]: Loading material file: " + model.material.split(":")[0]);
				material = FoxMaterial.fromJSON(path + model.material); // Adds to cache automatically
				if(material == null) {
					trace("[FoxLite > FoxMaterial]: Warning: material not found!! " + model.material);
				}
				else materials.set(material.name, material);
			}

			var mesh = new FoxMesh();
			mesh.setArrays(model.vertices, model.uvtData, model.indices, material, model.normals, model.colors, model.weights, model.influences);
			mesh.assetsKey = name;
			meshes.push(mesh);
		}

		FoxCache.meshes().set(name, meshes);

		return {meshes:meshes, materials: materials};
	}

	/**
		Loads skin data from a `.json` file.

		The skin data contains the bone structure to animate models.

		__Note:__ This resource is not cached, use `FoxSkinData.copy()` instead.
	**/
	public static function loadSkinData(name:String):FoxSkinData {
		var data:Array<Dynamic> = Json.parse(FoxLoaderUtil.loadText(name));
		if(data == null) return null;
		
		var skin = new FoxSkinData();
		skin.assetsKey = name;

		for(bd in data) {
			var rest = new Matrix3D(VectorFactory.Float(bd.rest));
			var bone = new FoxBone(rest);
			bone.name = bd.name;
			
			if(bd.pose != null) {
				var pose = bd.pose;
				if(Std.isOfType(pose?.position, Array)) bone.position.setTo(bd.pose.position[0], bd.pose.position[1], bd.pose.position[2]);
				if(Std.isOfType(pose?.rotation, Array)) bone.rotation.setTo(bd.pose.rotation[0], bd.pose.rotation[1], bd.pose.rotation[2]);
				if(Std.isOfType(pose?.scale, Array)) bone.scale.setTo(bd.pose.scale[0], bd.pose.scale[1], bd.pose.scale[2]);
			}
			skin.addBone(bone, bd.parent);
		}

		return skin;
	}

	/**
		Loads an animation collection from a `.json` file
	**/
	public static function loadAnimationLibrary(name:String):Map<String, FoxAnimation> {
		if(FoxCache.animationLibs().exists(name)) {
			return FoxCache.animationLibs().get(name);
		}

		var animData:Dynamic = FoxLoaderUtil.loadJSON(name);
		if(animData == null) return null;

		var map:Map<String, FoxAnimation> = new StringMap();

		for(animName in Reflect.fields(animData)) {
			var data:Dynamic = Reflect.field(animData, animName);
			var anim = new FoxAnimation(animName);

			var useMaxFrameTimes:Bool = false;

			if(Std.isOfType(data.duration, Float) || Std.isOfType(data.duration, Int)) anim.duration = Math.max(data.duration, 0);
			else {
				trace('[FoxLite > FoxJSONLoader]: Warning! Animation "$animName" duration is invalid. Keyframe times will be used instead.');
				useMaxFrameTimes = true;
			}
			if(Std.isOfType(data.loop, Bool)) anim.loop = data.loop;

			for(trackName in Reflect.fields(data.tracks)) {
				var tData:Dynamic = Reflect.field(data.tracks, trackName);
				var tType:Int = Std.isOfType(tData.type, String) ? FoxTrackType.fromString(tData.type) : (Std.isOfType(tData.type, Int) || Std.isOfType(tData.type, Float) ? Std.int(tData.type) : -1);
				if(tType < 0) {
					trace('[FoxLite > FoxJSONLoader]: Warning! Track "$trackName" of animation "$animName" has an invalid type, skipping.');
					continue;
				}
				var track:FoxAnimationTrack<Any> = anim.addTrack(trackName, tType);
				if(Std.isOfType(tData.frames, Array)) {
					final stride = 3;
					var idx = 0;
					var arr:Array<Dynamic> = tData.frames;
					while(idx < arr.length) {
						var e:Dynamic = arr[idx+2];
						var easing:Int = Std.isOfType(e, String) ? FoxEaseType.fromString(e) : (Std.isOfType(e, Int) || Std.isOfType(e, Float) ? Std.int(e) : FoxEaseType.LINEAR);
						track.addFrame(arr[idx], FoxTrackData.getValueForType(tType, arr[idx+1]), easing);
						if(useMaxFrameTimes)
							anim.duration = Math.max(anim.duration, arr[idx]);
						
						idx += stride;
					}
				}
			}
			map.set(animName, anim);
		}

		FoxCache.animationLibs().set(name, map);

		return map;
	}
}