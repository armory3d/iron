package fox.trait;

import fox.core.IUpdateable;
import fox.core.Trait;
import fox.sys.Time;

import oimo.physics.collision.shape.BoxShape;
import oimo.physics.collision.shape.Shape;
import oimo.physics.collision.shape.ShapeConfig;
import oimo.physics.collision.shape.SphereShape;

class RigidBody extends Trait implements IUpdateable {

	public static inline var SHAPE_BOX = 0;
	public static inline var SHAPE_SPHERE = 1;
	var shape:Int;

	public var scene:SceneRenderer;
	public var body:oimo.physics.dynamics.RigidBody = null;

	var transform:Transform;
	var mass:Float;

	public function new(mass:Float = 1, shape:Int = SHAPE_BOX) {
		super();

		this.mass = mass;
		this.shape = shape;
	}

	@injectAdd({asc:true,sibl:true})
	function addSceneRenderer(trait:SceneRenderer) {
		scene = trait;

		if (transform != null) init(transform, scene);
	}

	@injectAdd
	function addTransform(trait:Transform) {
		transform = trait;

		if (scene != null) init(transform, scene);
	}

	public function init(transform:Transform, scene:SceneRenderer) {
		if (body != null) return;

		this.transform = transform;
		this.scene = scene;

		var sc:ShapeConfig = new ShapeConfig();
		sc.density = mass > 0 ? mass : 1;
		body = new oimo.physics.dynamics.RigidBody(this, transform.pos.x, transform.pos.y, transform.pos.z);
		body.name = parent.name;

		if (shape == SHAPE_BOX) {
			body.addShape(new BoxShape(sc, transform.size.x, transform.size.y, transform.size.z));
		}
		else if (shape == SHAPE_SPHERE) {
			body.addShape(new SphereShape(sc, transform.size.x / 2));
		}
		
		if (mass == 0) {
			body.setupMass(oimo.physics.dynamics.RigidBody.BODY_STATIC);
		}
		else {
			body.setupMass(oimo.physics.dynamics.RigidBody.BODY_DYNAMIC);
		}
		
		scene.world.addRigidBody(body);
		Shape.nextID++;

		body.orientation.x = transform.rot.x;
		body.orientation.y = transform.rot.y;
		body.orientation.z = transform.rot.z;
		body.orientation.s = transform.rot.w;
	}

	public function update() {

		// Clear small values
		/*if (Math.abs(transform.pos.x - body.position.x) < 0.001) body.position.x = transform.pos.x;
		if (Math.abs(transform.pos.y - body.position.y) < 0.001) body.position.y = transform.pos.y;
		if (Math.abs(transform.pos.z - body.position.z) < 0.001) body.position.z = transform.pos.z;

		if (Math.abs(transform.rot.x - body.orientation.x) < 0.001) body.orientation.x = transform.rot.x;
		if (Math.abs(transform.rot.y - body.orientation.y) < 0.001) body.orientation.y = transform.rot.y;
		if (Math.abs(transform.rot.z - body.orientation.z) < 0.001) body.orientation.z = transform.rot.z;
		if (Math.abs(transform.rot.w - body.orientation.s) < 0.001) body.orientation.s = transform.rot.w;*/

		transform.pos.x = body.position.x;
		transform.pos.y = body.position.y;
		transform.pos.z = body.position.z;
		
		transform.rot.x = body.orientation.x;
		transform.rot.y = body.orientation.y;
		transform.rot.z = body.orientation.z;
		transform.rot.w = body.orientation.s;

		transform.modified = true;
	}

	override function onItemRemove() { // TODO: not called
		scene.world.removeRigidBody(body);
	}
}
