
uniform vec2 skyOffset;
uniform sampler2D skyTexture;

varying vec3 worldDirection;
varying mat3 worldBasis;

vec2 coordFromSphere(vec3 dir) {
    return vec2(
        0.5 + atan(dir.z, dir.x) / TAU,
        0.5 - asin(dir.y) / PI
    );
}

vec3 sphereFromCoord(vec2 uv) {
    float phi   = (uv.x - 0.5) * TAU; // azimuthal (xz plane)
    float theta = (0.5 - uv.y) * PI;  // elevation (y)

    float cosTheta = cos(theta);
    return vec3(
        cosTheta * cos(phi),
        sin(theta),
        cosTheta * sin(phi)
    );
}

#ifdef FRAGMENT
// LOD version for fragment shader only
// Stops WebGL from crashing
vec3 panoramaSky(sampler2D skyTex, vec3 direction, float lod) {
	return texture2D(skyTex, coordFromSphere(direction) + skyOffset, lod).rgb;
}
#endif

vec3 panoramaSky(sampler2D skyTex, vec3 direction) {
	return texture2D(skyTex, coordFromSphere(direction) + skyOffset).rgb;
}
