Wings
===

### Lightweight 3D framework built on Kha

Sample code showing how to render a rotating 3D cube:
```haxe
class Game {

	var model:Model;

	public function new() {

		// Create a camera at position x = 0, y = 1, z = 3
		var camera = new PerspectiveCamera(new Vec3(0, 1, 3));

		// Look down 15 degrees
		camera.pitch(-15);

		// Create empty scene
		var scene = new Scene(camera);
		Root.addChild(scene);

		// Create material with default shader and box texture
		var material = new Material(R.shader, R.box);

		// Create cube mesh of size 1x1x1
		var mesh = new CubeMesh(1, 1, 1);

		// Create model that renders cube mesh using our material
		model = new Model(mesh, material);

		// Set shader uniforms(you can write your own glsl shaders)
		// Default shader needs model matrix
		model.setMat4(model.mvpMatrix);

		// Add cube to scene
		scene.addChild(model);

		// Listen to update event
		Root.addEvent(new UpdateEvent(onUpdate));
	}

	function onUpdate() {

		// Rotate cube on Y axis
		model.rotateY(Time.delta * 0.001);
	}
}
```

Vertex shader:
```glsl
attribute vec3 vertexPosition;
attribute vec2 texPosition;

uniform mat4 mvpMatrix;

varying vec2 texCoord;

void kore() {
	gl_Position =  mvpMatrix * vec4(vertexPosition, 1.0);
	
	texCoord = texPosition;
}
```

Fragment shader:
```glsl
uniform sampler2D tex;

varying vec2 texCoord;

void kore() {
	gl_FragColor = texture2D(tex, texCoord);
}
```
