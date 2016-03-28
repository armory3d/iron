package lue.trait;

import lue.node.Node;

class Trait {

	public var name:String = "";
	public var node:Node;

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
		node.removeTrait(this);
	}

	function requestAdd(f:Void->Void) {
		_add = f;
	}

	function requestInit(f:Void->Void) {
		App.requestInit(f);
		_init = f;
	}

	function requestRemove(f:Void->Void) {
		_remove = f;
	}

	function requestUpdate(f:Void->Void) {
		App.requestUpdate(f);
		_update = f;
	}
	
	function requestLateUpdate(f:Void->Void) {
		App.requestLateUpdate(f);
		_lateUpdate = f;
	}

	function requestRender(f:kha.graphics4.Graphics->Void) {
		App.requestRender(f);
		_render = f;
	}

	function requestRender2D(f:kha.graphics2.Graphics->Void) {
		App.requestRender2D(f);
		_render2D = f;
	}
}
