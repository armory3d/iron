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

	public var animation:Animation = null;
	public var visible = true; // Skip render, keep updating
	public var visibleMesh = true;
	public var visibleShadow = true;
	public var culled = false; // Object was culled last frame
	public var culledMesh = false;
	public var culledShadow = false;
	public var properties:Map<String, Dynamic> = null;
	var isEmpty = false;

	public function new() {
		uid = uidCounter++;
		urandom = seededRandom(); //Math.random();
		transform = new Transform(this);
		isEmpty = Type.getClass(this) == Object;
		if (isEmpty && Scene.active != null) Scene.active.empties.push(this);
	}
	
	public function addChild(o:Object, parentInverse = false) {
		if (o.parent == this) return;
		children.push(o);
		o.parent = this;
		if (parentInverse) o.transform.applyParentInverse();
	}

	public function removeChild(o:Object, keepTransform = false) {
		if (keepTransform) o.transform.applyParent();
		o.parent = null;
		o.transform.buildMatrix();
		children.remove(o);
	}

	public function removeChildWithName(name:String, keepTransform = false){
		var childToRemove = this.getChild(name);
		if (childToRemove != null){
			removeChild(childToRemove, keepTransform);
			return true;
		}
		return false;
	}

	/**
	 * Removes the game object from the scene.
	 */
	public function remove() {
		if (isEmpty && Scene.active != null) Scene.active.empties.remove(this);
		if (animation != null) animation.remove();
		while (children.length > 0) children[0].remove();
		while (traits.length > 0) traits[0].remove();
		if (parent != null) { parent.children.remove(this); parent = null; }
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

	@:access(iron.Trait)
	public function addTrait(t:Trait) {
		traits.push(t);
		t.object = this;

		if (t._add != null) {
			for (f in t._add) f();
			t._add = null;
		}
	}

	@:access(iron.Trait)
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
	}

	/**
	 * Returns the instance of the Trait attached to the Game Object. 
	 *
	 * @param	c - The class of type Trait to attempt to retrieve.
	 * @return	Returns the requested Trait or null if it does not exsist.
	 */
	public function getTrait<T:Trait>(c:Class<T>):T {
		for (t in traits) if (Type.getClass(t) == cast c) return cast t;
		return null;
	}

	#if arm_skin
	public function getParentArmature(name:String):BoneAnimation {
		for (a in Scene.active.animations) if (a.armature != null && a.armature.name == name) return cast a;
		return null;
	}
	#end

	public function setupAnimation(oactions:Array<TSceneFormat> = null) {
		// Parented to bone
		#if arm_skin
		if (raw.parent_bone != null) {
			Scene.active.notifyOnInit(function() {
				var banim = getParentArmature(parent.name);
				if (banim != null) banim.addBoneChild(raw.parent_bone, this);
			});
		}
		#end
		// Object actions
		if (oactions == null) return;
		animation = new ObjectAnimation(this, oactions);
	}

	static var seed = 1; // cpp / js not consistent
	static function seededRandom():Float {
		seed = (seed * 9301 + 49297) % 233280;
		return seed / 233280.0;
	}

	public function toString():String { return "Object " + name; }
}
