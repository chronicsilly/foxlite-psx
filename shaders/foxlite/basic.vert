
#define BASIC_LIGHTING_VERT
#include "foxlite/inc/foxlite.glsl"
#include "foxlite/inc/mesh.glsl"
#include "foxlite/inc/material.glsl"
#include "foxlite/inc/lighting.glsl"
#include "foxlite/inc/sky.glsl"      // For worldDirection and sky reflections
#include "foxlite/inc/armature.glsl"

void main(void)
{
	foxlite_TexCoordv = foxlite_TexCoord * uvScale + uvOffset;
	foxlite_Colorv = foxlite_Color * color;
	
	mat4 worldTransform = model;

	if(uInstanced) {
		foxlite_Colorv *= foxlite_InstanceColor;
		worldTransform = worldTransform * foxlite_InstanceTransform;
	}

	#if defined(BILLBOARD)
	if(uSkinned) worldTransform = worldTransform * skin();
	
	mat4 fmodelView = view * worldTransform;
	#ifdef BILLBOARD_KEEP_SCALE
	vec3 scale = vec3(
		length(vec3(worldTransform[0])),
		length(vec3(worldTransform[1])),
		length(vec3(worldTransform[2]))
	);
	#else
	const vec3 scale = vec3(1);
	#endif
	fmodelView[0] = vec4(scale.x, 0.0, 0.0, 0.0); // right
    fmodelView[1] = vec4(0.0, scale.y, 0.0, 0.0); // up
    fmodelView[2] = vec4(0.0, 0.0, scale.z, 0.0); // forward

	#elif defined(BILLBOARD_Y)

	if(uSkinned) worldTransform = worldTransform * skin();

	vec3 right   = normalize(vec3(view[0][0], view[1][0], view[2][0]));
    const vec3 up = vec3(0.0, 1.0, 0.0);  // locked to world Y
    vec3 forward = normalize(cross(right, up));
	right = normalize(cross(up, forward)); // reorthogonalize
	
	#ifdef BILLBOARD_KEEP_SCALE
	vec3 scale = vec3(
		length(vec3(worldTransform[0])),
		length(vec3(worldTransform[1])),
		length(vec3(worldTransform[2]))
	);
	#else
	const vec3 scale = vec3(1);
	#endif
	mat4 fmodelView = view * mat4(
		vec4(right   * scale.x, 0.0),
		vec4(up      * scale.y, 0.0),
		vec4(forward * scale.z, 0.0),
		worldTransform[3]
	);
	#else // No billboard

	if(uSkinned) worldTransform = worldTransform * skin();
	mat4 fmodelView = view * worldTransform;
	#endif

	// Inverting then transposing a mat4 is never good in the GPU
	// but it would take tons and tons of operations in HScript and we don't want that either
	mat4 invfmodelView = fusedInverseTranspose(fmodelView);
	
	vec4 localPosition = vec4(foxlite_Position.xyz, 1.0);
	vec4 worldPosition = worldTransform * localPosition;
	viewPosition = fmodelView * localPosition;

	modelViewNormal = normalize(basis(invfmodelView) * foxlite_Normal);

	#ifdef NORMAL_MAP
	vec3 tangentView = normalize(basis(invfmodelView) * foxlite_Tangent.xyz);
	
	// Re-orthogonalize tangent with respect to normal (Gram-Schmidt)
	// This is done because the tangent might not be perfectly perpendicular to Normal
	tangentView = normalize(tangentView - dot(tangentView, modelViewNormal) * modelViewNormal);

	// Create TBN matrix
	TBN = tbnNormalTangent(modelViewNormal, tangentView);
	TBN[1] *= foxlite_Tangent.w; // bitangent handedness
	#endif

	#ifdef SKY_REFLECTIONS
	worldDirection = viewToWorld(viewPosition);
	worldBasis = transpose(basis(invView));
	#endif

	#ifdef VERTEX_LIGHTING
	// Doesn't make much sense to calculate PBR materials here

	#ifdef FOG
	
	#ifdef FAST_FOG
	float fogStrength = -viewPosition.z;
	#else
	float fogStrength = length(viewPosition);
	#endif

	// Vertex interpolated fog
	fogStrength = clamp((fogStrength - fogStart) / (fogEnd - fogStart), 0.0, 1.0);
	#else
	const float fogStrength = 0.0;
	#endif

	foxlite_Colorv.rgb = light(foxlite_Colorv.rgb, -modelViewNormal, viewPosition.xyz, uSpecular, uRoughness);

	#ifdef FOG 
	
	#ifdef LINEAR_FOG
	foxlite_Colorv.rgb = mix(foxlite_Colorv.rgb, fogColor, fogStrength);
	#else
	foxlite_Colorv.rgb = mix(foxlite_Colorv.rgb, fogColor, fogStrength * fogStrength);
	#endif
	#endif
	#elif !defined(UNSHADED) && defined(SHADOW_GLSL) && !defined(SHADOW_PASS)
	setupShadows(worldPosition);
	#endif
	
	#ifdef SHADOW_PASS
	#if defined(SHADOW_GLSL)
	// Per-shadow light specific code
	if(currentLightType == LIGHT_POINT || currentLightType == LIGHT_AREA) {
		gl_Position = dualParaboloid(viewPosition, nearFarFromProjection(projection), view[3][3]);
		foxlite_TexCoordv *= shadowDistortW;
		return;
	}
	#endif
	#endif

	gl_Position = projection * viewPosition;
}