package wings.w2d;

import kha.Painter;
import kha.Color;
import kha.Rotation;
import wings.wxd.EventListener;

class Object2D extends EventListener {

	public var parent:Object2D;
	public var children:Array<Object2D>;

	// Relative and absolute transforms
	// TODO: transform origin
	public var rel:Transform;
	public var abs:Transform;

	// Handy access to relative transform
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var rotation(get, set):Rotation;
	public var w(get, set):Float;
	public var h(get, set):Float;
	public var scale(get, set):Float;
	public var scaleX(get, set):Float;
	public var scaleY(get, set):Float;

	public var color(get, set):Color;
	public var r(get, set):Float;
	public var g(get, set):Float;
	public var b(get, set):Float;
	public var a(get, set):Float;

	public var visible:Bool;

	// TODO: Take pos in constructor
	public function new() {
		
		parent = null;
		rel = new Transform(this);
		abs = new Transform(this);

		super();
		reset();	// TODO: reset called in super class
	}

	public override function update() {

		super.update();

		// Children on top receive events first
		var i = children.length - 1;
		while (i >= 0) {
			if (children[i] != null) children[i].update();
			i--;
		}
	}

	public function render(painter:Painter) {

		// Update transform
		if (rel.changed || abs.changed) {
			updateTransform();
		}

		for (i in 0...children.length) if (children[i] != null) children[i].render(painter);
	}

	public function addChild(child:Object2D) {
		children.push(child);
		child.parent = this;

		// Calc abs size
		var p = this;
		// TODO: do recursively for every children
		while (p != null) { 
			updateTransform();
			updateSize();
			p = p.parent;
		}
	}

	public function removeChild(child:Object2D) {
		if (children.remove(child))
			child.parent = null;
	}

	public function remove() {
		if (parent != null) parent.removeChild(this);
	}

	public override function reset() {
		super.reset();

		children = new Array();
		rel.reset();
		abs.reset();

		visible = true;
	}

	public function updateSize() {

		// Calc abs size // TODO: switch with rel
		var left = abs.x;
		var top = abs.y;
		var right = w + left;
		var bottom = h + top;

		for (i in 0...children.length) {

			// TODO: update all children recursively
			var child = children[i];

			if (child.abs.x < left) left = child.abs.x;
			else if (child.abs.x + child.w > right) right = child.abs.x + child.w;

			if (child.abs.y < top) top = child.abs.y;
			else if (child.abs.y + child.h > bottom) bottom = child.abs.y + child.h;
		}

		w = right - left;
		h = bottom - top;
	}

	public function updateTransform() {

		// Calculate transforms
		// TODO: separate rel & abs changes
		abs.x = rel.x;
		abs.y = rel.y;
		abs.rotation.angle = rel.rotation.angle;
		abs.rotation.center.x = rel.rotation.center.x;
		abs.rotation.center.y = rel.rotation.center.y;
		abs.scaleX = rel.scaleX;
		abs.scaleY = rel.scaleY;
		var colorR = rel.color.R;
		var colorG = rel.color.G;
		var colorB = rel.color.B;
		var colorA = rel.color.A;

		var p:Object2D = parent;
		if (p != null) {

			// Pos
			abs.x += p.abs.x;
			abs.y += p.abs.y;

			// Rotation
			// TODO: rotation center
			abs.rotation.angle += p.abs.rotation.angle;

			// Scale
			abs.scaleX *= p.abs.scaleX;
			abs.scaleY *= p.abs.scaleY;

			// Color
			colorR *= p.abs.color.R;
			colorG *= p.abs.color.G;
			colorB *= p.abs.color.B;
			colorA *= p.abs.color.A;
		}

		abs.color = Color.fromFloats(colorR, colorG, colorB, colorA);
		abs.x = Std.int(abs.x);
		abs.y = Std.int(abs.y);

		// Update children
		for (i in 0...children.length) {
			children[i].updateTransform();
		}

		rel.changed = false;
		abs.changed = false;
	}

	public function moveInDirection(deltaX:Float, deltaY:Float) {
		x += deltaX * Math.cos(rotation.angle);
		y += deltaY * Math.sin(rotation.angle);
	}

	inline function get_x():Float { return rel.x; }
	inline function set_x(f:Float):Float { return rel.x = f; }

	inline function get_y():Float { return rel.y; }
	inline function set_y(f:Float):Float { return rel.y = f; }

	inline function get_rotation():Rotation { return rel.rotation; }
	inline function set_rotation(r:Rotation):Rotation { return rel.rotation = r; }

	function get_w():Float { return abs.w; }
	function set_w(f:Float):Float { return abs.w = f; }

	function get_h():Float { return abs.h; }
	function set_h(f:Float):Float { return abs.h = f; }

	inline function get_scale():Float { return rel.scale; }
	inline function set_scale(f:Float):Float { return rel.scale = f; }

	inline function get_scaleX():Float { return rel.scaleX; }
	inline function set_scaleX(f:Float):Float { return rel.scaleX = f; }

	inline function get_scaleY():Float { return rel.scaleY; }
	inline function set_scaleY(f:Float):Float { return rel.scaleY = f; }

	inline function get_color():Color { return rel.color; }
	inline function set_color(c:Color):Color { return rel.color = c; }

	inline function get_r():Float { return rel.r; }
	inline function set_r(f:Float):Float { return rel.r = f; }

	inline function get_g():Float { return rel.g; }
	inline function set_g(f:Float):Float { return rel.g = f; }

	inline function get_b():Float { return rel.b; }
	inline function set_b(f:Float):Float { return rel.b = f; }

	inline function get_a():Float { return rel.a; }
	inline function set_a(f:Float):Float { return rel.a = f; }

	public inline function hitTest(x:Float, y:Float):Bool { return abs.hitTest(x, y); }
}
