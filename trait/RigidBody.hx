package wings.trait;

import wings.core.IUpdateable;
import wings.core.Trait;
import wings.sys.Time;
import wings.trait.SceneRenderer;
import wings.trait.Transform;

import com.element.oimo.physics.collision.shape.BoxShape;
import com.element.oimo.physics.collision.shape.Shape;
import com.element.oimo.physics.collision.shape.ShapeConfig;
import com.element.oimo.physics.collision.shape.SphereShape;

class RigidBody extends Trait implements IUpdateable {

	public var scene:SceneRenderer;

	public var body:com.element.oimo.physics.dynamics.RigidBody;

	var transform:Transform;

	var mass:Float;

	public function new(mass:Float = 1) {
		super();

		this.mass = mass;
	}

	@injectAdd({asc:true,sibl:true})
	function addSceneRenderer(trait:SceneRenderer) {
		scene = trait;
	}

	@injectAdd
	function addTransform(trait:Transform) {
		transform = trait;

		var sc:ShapeConfig = new ShapeConfig();
		body = new com.element.oimo.physics.dynamics.RigidBody(transform.pos.x, transform.pos.y, transform.pos.z);
		body.addShape(new BoxShape(sc, transform.size.x, transform.size.y, transform.size.z));
		
		if (mass == 0) {
			body.setupMass(com.element.oimo.physics.dynamics.RigidBody.BODY_STATIC);
		}
		else {
			body.setupMass(com.element.oimo.physics.dynamics.RigidBody.BODY_DYNAMIC);
		}
		
		scene.world.addRigidBody(body);
		Shape.nextID++;

		body.orientation.x = transform.rot.x;
		body.orientation.y = transform.rot.y;
		body.orientation.z = transform.rot.z;
		body.orientation.s = transform.rot.w;
	}

	public function update() {

		transform.pos.x = body.position.x;
		transform.pos.y = body.position.y;
		transform.pos.z = body.position.z;
		
		transform.rot.x = body.orientation.x;
		transform.rot.y = body.orientation.y;
		transform.rot.z = body.orientation.z;
		transform.rot.w = body.orientation.s;

		transform.modified = true;
	}
}
