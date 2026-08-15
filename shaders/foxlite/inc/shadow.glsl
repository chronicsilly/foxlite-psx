#ifndef SHADOW_GLSL
#define SHADOW_GLSL

#define SHADOW_BIAS 0.00015

uniform sampler2D shadowCasterData;
uniform float shadowCasterPixelSize;

uniform sampler2D shadowtex0; // Directional light shadow atlas
uniform samplerCube shadowtex1; // wip - Point light shadow cubemap
uniform sampler2D shadowtex2; // Spot light shadow atlas
uniform samplerCube shadowtex3; // wip - Area light shadow cubemap

uniform vec2 shadowtex0size;
uniform vec2 shadowtex2size;

varying vec4 directionalShadowLightSpace[MAX_DIRECTIONAL_LIGHTS];
varying vec4 pointShadowLightSpace[1];
varying vec4 spotShadowLightSpace[MAX_SPOT_LIGHTS];
varying vec4 areaShadowLightSpace[1];

// For shadow clipping
#define outsideBounds(v) any(bvec2(any(lessThan(v, vec2(0))), any(greaterThan(v, vec2(1)))))

#ifdef VERTEX
void setupShadows(vec4 worldPosition) {

	for(int i = 0; i < MAX_DIRECTIONAL_LIGHTS; ++i) {
		if(i >= lightCount[LIGHT_DIRECTIONAL]) break;
		DirLight L = directionalLights[i];
		if(L.shadowCaster != -1) {
			mat4 viewProjection = fox_textureBufferMat4(shadowCasterData, L.shadowCaster, shadowCasterPixelSize);
			directionalShadowLightSpace[i] = viewProjection * worldPosition;
			directionalShadowLightSpace[i].xyz = directionalShadowLightSpace[i].xyz * 0.5 + 0.5;
			directionalShadowLightSpace[i].z -= max(shadowtex0size.x, shadowtex0size.y)*.333333333;
		}
	}

	for(int i = 0; i < 1; ++i) {
		if(i >= lightCount[LIGHT_POINT]) break;
		PointLight L = pointLights[i];
		if(L.shadowCaster != -1) {
			mat4 viewProjection = fox_textureBufferMat4(shadowCasterData, L.shadowCaster, shadowCasterPixelSize);
			pointShadowLightSpace[i] = viewProjection * worldPosition;
		}
	}

	for(int i = 0; i < MAX_SPOT_LIGHTS; ++i) {
		if(i >= lightCount[LIGHT_SPOT]) break;
		SpotLight L = spotLights[i];
		if(L.shadowCaster != -1) {
			mat4 viewProjection = fox_textureBufferMat4(shadowCasterData, L.shadowCaster, shadowCasterPixelSize);
			spotShadowLightSpace[i] = viewProjection * worldPosition;
		}
	}

	for(int i = 0; i < 1; ++i) {
		if(i >= lightCount[LIGHT_AREA]) break;
		AreaLight L = areaLights[i];
		if(L.shadowCaster != -1) {
			mat4 viewProjection = fox_textureBufferMat4(shadowCasterData, L.shadowCaster, shadowCasterPixelSize);
			areaShadowLightSpace[i] = viewProjection * worldPosition;
		}
	}

}
#endif

float sampleShadow(sampler2D tex, vec2 coord, float Z) {
	return step(texture2D(tex, coord).r, Z);
}

// For any custom implementations, use along SHADOW_FILTER_CUSTOM
float sampleShadowCustom(sampler2D tex, vec2 coord, float Z, vec2 S);

// Based on https://www.shadertoy.com/view/lsfGWn
float sampleShadowPoisson18(sampler2D tex, vec2 coord, float Z, vec2 S) {
	float pDepth = 0.0;
	float a = interleavedGradientNoise(ScreenCoord) * 6.28;
	vec2 sc = vec2(sin(a),cos(a));
	vec4 B = vec4(sc.y, sc.x, -sc.x, sc.y);
	S *= 2.5;

	// Unrolled for OpenGL ES 2
	const float NUM_TAPS = 18.0;
	vec2 ofs, texcoord;
	ofs = vec2(-0.220147, 0.976896); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2(-0.735514, 0.693436); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2(-0.200476, 0.310353); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2( 0.180822, 0.454146); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2( 0.292754, 0.937414); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2( 0.564255, 0.207879); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2( 0.178031, 0.024583); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2( 0.613912,-0.205936); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2(-0.385540,-0.070092); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2( 0.962838, 0.378319); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2(-0.886362, 0.032122); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2(-0.466531,-0.741458); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2( 0.006773,-0.574796); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2(-0.739828,-0.410584); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2( 0.590785,-0.697557); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2(-0.081436,-0.963262); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2( 1.000000,-0.100160); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);
	ofs = vec2( 0.622430, 0.680868); ofs = vec2( dot(ofs,B.xy), dot(ofs,B.zw) ) * S; texcoord = coord + ofs;
	pDepth += step(texture2D(tex, texcoord).r, Z);

	return pDepth / NUM_TAPS;
}

float shadowDirectional(in vec4 projCoords, const vec4 rect) {
	//vec3 projCoords = S.xyz;
	float shadow = 1.0;
	if(!outsideBounds(projCoords.xy)) {
		vec2 coord = mix(rect.xy, rect.zw, projCoords.xy); // Atlas rect
		
		#ifdef SHADOW_FILTER_NONE
		shadow -= sampleShadow(shadowtex0, coord, projCoords.z);
		#elif defined(SHADOW_FILTER_CUSTOM)
		shadow -= sampleShadowCustom(shadowtex0, coord, projCoords.z, shadowtex0size);
		#else
		shadow -= sampleShadowPoisson18(shadowtex0, coord, projCoords.z, shadowtex0size*0.6);
		#endif
	}
	return shadow;
}

float shadowSpot(in vec4 S, const vec4 rect) {
	vec3 projCoords = S.xyz / S.w;
	projCoords = projCoords * 0.5 + 0.5;
	projCoords.z -= SHADOW_BIAS;

	float shadow = 1.0;
	if(!outsideBounds(projCoords.xy)) {
		vec2 coord = mix(rect.xy, rect.zw, projCoords.xy); // Atlas rect
		
		#ifdef SHADOW_FILTER_NONE
		shadow -= sampleShadow(shadowtex2, coord, projCoords.z);
		#elif defined(SHADOW_FILTER_CUSTOM)
		shadow -= sampleShadowCustom(shadowtex2, coord, projCoords.z, shadowtex2size);
		#else
		shadow -= sampleShadowPoisson18(shadowtex2, coord, projCoords.z, shadowtex2size);
		#endif
	}
	return shadow;
}

float shadowPointCubemap(in vec4 S) {
	return 0.0;
}

float shadowArea(in vec4 S) {
	return 0.0;
}
#endif
