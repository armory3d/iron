#version 100

attribute vec3 vertexPosition;
attribute vec2 texPosition;
attribute vec3 normalPosition;

uniform mat4 mvpMatrix;
uniform vec3 billboardPos;
uniform vec3 billboardSize;
uniform vec3 camRightWorld;
uniform vec3 camUpWorld;

varying vec2 texCoord;
varying vec3 norm;

void kore() {

	vec3 vertexPos = vec3(
    	billboardPos +
    	camRightWorld * vertexPosition.x * billboardSize.x +
    	vec3(0, 1, 0) * vertexPosition.y * billboardSize.y);
    	//camUpWorld * vertexPosition.y * billboardSize.y);

	gl_Position =  mvpMatrix * vec4(vertexPos, 1.0);
	
	norm = normalPosition;
	texCoord = texPosition;
}
