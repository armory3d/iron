package lue.node;

import lue.math.Mat4;
import lue.resource.LightResource;

class LightNode extends Node {

	public var resource:LightResource;

	// Shadow map matrices
	public var V:Mat4 = null;

	public function new(resource:LightResource) {
		super();
		
		this.resource = resource;

		RootNode.lights.push(this);
	}

	public function buildMatrices() {
		transform.buildMatrix();
		
		// V = Mat4.lookAt(new Vec4(transform.absx(), transform.absy(), transform.absz()), new Vec4(0, 0, 0), new Vec4(0, 0, -1));
		
		V = Mat4.identity();
		V.inverse2(transform.matrix);
	}
}
