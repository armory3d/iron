#version 100

#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D tex;
varying vec2 texCoord;
varying vec4 color;

uniform float time;

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v) {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0

// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  //i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}

void kore() {

	//vec2 texc = texCoord;
	//texc.x = texCoord.x + (sin(texCoord.y * time) * amplitude);
	//texc.y = texCoord.y + (sin(texCoord.x * time) * amplitude);
	//vec4 texcolor = texture2D(tex, texc) * color;
	//gl_FragColor = texcolor;

	// A very plain monochrome noise
	
  //float n = snoise(texCoord * time);

	//vec2 texc = texCoord;

	//vec4 texcolor = texture2D(tex, texc) * color;
	//texcolor.r = 0.5 + 0.5 * n;
	//texcolor.g = 0.5 + 0.5 * n;
	//texcolor.b = 0.5 + 0.5 * n;

	//gl_FragColor = texcolor;



  // Perturb the texcoords with three components of noise
  vec2 uvw = texCoord + 0.1 * vec2(snoise(texCoord + vec2(0.0, time)),
                                   snoise(texCoord + vec2(-17.0, time)));
  // Six components of noise in a fractal sum
  float n = snoise(uvw - vec2(0.0, time));
  n += 0.5 * snoise(uvw * 2.0 - vec2(0.0, time*1.4)); 
  n += 0.25 * snoise(uvw * 4.0 - vec2(0.0, time*2.0)); 
  n += 0.125 * snoise(uvw * 8.0 - vec2(0.0, time*2.8)); 
  n += 0.0625 * snoise(uvw * 16.0 - vec2(0.0, time*4.0)); 
  n += 0.03125 * snoise(uvw * 32.0 - vec2(0.0, time*5.6)); 
  n = n * 0.7;
  // A "hot" colormap - cheesy but effective 
  gl_FragColor = vec4(vec3(0.5, 0.5, 0.5) + vec3(n, n, n), 1.0);
}
