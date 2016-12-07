package iron;

import iron.object.Object;

class Trait {

	public var name:String = "";
	public var object:Object;

	public var _add:Void->Void = null;
	public var _init:Void->Void = null;
	public var _remove:Void->Void = null;
	public var _update:Void->Void = null;
	public var _lateUpdate:Void->Void = null;
	public var _render:kha.graphics4.Graphics->Void = null;
	public var _render2D:kha.graphics2.Graphics->Void = null;

	public function new() {
	
	}

	public function remove() {
		object.removeTrait(this);
	}

	function notifyOnAdd(f:Void->Void) {
		_add = f;
	}

	function notifyOnInit(f:Void->Void) {
		App.notifyOnInit(f);
		_init = f;
	}

	function notifyOnRemove(f:Void->Void) {
		_remove = f;
	}

	function notifyOnUpdate(f:Void->Void) {
		App.notifyOnUpdate(f);
		_update = f;
	}

	function removeUpdate(f:Void->Void) {
		App.removeUpdate(f);
		_update = null;
	}
	
	function notifyOnLateUpdate(f:Void->Void) {
		App.notifyOnLateUpdate(f);
		_lateUpdate = f;
	}

	function removeLateUpdate(f:Void->Void) {
		App.removeLateUpdate(f);
		_lateUpdate = null;
	}

	function notifyOnRender(f:kha.graphics4.Graphics->Void) {
		App.notifyOnRender(f);
		_render = f;
	}

	function removeRender(f:kha.graphics4.Graphics->Void) {
		App.removeRender(f);
		_render = null;
	}

	function notifyOnRender2D(f:kha.graphics2.Graphics->Void) {
		App.notifyOnRender2D(f);
		_render2D = f;
	}

	function removeRender2D(f:kha.graphics2.Graphics->Void) {
		App.removeRender2D(f);
		_render2D = null;
	}
}
