package iron;

import iron.object.Object;

class Trait {

	public var name:String = "";
	/**
	 * Object this trait belongs to.
	 */
	public var object:Object;

	var _add:Array<Void->Void> = null;
	var _init:Array<Void->Void> = null;
	var _remove:Array<Void->Void> = null;
	var _update:Array<Void->Void> = null;
	var _lateUpdate:Array<Void->Void> = null;
	var _render:Array<kha.graphics4.Graphics->Void> = null;
	var _render2D:Array<kha.graphics2.Graphics->Void> = null;

	public function new() {}

	public function remove() {
		object.removeTrait(this);
	}

	public function notifyOnAdd(f:Void->Void) {
		if (_add == null) _add = [];
		_add.push(f);
	}

	public function notifyOnInit(f:Void->Void) {
		if (_init == null) _init = [];
		_init.push(f);
		App.notifyOnInit(f);
	}

	public function notifyOnRemove(f:Void->Void) {
		if (_remove == null) _remove = [];
		_remove.push(f);
	}

	public function notifyOnUpdate(f:Void->Void) {
		if (_update == null) _update = [];
		_update.push(f);
		App.notifyOnUpdate(f);
	}

	public function removeUpdate(f:Void->Void) {
		_update.remove(f);
		App.removeUpdate(f);
	}
	
	public function notifyOnLateUpdate(f:Void->Void) {
		if (_lateUpdate == null) _lateUpdate = [];
		_lateUpdate.push(f);
		App.notifyOnLateUpdate(f);
	}

	public function removeLateUpdate(f:Void->Void) {
		_lateUpdate.remove(f);
		App.removeLateUpdate(f);
	}

	public function notifyOnRender(f:kha.graphics4.Graphics->Void) {
		if (_render == null) _render = [];
		_render.push(f);
		App.notifyOnRender(f);
	}

	public function removeRender(f:kha.graphics4.Graphics->Void) {
		_render.remove(f);
		App.removeRender(f);
	}

	public function notifyOnRender2D(f:kha.graphics2.Graphics->Void) {
		if (_render2D == null) _render2D = [];
		_render2D.push(f);
		App.notifyOnRender2D(f);
	}

	public function removeRender2D(f:kha.graphics2.Graphics->Void) {
		_render2D.remove(f);
		App.removeRender2D(f);
	}
}
