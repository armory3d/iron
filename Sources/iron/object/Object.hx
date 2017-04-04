package iron.object;

import iron.Trait;
import iron.data.SceneFormat;

class Object {
	static var uidCounter = 0;
	public var uid:Int;
	public var urandom:Float;
	public var raw:TObj = null;

	public var name:String = "";
	public var transform:Transform;
	public var constraints:Array<Constraint> = null;
	public var traits:Array<Trait> = [];

	public var parent:Object = null;
	public var children:Array<Object> = [];
	public var lods:Array<Object> = null;
	public var group:Array<Object> = null;

	public var animation:Animation = null;
	public var visible = true; // Skip render, keep updating
	public var visibleMesh = true;
	public var visibleShadow = true;
	public var culled = false; // Object was culled last frame

	public function new() {
		uid = uidCounter++;
		urandom = seededRandom(); //Math.random();
		transform = new Transform(this);
	}
	
	public function addChild(o:Object) {
		children.push(o);
		o.parent = this;
	}

	public function remove() {
		if (animation != null) animation.remove();
		while (children.length > 0) children[0].remove();
		while (traits.length > 0) traits[0].remove();
		if (parent != null) parent.children.remove(this);
		parent = null;
	}

	public function getChild(name:String):Object {
		if (this.name == name) return this;
		else {
			for (c in children) {
				var r = c.getChild(name);
				if (r != null) return r;
			}
		}
		return null;
	}

	public function getChildOfType(type:Class<Object>):Object {
		if (Std.is(this, type)) return this;
		else {
			for (c in children) {
				var r = c.getChildOfType(type);
				if (r != null) return r;
			}
		}
		return null;
	}

	public function addTrait(t:Trait) {
		traits.push(t);
		t.object = this;

		if (t._add != null) {
			for (f in t._add) f();
			t._add = null;
		}
	}

	public function removeTrait(t:Trait) {
		if (t._init != null) {
			for (f in t._init) App.removeInit(f);
			t._init = null;
		}
		if (t._update != null) {
			for (f in t._update) App.removeUpdate(f);
			t._update = null;
		}
		if (t._lateUpdate != null) {
			for (f in t._lateUpdate) App.removeLateUpdate(f);
			t._lateUpdate = null;
		}
		if (t._render != null) {
			for (f in t._render) App.removeRender(f);
			t._render = null;
		}
		if (t._render2D != null) {
			for (f in t._render2D) App.removeRender2D(f);
			t._render2D = null;
		}
		if (t._remove != null) {
			for (f in t._remove) f();
			t._remove = null;
		}

		traits.remove(t);
		t.object = null;
	}

	public function getTrait(c:Class<Trait>):Dynamic {
		for (t in traits) if (Type.getClass(t) == c) return t;
		return null;
	}

	public function setupAnimation(setup:TAnimationSetup) {
		animation = new ObjectAnimation(this, setup);
	}

	static var seed = 1; // cpp / js not consistent
	static function seededRandom():Float {
		seed = (seed * 9301 + 49297) % 233280;
		return seed / 233280.0;
	}

	public function toString():String {
		return "Object " + name;
	}
}
