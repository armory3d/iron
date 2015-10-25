package lue.node;

import kha.graphics4.Graphics;
import lue.trait.Trait;

class Node {

	public static var models:Array<ModelNode>;
	public static var lights:Array<LightNode>;
	public static var cameras:Array<CameraNode>;

	public var name:String = "";
	public var parent:Node;

	public var children:Array<Node> = [];
	public var traits:Array<Trait> = [];

	public var transform:Transform;

	public function new() {
		transform = new Transform(this);
	}

	public static function reset() {
		models = [];
		lights = [];
		cameras = [];
	}

	public function addChild(o:Node) {
		children.push(o);
		o.parent = this;
	}

	public function removeChild(o:Node) {
		// Remove children of o
		while (o.children.length > 0) o.removeChild(o.children[0]);

		// Remove traits
		while (o.traits.length > 0) o.removeTrait(o.traits[0]);

		children.remove(o);
		o.parent = null;
	}

	public function getChild(name:String):Node {
		if (this.name == name) {
			return this;
		}
		else {
			for (c in children) {
				var r = c.getChild(name);
				if (r != null) {
					return r;
				}
			}
		}
		return null;
	}

	public function addTrait(t:Trait) {
		traits.push(t);
		t.node = this;

		if (t._add != null) { t._add(); t._add = null; }
	}

	public function removeTrait(t:Trait) {
		if (t._init != null) App.removeInit(t._init);
		if (t._update != null) App.removeUpdate(t._update);
		if (t._render != null) App.removeRender(t._render);
		if (t._render2D != null) App.removeRender2D(t._render2D);
		if (t._remove != null) { t._remove(); t._remove = null; }

		traits.remove(t);
		t.node = null;
	}

	public function getTrait(c:Class<Trait>):Dynamic {
		for (t in traits) {
			if (Type.getClass(t) == c) {
				return t;
			}
		}
		return null;
	}

	public function render(g:Graphics, context:String, camera:CameraNode, light:LightNode) {
		for (c in children) c.render(g, context, camera, light);
	}
}
