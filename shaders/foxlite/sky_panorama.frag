#define SKY_PANORAMA_FRAG
#include "foxlite/inc/foxlite.glsl"
#include "foxlite/inc/material.glsl"
#include "foxlite/inc/sky.glsl"      // For worldDirection and sky funcs

void main() {
	vec3 skyColor = panoramaSky(skyTexture, normalize(worldDirection));
	gl_FragColor = vec4(skyColor, 1);
}