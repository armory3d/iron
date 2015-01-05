package fox.trait;

import oimo.physics.dynamics.World;
import fox.core.ILateUpdateable;
import fox.core.Trait;
import fox.sys.Time;

class PhysicsScene extends Trait implements ILateUpdateable {

	// Physics world
	public var world:World;

	public function new() {
		super();

		// Gravity
		World.gravityX = Main.gameData.gravity[0];
		World.gravityY = Main.gameData.gravity[1];
		World.gravityZ = Main.gameData.gravity[2];
		
		world = new World();
	}

	public function update() {
		world.step(Time.delta);
	}
}
