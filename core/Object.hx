package wings.core;

import composure.core.ComposeGroup;

import wings.trait.Transform;
import wings.trait.Input;

class Object extends ComposeGroup {

	public var name:String = "";
	
	public var parent(get, never):Object;

	public var transform:Transform;
	public var input:Input;

	public function new() {
		super();

		transform = new Transform();
		addTrait(transform);

		input = new Input();
		addTrait(input);
	}

	public function remove() {
		parentItem.removeChild(this);
	}

	inline function get_parent():Object {
		if (Std.is(parentItem, Object)) {
			return cast(parentItem, Object);
		}
		else return null;
	}

	override function onParentAdd() {
		super.onParentAdd();

		/*if (Std.is(parentItem, Object) && input.layer == 0) {
			input.layer = cast(parentItem, Object).input.layer;
			Input._layer = input.layer;
		}*/

		transform.update();
	}

	override function onParentRemove() {
		super.onParentRemove();

		// TODO: prevent if parent input layer is > 0
		if (input.layer > 0) Input._layer = input.layer - 1;
	}

	public function getChild(name:String):Object {

		if (this.name == name) {
			return this;
		}
		else {
			for (c in children) {
				var r = cast(c, Object).getChild(name);
				if (r != null) {
					return r;
				}
			}
		}

		return null;
	}
}
