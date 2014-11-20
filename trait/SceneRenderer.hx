package fox.trait;

import fox.core.IUpdateable;
import fox.core.Trait;
import fox.sys.Time;

import oimo.physics.dynamics.World;

//import jiglib.physics.PhysicsSystem;

class SceneRenderer extends Trait implements IUpdateable {

	@inject({desc:true,sibl:true})
	public var camera:Camera;

	public var world:World;
	//public var physicsSystem:PhysicsSystem;

	public function new() {
		super();

		// Physics world
		World.gravityX = Main.gameData.gravity[0];
		World.gravityY = Main.gameData.gravity[1];
		World.gravityZ = Main.gameData.gravity[2];
		world = new World();

		//physicsSystem = PhysicsSystem.getInstance();
		//physicsSystem.setCollisionSystem(false);
	}

	public function update() {
		world.step(fox.sys.Time.delta);
		//physicsSystem.integrate(fox.sys.Time.delta);
	}
}
