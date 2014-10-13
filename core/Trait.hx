package fox.core;

import composure.traits.AbstractTrait;

class Trait extends AbstractTrait {

	public var name:String = "";

	// TODO: Rename
	public var parent(get, never):Object;

	public function new() {
		super();
	}

	inline function get_parent():Object {
		return cast(item, Object);
	}
}
