#include "foxlite/inc/material.glsl" // For material data
#include "foxlite/inc/sdf3d.glsl"

// Lighting defines
// Note: - Positions must be in View-Space (view * X)
//		 - Directions must be in Inverse View-Space (invView * X)
// Calculations are made in view-space for future deferred lighting implementation

/*
#define MAX_DIRECTIONAL_LIGHTS 4
#define MAX_POINT_LIGHTS 16
#define MAX_SPOT_LIGHTS 8
#define MAX_AREA_LIGHTS 8

struct DirLight {
	vec4 color;
	vec4 direction;
	int shadowCaster;
};

struct PointLight {
	vec4 color;
	vec4 position;
	int shadowCaster;
};

struct SpotLight {
	vec4 color;
	vec4 position;
	vec4 direction;
	int shadowCaster;
};

struct AreaLight {
	vec4 color;
	vec4 position;
	vec4 direction;
	vec4 sdfData;
	int shadowCaster;
};

uniform DirLight directionalLights[MAX_DIRECTIONAL_LIGHTS]; //  4*3 = 12 vector units
uniform PointLight pointLights[MAX_POINT_LIGHTS];			// 16*3 = 48 vector units
uniform SpotLight spotLights[MAX_SPOT_LIGHTS];				//  8*4 = 32 vector units
uniform AreaLight areaLights[MAX_AREA_LIGHTS];				//  8*5 = 40 vector units
uniform ivec4 lightCount; 									//   +1 = 133 vec4s for lights
															// lightCount: x=directional, y=point, z=spot, w=area


struct ShadowCaster {
	mat4 viewProj;
	vec4 atlasRect;
};

uniform sampler2D shadowCasterData;
uniform float shadowCasterPixelSize;

ShadowCaster getShadowCaster(int idx) {
	int b = idx * 5;
	vec4 c0 = texture2D(shadowCasterData, vec2(float(b  ) * shadowCasterPixelSize, 0));
	vec4 c1 = texture2D(shadowCasterData, vec2(float(b+1) * shadowCasterPixelSize, 0));
	vec4 c2 = texture2D(shadowCasterData, vec2(float(b+2) * shadowCasterPixelSize, 0));
	vec4 c3 = texture2D(shadowCasterData, vec2(float(b+3) * shadowCasterPixelSize, 0));
	vec4 rect = texture2D(shadowCasterData, vec2(float(b+4) * shadowCasterPixelSize, 0));
	return ShadowCaster(mat4(c0, c1, c2, c3), rect);
}
*/

#define MAX_LIGHTS 		  24

#define LIGHT_DIRECTIONAL 0
#define LIGHT_POINT 	  1
#define LIGHT_SPOT 		  2
#define LIGHT_AREA  	  3

#include "foxlite/inc/shadow.glsl"

uniform vec3 ambientLight;

struct FoxLight {
	vec4 color;		// xyz = color, w = range (not applicable for directional light)
	vec4 position;  // xyz = position, w = attenuation (not applicable for directional light)
	vec4 direction; // xyz = direction, w = spot angle (for area lights: w = sdfRange)
	vec4 sdfData; 	// extra data for area lights
};

uniform FoxLight lights[MAX_LIGHTS];	 // 24*4 = 96 vector units for lights
uniform int lightTypes[MAX_LIGHTS];
uniform int lightCount;

// https://dev.to/alex_ricciardi/light-interaction-in-computer-graphics-reflection-and-the-blinn-phong-model-opengl-mc9
float blinnPhong(vec3 lightDirection, vec3 viewPos, vec3 normal, float roughness) {
	vec3 viewDirection = normalize(viewPos);
	// Compute specular component using the Blinn-Phong model
	vec3 halfwayDir = normalize(lightDirection + viewDirection); // H
	float shininess = (1.0 - roughness) * (1.0 - roughness) * 256.0;
	float specularFactor = pow(max(dot(normal, halfwayDir), 0.0), shininess);
	
	return specularFactor;
}

// Custom light functions, outputs Diffuse and Specular factors from view-space

vec2 directionalLight(vec3 lightDir, vec3 viewPos, vec3 normal, float roughness) {
	float diffuse = max(dot(lightDir, normal), 0.0);
	float specular = blinnPhong(lightDir, viewPos, normal, roughness);
	return vec2(diffuse, specular); 
}

vec2 pointLight(vec3 lightPos, float radius, float attenuation, vec3 viewPos, vec3 normal, float roughness) {
	float dist = distance(lightPos.xyz, viewPos) / radius;

	vec3 lightDir = -normalize(lightPos.xyz - viewPos);
	float diffuse = max(dot(lightDir, normal)+uScattering, 0.0);
	float decay = max(1.0 - dist*dist, 0.0);
	float specular = blinnPhong(lightDir, viewPos, normal, roughness);
	
	diffuse *= decay * pow(2.0, 1.0 - attenuation);
	return vec2(diffuse, specular * diffuse);
}

