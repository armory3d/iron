package fox.core;

import composure.traits.AbstractTrait;

class Trait extends AbstractTrait {

	public var name:String = "";

	public var owner(get, never):Object;

	public function new() {
		super();
	}

	inline function get_owner():Object {
		return cast(item, Object);
	}
}
