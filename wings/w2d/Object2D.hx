package wings.w2d;

import kha.Painter;
import kha.Color;
import kha.Rotation;
import wings.wxd.EventListener;

class Object2D extends EventListener {

	public var parent:Object2D;
	public var children:Array<Object2D>;

	// Relative and absolute transforms
	public var rel:Transform;
	public var abs:Transform;

	// Handy access to relative transform
	public var x(get, set):Float;
	public var y(get, set):Float;
	public var rotation(get, set):Rotation;
	public var w(get, set):Float;
	public var h(get, set):Float;
	public var scaleX(get, set):Float;
	public var scaleY(get, set):Float;
	public var color(get, set):Color;

	// TODO: Take pos in constructor
	public function new() {
		
		parent = null;
		rel = new Transform();
		abs = new Transform();

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

		// TODO: calc in updateTransform
		if (child.w > w) w = child.w;
		if (child.h > h) h = child.h;
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
	}

	public function updateTransform() {

		// Calculate transforms
		// TODO: separate rel & abs changes
		abs.x = rel.x;
		abs.y = rel.y;
		abs.rotation.angle = rel.rotation.angle;
		abs.rotation.center.x = rel.rotation.center.x;
		abs.rotation.center.y = rel.rotation.center.y;
		abs.w = rel.w;
		abs.h = rel.h;
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

			// Size
			// TODO: proper nested size calculation
			if (abs.w > p.abs.w) p.abs.w = abs.w;
			if (abs.h > p.abs.h) p.abs.h = abs.h;

			// Scale
			abs.scaleX *= p.abs.scaleX;
			abs.scaleX *= p.abs.scaleY;

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
			//children[i].rel.changed = true;
			//children[i].abs.changed = true;
		}

		rel.changed = false;
		abs.changed = false;
	}

	inline function get_x():Float { return rel.x; }
	inline function set_x(f:Float):Float { return rel.x = f; }

	inline function get_y():Float { return rel.y; }
	inline function set_y(f:Float):Float { return rel.y = f; }

	inline function get_rotation():Rotation { return rel.rotation; }
	inline function set_rotation(r:Rotation):Rotation { return rel.rotation = r; }

	inline function get_w():Float { return rel.w; }
	inline function set_w(f:Float):Float { return rel.w = f; }

	inline function get_h():Float { return rel.h; }
	inline function set_h(f:Float):Float { return rel.h = f; }

	inline function get_scaleX():Float { return rel.scaleX; }
	inline function set_scaleX(f:Float):Float { return rel.scaleX = f; }

	inline function get_scaleY():Float { return rel.scaleY; }
	inline function set_scaleY(f:Float):Float { return rel.scaleY = f; }

	inline function get_color():Color { return rel.color; }
	inline function set_color(c:Color):Color { return rel.color = c; }

	public inline function hitTest(x:Float, y:Float):Bool { return abs.hitTest(x, y); }
}
