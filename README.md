# Wings

### Lightweight [Haxe](https://github.com/HaxeFoundation/haxe) & [Kha](https://github.com/KTXSoftware/Kha/) game framework

### Getting started
Clone empty wings project
- git clone --recursive https://github.com/luboslenco/empty
- git submodule foreach git pull origin master

### Usage
Rendering a [rotating 3D cube](https://googledrive.com/host/0B22ElR_OUmfddkFKczhfQ243LWs/index.html):
```haxe
class MeshController extends Trait implements IUpdateable {

    @inject
    var transform:Transform;

    public function new() {
        super();
    }

    public function update() {
    	// Rotate object
        transform.rotateY(Time.delta);
    }
}

class Game {

    public function new() {

        // Define shader structure
        var struct = new VertexStructure();
        struct.addFloat3("vertexPosition");
        struct.addFloat2("texturePosition");
        struct.addFloat3("normalPosition");

        // Create shader
        var shader = new Shader("default.frag", "default.vert", struct);
        shader.addConstantMat4("mvpMatrix");
        shader.addTexture("tex");
        Factory.addShader("shader", shader);

        // Create scene
        var scene = new Object();
        scene.addTrait(new SceneRenderer());
        Root.addChild(scene);
        
        // Add camera
        var camera = new PerspectiveCamera(new Vec3(0, 1, 3));
        camera.pitch(-15);
        scene.addTrait(camera);

        // Create mesh data
        Factory.addGeometry("cube", new CubeGeometry(1, 1, 1));
        Factory.addMaterial("wood", new TextureMaterial(shader, Factory.getTexture("box")));
        Factory.addMesh("mesh", new Mesh("cube", "wood"));

        // Add mesh
        var mesh = new Object();
        var renderer = new MeshRenderer("mesh");
        renderer.setMat4(renderer.mvpMatrix);
        mesh.addTrait(renderer);
        mesh.addTrait(new MeshController());
        scene.addChild(mesh);
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

### Demos
- [Fbx rendering](https://googledrive.com/host/0B22ElR_OUmfdNzluUmJJZjZQZUU/index.html)
- [3D physics](https://googledrive.com/host/0B22ElR_OUmfdRUk0M24xUDR4VUU/index.html)
- [Sculpting & Ray casting](https://googledrive.com/host/0B22ElR_OUmfdWEhUN2VyUW5HWVk/index.html)
- [2D particle systems](https://googledrive.com/host/0B22ElR_OUmfdUkI4SDhFWnVlS2s/index.html)
- [2D parallax effect](https://googledrive.com/host/0B22ElR_OUmfdS1NLUjRBUEtJM1k/index.html)
- [Basic UI](https://googledrive.com/host/0B22ElR_OUmfdOUh6Y1hlVE1xM1U/index.html)
- [Perlin Noise Shader](https://googledrive.com/host/0B22ElR_OUmfddm1LRVpjbjFFUVE/index.html)
- [Skeletal animation](https://googledrive.com/host/0B22ElR_OUmfdZ1VIa0w2Rm1qNGM/index.html)
