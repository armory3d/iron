package wings.trait;

import kha.Color;
import kha.Rotation;

import wings.math.Mat4;
import wings.math.Vec3;
import wings.math.Quat;
import wings.core.Object;
import wings.core.Trait;
import wings.core.IUpdateTrait;

class Transform extends Trait implements IUpdateTrait {

	public var modified:Bool;

	// Properties
	public var matrix:Mat4;

	public var pos:Vec3;
	public var rot:Quat;
	public var rotation:Rotation;
	public var scale:Vec3;

	public var size:Vec3;

	public var color:Color;

	// Shortcuts
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var z(get, set):Float;

	public var absx(get, null):Float;
	public var absy(get, null):Float;
	public var absz(get, null):Float;

	public var w(get, set):Float;
	public var h(get, set):Float;
	public var d(get, set):Float;

	public var r(get, set):Float;
	public var g(get, set):Float;
	public var b(get, set):Float;
	public var a(get, set):Float;
	public var val(get, set):Int;

	public function new() {
		super();

		reset();
	}

	public function update() {
		if (modified) {
			modified = false;

			buildMatrix();
			//updateSize();

			for (c in group.children) {
				if (Std.is(c, Object)) cast(c, Object).transform.modified = true;
			}
		}
	}

	public function reset() {

		matrix = new Mat4();

		pos = new Vec3();
		rot = new Quat();
		rotation = new Rotation(new kha.math.Vector2(0, 0), 0);
		scale = new Vec3(1, 1, 1);

		size = new Vec3();

		color = Color.fromValue(0xffffffff);

		modified = true;
	}

	function buildMatrix() {
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
		matrix._41 = pos.x;
		matrix._42 = pos.y;
		matrix._43 = pos.z;

		if (Std.is(item.parentItem, Object)) {
			matrix.multiply3x4(matrix, cast(item.parentItem, Object).transform.matrix);
		}
	}

	inline function get_x():Float { return pos.x; }

	inline function set_x(f:Float):Float { modified = true; return pos.x = f; }

	inline function get_y():Float { return pos.y; }

	inline function set_y(f:Float):Float { modified = true; return pos.y = f; }

	inline function get_z():Float { return pos.z; }

	inline function set_z(f:Float):Float { modified = true; return pos.z = f; }


	inline function get_absx():Float { return matrix._41; }

	inline function get_absy():Float { return matrix._42; }

	inline function get_absz():Float { return matrix._43; }


	inline function get_w():Float { return size.x; }

	inline function set_w(f:Float):Float { modified = true; return size.x = f; }

	inline function get_h():Float { return size.y; }

	inline function set_h(f:Float):Float { modified = true; return size.y = f; }

	inline function get_d():Float { return size.z; }

	inline function set_d(f:Float):Float { modified = true; return size.z = f; }


	inline function get_r():Float { return pos.x; }

	inline function set_r(f:Float):Float { modified = true; return color.R = f; }

	inline function get_g():Float { return color.G; }

	inline function set_g(f:Float):Float { modified = true; return color.G = f; }

	inline function get_b():Float { return color.B; }

	inline function set_b(f:Float):Float { modified = true; return color.B = f; }

	inline function get_a():Float { return color.A; }

	inline function set_a(f:Float):Float { modified = true; return color.A = f; }

	inline function get_val():Int { return color.value; }

	inline function set_val(i:Int):Int { modified = true; return color.value = i; }
}
