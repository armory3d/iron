package wings.w3d;

import kha.Painter;
import wings.math.Mat4;
import wings.math.Vec3;
import wings.math.Quat;
import wings.wxd.EventListener;

class Object extends EventListener {

	//public var skinMatrixes:Array<Mat4>;

	public var modelMatrix:Mat4;
	public var mvpMatrix:Mat4;
	public var rebuildMatrix:Bool;

	public var position:Vec3;
	public var rotation:Quat;
	public var scale:Vec3;
	public var size:Vec3;

	public var defaultTransform(default, set):Mat4;
	public var currentAnimation(default, null):wings.w3d.anim.Animation;

	public var scene:Scene;
	public var parent:Object;

	public var name:String;
	public var children:Array<Object>;
	public var numChildren(get, never):Int;

	public function new(parent:Object = null) {
		super();
		size = new Vec3();

		reset();
		
		if (parent != null) {
			parent.addChild(this);
		}
	}

	public override function update() {
		super.update();
		for (i in 0...children.length) if (children[i] != null) children[i].update();
	}

	public function render(painter:Painter) {
		// Rebuild matrix
		if (rebuildMatrix) {
			//syncPos();
			buildMatrix();
		}

		// Update model-view-projection matrix
		mvpMatrix.identity();
		mvpMatrix.append(modelMatrix);
		if (scene != null) {
			mvpMatrix.append(scene.camera.viewMatrix);
			mvpMatrix.append(scene.camera.projectionMatrix);
		}

		for (i in 0...children.length) if (children[i] != null) children[i].render(painter);
	}

	public function addChild(child:Object) {
		children.push(child);
		child.parent = this;
		child.scene = scene;
	}

	public function removeChild(child:Object) {
		if (children.remove(child))
			child.parent = null;
	}

	public function remove() {
		if (parent != null) parent.removeChild(this);
	}

	public function getChildAt(pos:Int) {
		return children[pos];
	}

	public override function reset() {
		super.reset();
		children = new Array();

		modelMatrix = new Mat4();
		mvpMatrix = new Mat4();

		position = new Vec3(0, 0, 0);
		rotation = new Quat();
		scale = new Vec3(1, 1, 1);

		rebuildMatrix = true;
	}

	public function buildMatrix() {
		//modelMatrix.identity();
		//modelMatrix.appendScale(scale.x, scale.y, scale.z);
		//modelMatrix.append(new Mat4(rotation.toMatrix().getFloats()));
		//modelMatrix.appendTranslation(position.x, position.y, position.z);

		rotation.saveToMatrix(modelMatrix);
		modelMatrix._11 *= scale.x;
		modelMatrix._12 *= scale.x;
		modelMatrix._13 *= scale.x;
		modelMatrix._21 *= scale.y;
		modelMatrix._22 *= scale.y;
		modelMatrix._23 *= scale.y;
		modelMatrix._31 *= scale.z;
		modelMatrix._32 *= scale.z;
		modelMatrix._33 *= scale.z;
		modelMatrix._41 = position.x;
		modelMatrix._42 = position.y;
		modelMatrix._43 = position.z;

		if (defaultTransform != null)
			modelMatrix.multiply3x4(modelMatrix, defaultTransform);

		if (parent != null)
			modelMatrix.multiply3x4(modelMatrix, parent.modelMatrix);
	}

	function sync() {
	/*	if (currentAnimation != null) {
			var old = parent;
			var dt = wings.wxd.Time.delta / 5000;
			while( dt > 0 && currentAnimation != null )
				dt = currentAnimation.update(dt);
			if( currentAnimation != null )
				currentAnimation.sync();
			if( parent == null && old != null ) return; // if we were removed by an animation event
		}

		var changed = rebuildMatrix;
		if( changed ) {
			rebuildMatrix = false;
			buildMatrix();
		}

		//lastFrame = ctx.frame;
		var p = 0, len = children.length;
		while( p < len ) {
			var c = children[p];
			if( c == null )
				break;
			//if( c.lastFrame != ctx.frame ) {
				if( changed ) c.rebuildMatrix = true;
				c.sync();
			//}
			// if the object was removed, let's restart again.
			// our lastFrame ensure that no object will get synched twice
			if( children[p] != c ) {
				p = 0;
				len = children.length;
			} else
				p++;
		}*/
	}

	function syncPos() {
		//if( parent != null ) parent.syncPos();
		//if( rebuildMatrix ) {
		//	rebuildMatrix = false;
		//	buildMatrix();
		//	for (c in children)
		//		c.rebuildMatrix = true;
		//}
	}

	public function getObjectByName(name:String) {
		if(this.name == name)
			return this;

		for(c in children) {
			var d = c.getObjectByName(name);
			if(d != null) {
				return d;
			}
		}

		return null;
	}

	public function setPos(pos:Vec3) {
		position = pos;
		rebuildMatrix = true;
	}

	public function setPosition(x:Float = 0, y:Float = 0, z:Float = 0) {
		position.x = x;
		position.y = y;
		position.z = z;
		rebuildMatrix = true;
	}

	public inline function move(x:Float, y:Float, z:Float) {
		setPosition(position.x + x, position.y + y, position.z + z);
	}

	public function setRotation(x:Float, y:Float, z:Float) {
		rotation.initRotate(x, y, z);
		rebuildMatrix = true;
	}

	public function setRotationX(f:Float) {
		var rot = new Vec3();
		rotation.toEuler(rot);
		rot.x = f;
		setRotation(rot.x, rot.y, rot.z);
	}

	public function setRotationY(f:Float) {
		var rot = new Vec3();
		rotation.toEuler(rot);
		rot.y = f;
		setRotation(rot.x, rot.y, rot.z);
	}

	public function setRotationZ(f:Float) {
		var rot = new Vec3();
		rotation.toEuler(rot);
		rot.z = f;
		setRotation(rot.x, rot.y, rot.z);
	}

	public function setRotationQuat(q:Quat) {
		rotation = q;
		rebuildMatrix = true;
	}

	public function rotate(x:Float, y:Float, z:Float) {
		var q = new Quat();
		q.initRotate(x, y, z);
		rotation.multiply(q, rotation);
		rebuildMatrix = true;
	}

	public inline function rotateX(f:Float) {
		rotate(f, 0, 0);
	}

	public inline function rotateY(f:Float) {
		rotate(0, f, 0);
	}

	public inline function rotateZ(f:Float) {
		rotate(0, 0, f);
	}

	public function setScale(x:Float = 1, y:Float = 1, z:Float = 1) {
		scale.x = x;
		scale.y = y;
		scale.z = z;
		rebuildMatrix = true;
	}

	public function playAnimation( a : wings.w3d.anim.Animation ) {
		return currentAnimation = a.createInstance(this);
	}
	
	public function switchToAnimation( a : wings.w3d.anim.Animation ) {
		return currentAnimation = a;
	}
	
	public function stopAnimation() {
		currentAnimation = null;
	}

	inline function get_numChildren() {
		return children.length;
	}

	inline function set_defaultTransform(v) {
		defaultTransform = v;
		rebuildMatrix = true;
		return v;
	}
}
