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
	/**
	 * Removes trait from the object.
	 */
	public function remove() {
		object.removeTrait(this);
	}
	/**
	 * Notify when the trait is added.
	 * @param f A function to run after trait it added.
	 */
	public function notifyOnAdd(f:Void->Void) {
		if (_add == null) _add = [];
		_add.push(f);
	}
	/**
	 * Notify when the trait is initiated.
	 * @param f A function to run after trait it initiated.
	 */
	public function notifyOnInit(f:Void->Void) {
		if (_init == null) _init = [];
		_init.push(f);
		App.notifyOnInit(f);
	}
	/**
	 * Notify when the trait is removed.
	 * @param f A function to run before trait is remove.
	 */
	public function notifyOnRemove(f:Void->Void) {
		if (_remove == null) _remove = [];
		_remove.push(f);
	}
	/**
	 * Notify when the trait is updated every frame.
	 * @param f A function to run during trait update.
	 */
	public function notifyOnUpdate(f:Void->Void) {
		if (_update == null) _update = [];
		_update.push(f);
		App.notifyOnUpdate(f);
	}
	/**
	 * Notify when the trait update is removed
	 * @param f A function to run before trait update is removed.
	 */
	public function removeUpdate(f:Void->Void) {
		_update.remove(f);
		App.removeUpdate(f);
	}
	/**
	 * Notify during the last frame of update.
	 * @param f A function to run during trait last frame of update.
	 */
	public function notifyOnLateUpdate(f:Void->Void) {
		if (_lateUpdate == null) _lateUpdate = [];
		_lateUpdate.push(f);
		App.notifyOnLateUpdate(f);
	}
	/**
	 * Notify when the trait last frame of update is removed.
	 * @param f A function to run before the trait last frame of update is removed.
	 */
	public function removeLateUpdate(f:Void->Void) {
		_lateUpdate.remove(f);
		App.removeLateUpdate(f);
	}
	/**
	 * Notify when the trait render.
	 * @param f A function to run during trait render.
	 */
	public function notifyOnRender(f:kha.graphics4.Graphics->Void) {
		if (_render == null) _render = [];
		_render.push(f);
		App.notifyOnRender(f);
	}
	/**
	 * Notify when the trait render is removed
	 * @param f A function to run before trait render is removed.
	 */
	public function removeRender(f:kha.graphics4.Graphics->Void) {
		_render.remove(f);
		App.removeRender(f);
	}
	/**
	 * Notify when the trait render 2d.
	 * @param f A function to run during trait render 2d.
	 */
	public function notifyOnRender2D(f:kha.graphics2.Graphics->Void) {
		if (_render2D == null) _render2D = [];
		_render2D.push(f);
		App.notifyOnRender2D(f);
	}
	/**
	 * Notify when the trait render 2d is removed
	 * @param f A function to run before trait render 2d is removed.
	 */
	public function removeRender2D(f:kha.graphics2.Graphics->Void) {
		_render2D.remove(f);
		App.removeRender2D(f);
	}
}
