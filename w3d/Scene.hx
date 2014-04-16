package wings.w3d;

import kha.Painter;
import wings.w3d.Object;
import wings.w3d.cameras.Camera;

class Scene extends Object
{
	public var camera:Camera;

	public function new(camera:Camera) {
		super();
		
		this.camera = camera;
		//scene = this;
	}

	public override function addChild(child:Object) {
		super.addChild(child);

		child.scene = this;

		for (i in 0...child.children.length) {	// TODO: set scene recursively
			child.children[i].scene = this;
		}
	}

	public override function update() {
		super.update();

		sync();
	}

	public override function render(painter:Painter) {
		super.render(painter);
	}

	public function load()
	{
		// Load scene
	}
}
