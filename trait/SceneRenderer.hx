package wings.trait;

import wings.core.IUpdateable;
import wings.core.Trait;
import wings.sys.Time;
import wings.trait.camera.Camera;

import com.element.oimo.physics.dynamics.World;

class SceneRenderer extends Trait implements IUpdateable {

	@inject({desc:true,sibl:true})
	public var camera:Camera;

	public var world:World;

	public function new() {
		super();

		// Physics world
		world = new World();
	}

	public function update() {
		world.step();
	}
}
