package lue.node;

import lue.resource.LightResource;

class LightNode extends Node {

	var resource:LightResource;

	public function new(resource:LightResource) {
		super();

		this.resource = resource;
	}
}
