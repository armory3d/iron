![Lue](http://lue3d.org/docs/images/lue.png)

[Lue](http://lue3d.org) is a minimal 3D rendering engine built with Haxe and Kha.

###### Getting Started
- [docs](http://lue3d.org/docs)
- [examples](https://github.com/luboslenco/lue_examples)

##### Rendering 3D model

![Hello](http://lue3d.org/docs/images/basic_render.png)

```haxe
class Game {

	var cam:CameraNode;

	public function new() {

		var modelRes = Eg.getModelResource("monkey_resource");
		var materialRes = Eg.getMaterialResource("material_resource");
		var lightRes = Eg.getLightResource("light_resource");
		var camRes = Eg.getCameraResource("camera_resource");

		var model = Eg.addModelNode(modelRes, materialRes);

		cam = Eg.addCameraNode(camRes);
		Eg.setNodeTransform(cam, 0, -5, 1.5, -1.3, 0, 0);
		
		var light = Eg.addLightNode(lightRes);
		Eg.setNodeTransform(light, 5, -10, 20);

		App.requestRender(render);
	}

	function render(g:kha.graphics4.Graphics) {
		Eg.render(g, cam);
	}
}
```
