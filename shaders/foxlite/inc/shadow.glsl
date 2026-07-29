#ifndef SHADOW_GLSL
#define SHADOW_GLSL

#define SHADOW_BIAS 0.00015
#define MAX_SHADOW_LIGHTS 8

struct ShadowLight {
	vec4 color;		// xyz = color, w = range (not applicable for directional light)
	vec4 position;  // xyz = position, w = attenuation (not applicable for directional light)
	vec4 direction; // xyz = direction, w = spot angle (for area lights: w = sdfRange)
	vec4 sdfData; 	// extra data for sdf
	
	mat4 viewProjection;   // Light VP for shadow calculation (or hemisphere for point lights)
	vec4 atlasRect;	// Shadowmap atlas region (width x 2 for point lights)
};

uniform ShadowLight shadowLights[MAX_SHADOW_LIGHTS];
uniform int shadowLightTypes[MAX_SHADOW_LIGHTS];
uniform int shadowCount;

uniform sampler2D shadowtex0; // Directional light shadow atlas
uniform sampler2D shadowtex1; // Point light (and area lights) shadow atlas
uniform sampler2D shadowtex2; // Spot light shadow atlas

uniform vec2 shadowtexelsize[3];

// The light type that's currently being used for the shadow shader
uniform int currentLightType;

varying vec4 shadowLightSpacePos[MAX_SHADOW_LIGHTS];
varying float shadowDistortW;
varying float shadowDistortClip;

// For shadow clipping
#define outsideBounds(v) any(bvec2(any(lessThan(v, vec2(0))), any(greaterThan(v, vec2(1)))))
#define nonZero(v) any(notEqual(v, vec4(0)))

// Based on https://github.com/shaderLABS/Shadow-Tutorial
#define SHADOW_DISTORT_FACTOR 0.1
vec3 distortShadow(vec3 pos) {
	float factor = length(pos.xy) + SHADOW_DISTORT_FACTOR;
	return vec3(pos.xy / factor, pos.z*.5);
}

float distortShadowBias(vec3 pos, float texelSize) {
	//square(length(pos.xy) + SHADOW_DISTORT_FACTOR) / SHADOW_DISTORT_FACTOR
	float numerator = length(pos.xy) + SHADOW_DISTORT_FACTOR;
	numerator *= numerator;
	return SHADOW_BIAS * texelSize * numerator / SHADOW_DISTORT_FACTOR;
}

vec4 dualParaboloid(vec4 viewPos, vec2 clip, float flip) {
	viewPos.z *= flip;
	// Distance from the origin, this is our depth
	float dist = length(viewPos.xyz);
	vec3 dir = viewPos.xyz / dist; // Direction vector
	
	// Paraboloid projection: y = 1 - x^2 - z^2
	dir.xy /= dir.z + 1.0;

	// Map depth into [NEAR, FAR] range linearly based on distance
	dir.z = (dist - clip.s) / (clip.t - clip.s);

	// Varyings for fragment
	#if defined(VERTEX) && defined(SHADOW_PASS)
	shadowDistortClip = viewPos.z;
	shadowDistortW = 1.0 / dist;
	#endif

	return vec4(dir.xy, dir.z, 1.0);
}

#ifdef VERTEX
void setupShadows(vec4 worldPosition) {
	for(int i = 0; i < MAX_SHADOW_LIGHTS; ++i) {
		if(i >= shadowCount) break;
		ShadowLight L = shadowLights[i];
		shadowLightSpacePos[i] = L.viewProjection * worldPosition; // To shadow NDC

		if(shadowLightTypes[i] == LIGHT_DIRECTIONAL) {
			// For directional lights we can do this here, saving some performance
			shadowLightSpacePos[i].xyz = shadowLightSpacePos[i].xyz * 0.5 + 0.5;
			shadowLightSpacePos[i].z -= max(shadowtexelsize[0].x, shadowtexelsize[0].y)/3.;
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
		shadow -= sampleShadowCustom(shadowtex0, coord, projCoords.z, shadowtexelsize[0]);
		#else
		shadow -= sampleShadowPoisson18(shadowtex0, coord, projCoords.z, shadowtexelsize[0]*0.6);
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
		shadow -= sampleShadowCustom(shadowtex2, coord, projCoords.z, shadowtexelsize[2]);
		#else
		shadow -= sampleShadowPoisson18(shadowtex2, coord, projCoords.z, shadowtexelsize[2]);
		#endif
	}
	return shadow;
}

// Dual paraboloid shadows, for Point lights
float shadowPointDual(in vec4 S, float range, vec4 rect) {
	float Z = sign(S.z);
	vec3 projCoords = dualParaboloid(S, vec2(0.05, range), Z).xyz;
	projCoords = projCoords * 0.5 + 0.5;
	projCoords.z -= SHADOW_BIAS;

	float shadow = 1.0;
	if(!outsideBounds(projCoords.xy)) {
		rect.xz += mix(rect.z - rect.x, 0.0, step(0.0, S.z)); // S.z < 0.0 ? 0.0 : 1.0;
		vec2 coord = mix(rect.xy, rect.zw, projCoords.xy); // Atlas rect

		#ifdef SHADOW_FILTER_NONE
		shadow -= sampleShadow(shadowtex1, coord, projCoords.z);
		#elif defined(SHADOW_FILTER_CUSTOM)
		shadow -= sampleShadowCustom(shadowtex1, coord, projCoords.z, shadowtexelsize[1]);
		#else
		shadow -= sampleShadowPoisson18(shadowtex1, coord, projCoords.z, shadowtexelsize[1]);
		#endif
	}

	return shadow;
}

float shadowPointCubemap(in vec4 S) {
	return 0.0;
}

float shadowArea() {
	return 0.0;
}
#endif
