package lue.node;

import lue.math.Mat4;
import lue.math.Vec4;
import lue.resource.LightResource;

class LightNode extends Node {

	var resource:LightResource;

	// Shadow map matrices
	public var P:Mat4 = null;
	public var V:Mat4 = null;

	public function new(resource:LightResource) {
		super();
		
		// P = Mat4.perspective(45, 1, 1, 20);
		// P = Mat4.orthogonal(-10, 10, -10, 10, -30, 30, 2);
		P = Mat4.orthogonal(-60, 60, -60, 60, -120, 120, 2);

		this.resource = resource;

		Node.lights.push(this);
	}

	public function buildMatrices() {
		transform.buildMatrix();
		V = Mat4.lookAt(new Vec4(transform.absx(), transform.absy(), transform.absz()), new Vec4(0, 0, 0), new Vec4(0, 0, -1));
		
		// V = transform.rot.toMatrix();
	    // var trans = Mat4.identity();
	    // trans.translate(transform.absx(), transform.absy(), transform.absz());
	    // V.multiply(trans, V);
	}
}
