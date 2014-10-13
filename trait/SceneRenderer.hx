package fox.trait;

import fox.core.IUpdateable;
import fox.core.Trait;
import fox.sys.Time;
import fox.trait.camera.Camera;

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
