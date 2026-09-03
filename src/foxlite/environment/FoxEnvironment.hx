package foxlite.environment;

import foxlite.material.FoxMaterial;
import foxlite.texture.FoxTexture;
import foxlite.FoxCamera;
import lime.math.Vector2;
import flixel.util.FlxColor;

class FoxEnvironment {
	public var fogColor:FlxColor = 0xFF000000;
	public var fogStart:Float = 1;
	public var fogEnd:Float = 10;
	public var ambientLight:FlxColor = 0xFFFFFFFF;
	public var skyOffset:Vector2 = new Vector2();
	public var skyTexture:FoxTexture;

	public function new() {}

	public function setEnvironment(material:FoxMaterial, shader:FoxShader, camera:FoxCamera) {
		if(skyTexture != null) {
			shader.setVector2("skyOffset", skyOffset);
			shader.setSampler2D("skyTexture", skyTexture);
		}
		else shader.textureInput.remove('skyTexture');
		
		if(shader.uniformCache.exists("fogColor")) {
			shader.setFloatArray("fogColor", [fogColor.redFloat, fogColor.greenFloat, fogColor.blueFloat, fogColor.alphaFloat]);
			shader.setFloat("fogStart", fogStart);
			shader.setFloat("fogEnd", fogEnd);
		}
		
		shader.setFloatArray("ambientLight", [ambientLight.redFloat, ambientLight.greenFloat, ambientLight.blueFloat]);
	}

	public function destroy() {
		skyTexture = null;
	}
}
