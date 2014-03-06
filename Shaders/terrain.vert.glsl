#version 100

#ifdef GL_ES
precision mediump float;
#endif

attribute vec3 vertexPosition;
attribute vec2 texPosition;
attribute vec3 normalPosition;

varying vec3 fPositionWorld;
varying vec2 texCoord;
varying vec3 norm;
varying vec3 eyeDirectionCamera;
varying vec3 lightDirectionCamera;
		
uniform sampler2D tex;	
uniform mat4 modelMatrix;
uniform mat4 viewMatrix;
uniform mat4 projectionMatrix;

//uniform vec3 lightPositionWorld;
			
void kore()
{
	gl_Position = projectionMatrix * viewMatrix * modelMatrix * vec4(vertexPosition, 1.0);

	// Position of the vertex, in worldspace : M * position
	fPositionWorld = (modelMatrix * vec4(vertexPosition, 1)).xyz;
	
	// Vector that goes from the vertex to the camera, in camera space.
	// In camera space, the camera is at the origin (0,0,0).
	vec3 vPositionCamera = (viewMatrix * modelMatrix * vec4(vertexPosition, 1)).xyz;
	eyeDirectionCamera = vec3(0,0,0) - vPositionCamera;

	// Vector that goes from the vertex to the light, in camera space. M is ommited because it's identity.
	vec3 lightPositionWorld = vec3(10, 30, 30);
	vec3 lightPositionCamera = (viewMatrix * vec4(lightPositionWorld, 1)).xyz;
	lightDirectionCamera = lightPositionCamera + eyeDirectionCamera;
	
	// Normal of the the vertex, in camera space
	norm = (viewMatrix * modelMatrix * vec4(normalPosition, 0)).xyz;
	// Only correct if ModelMatrix does not scale the model ! Use its inverse transpose if not.

	texCoord = texPosition;
}
