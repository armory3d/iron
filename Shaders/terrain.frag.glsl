#version 100

#ifdef GL_ES
precision mediump float;
#endif

varying vec2 texCoord;
varying vec3 fPositionWorld;
varying vec3 norm;
varying vec3 eyeDirectionCamera;
varying vec3 lightDirectionCamera;

uniform sampler2D tex;
uniform vec3 power;
uniform vec3 lightColor;
uniform vec3 materialAmbientColor;
uniform vec3 materialSpecularColor;

//uniform mat4 viewMatrix;
//uniform mat4 modelMatrix;

//uniform vec3 lightPositionWorld;

void kore()
{
	// Light emission properties
	// You probably want to put them as uniforms
	//vec3 lightColor = vec3(1, 1, 1);
	float lightPower = power.x;//3000.0;
	
	// Material properties
	vec3 materialDiffuseColor = texture2D(tex, vec2(texCoord.s, texCoord.t)).rgb;
	vec3 matAmbientColor = materialAmbientColor * materialDiffuseColor;
	//vec3 materialSpecularColor = vec3(0.3,0.3,0.3);

	// Distance to the light
	vec3 lightPositionWorld = vec3(10, 30, 30);
	float distance = length(lightPositionWorld - fPositionWorld);

	// Normal of the computed fragment, in camera space
	vec3 n = normalize(norm);
	// Direction of the light (from the fragment to the light)
	vec3 l = normalize(lightDirectionCamera);
	// Cosine of the angle between the normal and the light direction, 
	// clamped above 0
	//  - light is at the vertical of the triangle -> 1
	//  - light is perpendicular to the triangle -> 0
	//  - light is behind the triangle -> 0
	float cosTheta = clamp(dot(n, l), 0.0, 1.0);
	
	// Eye vector (towards the camera)
	vec3 e = normalize(eyeDirectionCamera);
	// Direction in which the triangle reflects the light
	vec3 r = reflect(-l, n);
	// Cosine of the angle between the Eye vector and the Reflect vector,
	// clamped to 0
	//  - Looking into the reflection -> 1
	//  - Looking elsewhere -> < 1
	float cosAlpha = clamp(dot(e, r), 0.0, 1.0);
	
	gl_FragColor = vec4(vec3(
		// Ambient : simulates indirect lighting
		matAmbientColor +
		// Diffuse : "color" of the object
		materialDiffuseColor * lightColor * lightPower * cosTheta / (distance * distance) +
		// Specular : reflective highlight, like a mirror
		materialSpecularColor * lightColor * lightPower * pow(cosAlpha, 5.0) / (distance * distance)), 1);
}
