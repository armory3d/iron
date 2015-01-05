package fox.trait;

import kha.Color;
import fox.math.Mat4;
import fox.math.Vec3;
import fox.math.Quat;
import fox.core.Object;
import fox.core.Trait;
import fox.core.IUpdateable;

class Transform extends Trait implements IUpdateable {

	public var modified:Bool;
	public var resized:Bool;

	// Properties
	public var matrix:Mat4;

	public var pos:Vec3;
	public var rot:Quat;
	public var scale:Vec3;
	
	public var size:Vec3;
	public var absSize:Vec3;

	public var color:Color;

	public var anchor:Vec3;

	// Position
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;

	public var absx(get, null):Float;
	public var absy(get, null):Float;
	public var absz(get, null):Float;

	// Size
	public var w(get, set):Float;
	public var h(get, set):Float;
	public var d(get, set):Float;

	public var absw(get, never):Float;
	public var absh(get, never):Float;
	public var absd(get, never):Float;

	// Color
	public var r(get, set):Float;
	public var g(get, set):Float;
	public var b(get, set):Float;
	public var a(get, set):Float;
	public var val(get, set):Int;

	// Anchor
	public var ax(get, set):Float;
	public var ay(get, set):Float;
	public var az(get, set):Float;

	// Rigid body
	@inject
	var rigidBody:RigidBody;

	public function new() {
		super();
		reset();
	}

	@injectAdd({desc:true,sibl:false})
    public function addTransform(trait:Transform) { resized = true; }

    @injectRemove({desc:true,sibl:false})
    public function removeTransform(trait:Transform) { resized = true; }

	public function update() {
		if (modified) {
			modified = false;

			buildMatrix();

			// Update parent size
			if (Std.is(item.parentItem, Object)) cast(item.parentItem, Object).transform.resized = true;

			// Update children
			for (c in group.children) {
				if (Std.is(c, Object)) {
					cast(c, Object).transform.modified = true;
					cast(c, Object).transform.update();
				}
			}
		}

		if (resized) {
			updateSize();

			// Update parent
			if (Std.is(item.parentItem, Object)) cast(item.parentItem, Object).transform.resized = true;
		}
	}

	public function reset() {
		matrix = new Mat4();

		pos = new Vec3();
		rot = new Quat();
		scale = new Vec3(1, 1, 1);

		size = new Vec3();
		absSize = new Vec3();

		color = Color.fromValue(0xffffffff);

		anchor = new Vec3();

		modified = true;
	}

	public function buildMatrix() {
		rot.saveToMatrix(matrix);
		matrix._11 *= scale.x;
		matrix._12 *= scale.x;
		matrix._13 *= scale.x;
		matrix._21 *= scale.y;
		matrix._22 *= scale.y;
		matrix._23 *= scale.y;
		matrix._31 *= scale.z;
		matrix._32 *= scale.z;
		matrix._33 *= scale.z;
		matrix._41 = pos.x - anchor.x * size.x;
		matrix._42 = pos.y - anchor.y * size.y;
		matrix._43 = pos.z - anchor.z * size.z;

		if (Std.is(item.parentItem, Object)) {
			matrix.multiply3x4(matrix, cast(item.parentItem, Object).transform.matrix);
		}
	}

	public function updateSize() {
		resized = false;

		// 2D only
		var left = absx;
		var top = absy;
		var right = left + (w * scale.x);
		var bottom = top + (h * scale.y);

		for (c in group.children) {

			var child = cast(c, Object).transform;

			if (child.absx < left) left = child.absx;
			else if (child.absx + (child.w * child.scale.x) > right) right = child.absx + (child.w * child.scale.x);

			if (child.absy < top) top = child.absy;
			else if (child.absy + (child.h * child.scale.y) > bottom) bottom = child.absy + (child.h * child.scale.y);
		}

		absSize.x = right - left;
		absSize.y = bottom - top;
	}

	public function hitTest(x:Float, y:Float):Bool {
		// 2D only
		if (x > this.absx /* * parent.scaleX*/ && x <= this.absx /* * parent.scaleX */+ w * scale.x &&
			y > this.absy /* * parent.scaleY*/ && y <= this.absy /* * parent.scaleY */+ h * scale.y) {
			return true;
		}

		return false;
	}

	public function rotate(x:Float, y:Float, z:Float) {
		var q = new Quat();
		q.setFromEuler(x, y, z);
		rot.multiply(q, rot);
		modified = true;
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

	public function setRotation(x:Float, y:Float, z:Float) {
		rot.setFromEuler(x, y, z, "ZXY");
		modified = true;
	}

	public function getEuler():Vec3 {
		var v = new Vec3();
		rot.toEuler(v);
		return v;
	}

	public function setEuler(v:Vec3) {
		rot.setFromEuler(v.x, v.y, v.z);
		modified = true;
	}


	// Positions
	inline function get_x():Float { return pos.x; }

	inline function set_x(f:Float):Float { modified = true; return pos.x = f; }

	inline function get_y():Float { return pos.y; }

	inline function set_y(f:Float):Float { modified = true; return pos.y = f; }

	inline function get_z():Float { return pos.z; }

	inline function set_z(f:Float):Float { modified = true; return pos.z = f; }


	inline function get_absx():Float { return matrix._41; }

	inline function get_absy():Float { return matrix._42; }

	inline function get_absz():Float { return matrix._43; }


	// Size
	inline function get_w():Float { return size.x; }

	inline function set_w(f:Float):Float { resized = true; return size.x = f; }

	inline function get_h():Float { return size.y; }

	inline function set_h(f:Float):Float { resized = true; return size.y = f; }

	inline function get_d():Float { return size.z; }

	inline function set_d(f:Float):Float { resized = true; return size.z = f; }


	inline function get_absw():Float { return absSize.x; }

	inline function get_absh():Float { return absSize.y; }

	inline function get_absd():Float { return absSize.z; }


	// Color
	inline function get_r():Float { return color.R; }

	inline function set_r(f:Float):Float { modified = true; return color.R = f; }

	inline function get_g():Float { return color.G; }

	inline function set_g(f:Float):Float { modified = true; return color.G = f; }

	inline function get_b():Float { return color.B; }

	inline function set_b(f:Float):Float { modified = true; return color.B = f; }

	inline function get_a():Float { return color.A; }

	inline function set_a(f:Float):Float { modified = true; return color.A = f; }

	inline function get_val():Int { return color.value; }

	inline function set_val(i:Int):Int { modified = true; return color.value = i; }


	// Anchor
	inline function get_ax():Float { return anchor.x; }

	inline function set_ax(f:Float):Float { modified = true; return anchor.x = f; }

	inline function get_ay():Float { return anchor.y; }

	inline function set_ay(f:Float):Float { modified = true; return anchor.y = f; }

	inline function get_az():Float { return anchor.z; }

	inline function set_az(f:Float):Float { modified = true; return anchor.z = f; }
}
