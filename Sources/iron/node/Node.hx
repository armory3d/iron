package iron.node;

import kha.graphics4.Graphics;
import iron.math.Mat4;
import iron.Trait;
import iron.resource.SceneFormat;
import iron.resource.Resource;
import iron.resource.MaterialResource;

class Node {
	static var uidCounter = 0;
	public var uid:Int;
	public var raw:TNode = null;

	public var id:String = "";
	public var transform:Transform;
	public var traits:Array<Trait> = [];

	public var parent:Node;
	public var children:Array<Node> = [];

	public var animation:Animation = null;

	public function new() {
		uid = uidCounter++;
		transform = new Transform(this);
	}
	
	public function addChild(o:Node) {
		children.push(o);
		o.parent = this;
	}

	public function remove() {
		while (children.length > 0) children[0].remove();
		while (traits.length > 0) traits[0].remove();
		if (parent != null) parent.children.remove(this);
		parent = null;
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

	public function setupAnimation(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>, speeds:Array<Float>, loops:Array<Bool>, reflects:Array<Bool>) {
		animation = Animation.setupNodeAnimation(this, startTrack, names, starts, ends, speeds, loops, reflects);
	}

	public inline function setAnimationParams(delta:Float) {
		animation.setAnimationParams(delta);
	}
}
