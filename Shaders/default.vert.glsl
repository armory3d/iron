#version 100

attribute vec3 vertexPosition;
attribute vec2 texPosition;
attribute vec3 normalPosition;

uniform mat4 mvpMatrix;

varying vec2 texCoord;
varying vec3 norm;

void kore() {
	gl_Position =  mvpMatrix * vec4(vertexPosition, 1.0);
	
	norm = normalPosition;
	texCoord = texPosition;
}