// https://ogldev.org/www/tutorial21/tutorial21.html
vec2 spotLight(vec3 lightPos, vec3 lightDirection, float radius, float angle, float attenuation, vec3 viewPos, vec3 normal, float roughness) {
	vec3 lightDir = -normalize(lightPos - viewPos);
	float spotFactor = dot(lightDir, lightDirection);

	// TODO: Add blur factor: when the cone is closer to the source, blur it less
	spotFactor = step(angle, spotFactor) * clamp((1.0 - (1.0 - spotFactor) * 1.0/(1.0 - angle)) , 0.0, 1.0);
	// Reuse pointLight function since spot is just a constrained version of it
	vec2 omni = pointLight(lightPos, radius, attenuation, viewPos, normal, roughness);
	// Spot blob at surface
	//omni = mix(omni, omni / dist, 0.25);
		
	return min(omni * spotFactor, 2.0);
}

vec2 areaLight(vec3 lightPos, vec3 lightDirection, vec4 sdfData, float range, float attenuation, vec3 viewPos, vec3 normal, float roughness) {
	// Rotation vectors
	mat3 boxBasis = basisFromDirection(lightDirection);

	vec3 boxPos = viewToWorld(lightPos - viewPos);
	boxPos = boxBasis * boxPos;

	float d = getSDF3D(int(sdfData.w), boxPos, sdfData.xyz); // sdBox3D(boxPos, sdfData.xyz);
	float dist = range / max(d, 1.0);
	dist = clamp(dist, 0.0, 1.0);

	vec3 lightDir = -normalize(lightPos.xyz - viewPos);

	float diffuse = max(dot(lightDir, normal)+uScattering, 0.0);
	float decay = max(dist*dist, 0.0);
	float specular = blinnPhong(lightDir, viewPos, normal, roughness);
	
	diffuse *= decay * pow(2.0, 1.0 - attenuation);
	return vec2(diffuse, specular * diffuse);
}	

void addLight(inout vec3 diffuse, inout vec3 specular, vec3 color, vec2 light) {
	#ifdef TOONLIGHT_3
	light = round(light*3.)/3.;
	#elif defined(TOONLIGHT_2)
	light = round(light*2.)/2.;
	#endif
	diffuse += light.s * color;
	specular += light.t * color;
}

vec3 light(vec3 unlit, vec3 normal, vec3 viewPosition, vec3 lightSpecular, float roughness) {
	vec3 diffuse = ambientLight;
	vec3 specular = vec3(0);

	// Dynamic iterator values are not supported in some WebGL implementations...
	// So we do this crappy break check
	
	for(int i = 0; i < MAX_LIGHTS; ++i) {
		if(i >= lightCount) break;
		FoxLight L = lights[i];

		if(lightTypes[i] == LIGHT_DIRECTIONAL) addLight(diffuse, specular, L.color.rgb,
			directionalLight(L.direction.xyz, viewPosition, normal, roughness)
		);
		else if(lightTypes[i] == LIGHT_POINT) addLight(diffuse, specular, L.color.rgb,
			pointLight(L.position.xyz, L.color.w, L.position.w, viewPosition, normal, roughness)
		);
		else if(lightTypes[i] == LIGHT_SPOT) addLight(diffuse, specular, L.color.rgb,
			spotLight(L.position.xyz, L.direction.xyz, L.color.w, L.direction.w, L.position.w, viewPosition, normal, roughness)
		);
		else if(lightTypes[i] == LIGHT_AREA) addLight(diffuse, specular, L.color.rgb,
			areaLight(L.position.xyz, L.direction.xyz, L.sdfData, L.color.w, L.position.w, viewPosition, normal, roughness)
		);
	}

	#ifdef SHADOW_GLSL
	for(int i = 0; i < MAX_SHADOW_LIGHTS; ++i) {
		if(i >= shadowCount) break;
		ShadowLight L = shadowLights[i];
		vec4 lightSpace = shadowLightSpacePos[i];
		
		float shadowF = 1.0;
		if(shadowLightTypes[i] == LIGHT_DIRECTIONAL) {
			#ifndef VERTEX_LIGHTING
			shadowF = shadowDirectional(lightSpace, L.atlasRect);
			#endif
			addLight(diffuse, specular, L.color.rgb, shadowF * directionalLight(L.direction.xyz, viewPosition, normal, roughness));
		}
		else if(shadowLightTypes[i] == LIGHT_POINT) {
			float range = L.color.w;
			#ifndef VERTEX_LIGHTING
			shadowF = shadowPointDual(lightSpace, range, L.atlasRect);
			#endif
			addLight(diffuse, specular, L.color.rgb, shadowF * pointLight(L.position.xyz, range, L.position.w, viewPosition, normal, roughness));
		}
		else if(shadowLightTypes[i] == LIGHT_SPOT) {
			#ifndef VERTEX_LIGHTING
			shadowF = shadowSpot(lightSpace, L.atlasRect);
			#endif
			addLight(diffuse, specular, L.color.rgb, shadowF * spotLight(L.position.xyz, L.direction.xyz, L.color.w, L.direction.w, L.position.w, viewPosition, normal, roughness));
		}
		else if(shadowLightTypes[i] == LIGHT_AREA) {
			#ifndef VERTEX_LIGHTING
			shadowF = shadowPointDual(lightSpace, L.direction.w, L.atlasRect);
			#endif
			addLight(diffuse, specular, L.color.rgb, shadowF * areaLight(L.position.xyz, L.direction.xyz, L.sdfData, L.color.w, L.position.w, viewPosition, normal, roughness));
		}
	}
	#endif

	unlit *= diffuse;
	return unlit + specular * lightSpecular;
}