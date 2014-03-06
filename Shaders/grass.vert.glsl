#version 100

attribute vec3 vertexPosition;
attribute vec2 texPosition;
attribute vec3 normalPosition;

uniform mat4 mvpMatrix;

varying vec2 texCoord;
varying vec3 norm;

void kore() {
	vec3 vec = vertexPosition;
	if (texCoord.y <= 0.1) {
		//vec.x = 1.0;
	}

	gl_Position =  mvpMatrix * vec4(vec, 1.0);
	
	norm = normalPosition;
	texCoord = texPosition;
}
