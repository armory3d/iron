package fox.trait;

import fox.core.IUpdateable;
import fox.core.Trait;
import fox.sys.Time;

import oimo.physics.dynamics.World;

class SceneRenderer extends Trait implements IUpdateable {

	@inject({desc:true,sibl:true})
	public var camera:Camera;

	public var world:World;

	public function new() {
		super();

		// Physics world
		World.gravityX = Main.gameData.gravity[0];
		World.gravityY = Main.gameData.gravity[1];
		World.gravityZ = Main.gameData.gravity[2];
		world = new World();
	}

	public function update() {
		world.step();
	}
}
