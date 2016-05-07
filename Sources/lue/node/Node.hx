package lue.node;

import kha.graphics4.Graphics;
import lue.math.Mat4;
import lue.Trait;
import lue.resource.SceneFormat;
import lue.resource.Resource;
import lue.resource.MaterialResource;

class Node {

	public var id:String = "";
	public var parent:Node;

	public var children:Array<Node> = [];
	public var traits:Array<Trait> = [];

	public var transform:Transform;

	public function new() {
		transform = new Transform(this);
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

	public function getChild(id:String):Node {
		if (this.id == id) {
			return this;
		}
		else {
			for (c in children) {
				var r = c.getChild(id);
				if (r != null) {
					return r;
				}
			}
		}
		return null;
	}

	public function render(g:Graphics, context:String, camera:CameraNode, light:LightNode, bindParams:Array<String>) {
		for (c in children) c.render(g, context, camera, light, bindParams);
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
}
