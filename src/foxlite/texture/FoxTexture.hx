package foxlite.texture;

import foxlite.FoxCache;
import foxlite.loaders.FoxLoaderUtil;
import foxlite.renderer.FoxRenderer;
import foxlite.texture.FoxMipFilter;
import foxlite.texture.FoxTextureFilter;
import foxlite.texture.FoxWrapMode;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.textures.TextureBase;

class FoxTexture {
	public var context:Context3D = null;

	public var wrapMode:FoxWrapMode = FoxWrapMode.CLAMP;
	public var filter:FoxTextureFilter = FoxTextureFilter.LINEAR;
	public var mipFilter:FoxMipFilter = FoxMipFilter.MIPNONE;
	public var glTexture:TextureBase; // Fix C++ black textures via downcast
	public var assetsKey:String;

	public var width(get, default):Int;
	public var height(get, default):Int;

	private function get_width():Int {
		return glTexture?.__width ?? 0;
	}

	private function get_height():Int {
		return glTexture?.__height ?? 0;
	}

	// Used to store information when resizing
	// If the texture was loaded from a file, it cannot be resized
	private var __format:String = null;
	private var __type:String = null;

	public function new() {
		FoxRenderer.allocationsThisFrame += 1;
		context = FoxRenderer.getContext();
	}

	public function asBitmapData():BitmapData {
		return BitmapData.fromTexture(glTexture);
	}

	// Copies this texture object, does not create new data on GPU
	public function copy():FoxTexture {
		var tex = new FoxTexture();
		tex.wrapMode = wrapMode;
		tex.filter = filter;
		tex.mipFilter = mipFilter;
		tex.glTexture = tex.glTexture;
		return tex;
	}

	public function generateMipmaps() {
		FoxRenderer.generateMipmap(context, this);
	}

	/**
		Resizes this texture. Intended for framebuffer textures,

		__Note:__ This will not work with textures that have been wrapped/loaded from a file.
	**/
	public function resize(width:Int, height:Int):FoxTexture {
		if(__format == null || __type == null) {
			trace("[FoxLite > FoxTexture]: Wrapped/Loaded textures cannot be resized!!!");
			return this;
		}
		glTexture?.dispose();
		glTexture = FoxRenderer.createTextureStorage(width, height, __format, __type);
		return this;
	}

	/**
		Instance version of `FoxTexture.wrap()`

		Takes a `BitmapData` and sets it as the GPU texture

		__Note:__ This will not update any extra information of this texture, such as format or type.
	**/
	public function take(bitmap:BitmapData) {
		if(bitmap.__texture == null) bitmap.getTexture(context);
		glTexture = bitmap.__texture;
	}

	/**
		Instance version of `FoxTexture.wrapGL()`

		Takes a `Texture` and sets it as the GPU texture

		__Note:__ This will not update any extra information of this texture, such as format or type.
	**/
	public function takeGL(texture:TextureBase) {
		glTexture = texture;
	}

	public function destroy() {
		glTexture?.dispose();
		if(assetsKey != null) FoxCache.textures().remove(assetsKey);
		glTexture = null;
	}

	public static function fromBitmapData(data:BitmapData, format:Context3DTextureFormat=#if !foxlite_polymod Context3DTextureFormat.BGRA #else 1 #end, mipmaps:Bool=false, ?params:{?wrapMode:FoxWrapMode, ?filter:FoxTextureFilter, ?mipFilter:FoxMipFilter}):FoxTexture {
		if(data == null) return null;
		// TODO: Add compressed textures
		var tex = FoxRenderer.getContext().createTexture(data.width, data.height, format, false);
		tex.uploadFromBitmapData(data, 0, mipmaps);

		var foxTex = new FoxTexture();
		foxTex.glTexture = tex;
		if(params != null) {
			foxTex.wrapMode = params.wrapMode ?? FoxWrapMode.CLAMP;
			foxTex.filter = params.filter ?? FoxTextureFilter.LINEAR;
			foxTex.mipFilter = params.mipFilter ?? FoxMipFilter.MIPNONE;
		}
		return foxTex;
	}

	public static function fromImage(name:String, mipmaps:Bool=false, format:Context3DTextureFormat=#if !foxlite_polymod Context3DTextureFormat.BGRA #else 1 #end, ?params:{?wrapMode:FoxWrapMode, ?filter:FoxTextureFilter, ?mipFilter:FoxMipFilter}):FoxTexture {
		if(FoxCache.textures().exists(name)) return FoxCache.textures().get(name);
		
		var path = FoxLoaderUtil.imagePath(name);
		if(!Assets.exists(path)) {
			trace('[Foxlite > FoxTexture]: Could not load image: ${path} (Not found.)');
			return null;
		}

		var data = Assets.getBitmapData(path);
		if(data == null) {
			trace('[Foxlite > FoxTexture]: Could not load image: ${path} (BitmapData error.)');
			return null;
		}
		
		var foxTex = FoxTexture.fromBitmapData(data, format, mipmaps, params);
		foxTex.assetsKey = name;
		trace("[FoxLite > FoxTexture]: Add texture to cache: " + name);
		FoxCache.textures().set(name, foxTex);
		data.dispose(); // Cleanup in CPU
		return foxTex;
	}

	// TODO: DXT and ASTC texture support
	//public static function fromImageCompressed(name:String, ?mipmaps:Bool, ?format:Int, ?params):FoxTexture {}

	/*
	* Create on GPU
	*/
	public static function create(width:Int, height:Int, format:String="rgba", type:String="unsigned_byte"):FoxTexture {
		var tex = FoxTexture.wrapGL(FoxRenderer.createTextureStorage(width, height, format, type));
		tex.__format = format.toUpperCase();
		tex.__type = type.toUpperCase();
		return tex;
	}

	/**
		Lighter version of fromBitmapData()
	
		Note: Use this **if** the bitmap data **already has a GPU texture attached** to it.
	*/
	public static function wrap(bitmap:BitmapData):FoxTexture {
		var texture = new FoxTexture();
		texture.take(bitmap);
		return texture;
	}

	/*
	* For wrapping GLTextures 
	*/
	public static function wrapGL(glTexture:TextureBase):FoxTexture {
		var texture = new FoxTexture();
		texture.glTexture = glTexture;
		return texture;
	}

}