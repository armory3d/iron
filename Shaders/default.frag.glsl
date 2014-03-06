#version 100

#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D tex;
varying vec2 texCoord;
varying vec3 norm;

void kore() {

	gl_FragColor = texture2D(tex, texCoord);// * vec4(1,1,1,1);

	//if (gl_FragColor.a == 0.0) discard;
}
