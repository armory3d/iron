package wings.core;

import composure.core.ComposeGroup;

import wings.trait.Transform;

class Object extends ComposeGroup {

	public var transform:Transform;

	public function new() {
		super();

		transform = new Transform();
		addTrait(transform);
	}
}
