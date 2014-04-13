# Wings

### Lightweight 2D/3D game framework built with [Haxe](https://github.com/HaxeFoundation/haxe) & [Kha](https://github.com/KTXSoftware/Kha/)

- [Cross-platform](http://kha.ktxsoftware.com/?systems)
- GLSL shaders
- [Fbx](https://github.com/ncannasse/h3d/tree/master/h3d/fbx) & Obj support
- Integrated [3D physics](https://github.com/gbpaul/cannon.hx)
- Scene hierarchy, Camera, Skydome, Billboards, Terrain, Grass,...
- UI
- 2D drawing and some 2D stuff
- 2D particle system [importer](http://onebyonedesign.com/flash/particleeditor/) & renderer
- [Parallax effect](https://github.com/wagerfield/parallax)

In Progress
- FBX & MD2 Animation
- Frustum culling

Wings is possible only thanks to the Haxe and Kha, which are the two most awesome things ever. The goal is to have a little framework for rapid prototyping of mini 3D games. It's inspired by H3D, ThreeJS and more.

If you are using Kha together with Sublime Text, check out my [Kha Sublime Bundle](https://github.com/luboslenco/kha-sublime-bundle), forked from [Haxe Sublime Bundle](https://github.com/clemos/haxe-sublime-bundle) by Clemos.

### Demos
- [Fbx rendering](https://googledrive.com/host/0B22ElR_OUmfdNzluUmJJZjZQZUU/index.html)
- [3D physics](https://googledrive.com/host/0B22ElR_OUmfdRUk0M24xUDR4VUU/index.html)
- [Sculpting & Ray casting](https://googledrive.com/host/0B22ElR_OUmfdWEhUN2VyUW5HWVk/index.html)
- [2D particle systems](https://googledrive.com/host/0B22ElR_OUmfdUkI4SDhFWnVlS2s/index.html)
- [2D parallax effect](https://googledrive.com/host/0B22ElR_OUmfdS1NLUjRBUEtJM1k/index.html)
- [Basic UI](https://googledrive.com/host/0B22ElR_OUmfdOUh6Y1hlVE1xM1U/index.html)
- [Perlin Noise Shader](https://googledrive.com/host/0B22ElR_OUmfddm1LRVpjbjFFUVE/index.html)

### Usage
Rendering a [rotating 3D cube](https://googledrive.com/host/0B22ElR_OUmfddkFKczhfQ243LWs/index.html):
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

		// Create cube geometry of size 1x1x1
		var geometry = new CubeGeometry(1, 1, 1);

		// Create material with default shader and box texture
		var material = new TextureMaterial(R.shader, R.box);

		// Create cube mesh
		var mesh = new Mesh(geometry, material);

		// Create model that renders cube mesh
		model = new Model(mesh);

		// Set shader uniforms(you can write your own glsl shaders)
		// Default shader needs model-view-projection matrix
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
