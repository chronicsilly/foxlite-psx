// Skinning

// Standard FBX bones-per-vertex count
attribute vec4 foxlite_BoneWeight;
attribute vec4 foxlite_BoneIndex;

uniform sampler2D BONESDATA;
uniform float BONESDATA_PIXEL_SIZE;

uniform bool uSkinned;

mat4 skin() {
	ivec4 index = ivec4(foxlite_BoneIndex);
	
	mat4 transform =
		fox_textureBufferMat4(BONESDATA, index.x, BONESDATA_PIXEL_SIZE) * foxlite_BoneWeight.x +
		fox_textureBufferMat4(BONESDATA, index.y, BONESDATA_PIXEL_SIZE) * foxlite_BoneWeight.y +
		fox_textureBufferMat4(BONESDATA, index.z, BONESDATA_PIXEL_SIZE) * foxlite_BoneWeight.z +
		fox_textureBufferMat4(BONESDATA, index.w, BONESDATA_PIXEL_SIZE) * foxlite_BoneWeight.w;

	return transform;
}