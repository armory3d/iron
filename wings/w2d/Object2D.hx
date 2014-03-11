package wings.w2d;

import kha.Painter;
import wings.wxd.EventListener;

class Object2D extends EventListener {

	public var parent:Object2D;

	public var children:Array<Object2D>;

	public var x:Float;
	public var y:Float;
	public var w:Float;
	public var h:Float;
	public var a:Float;

	// Actual pos
	public var _x:Float;
	public var _y:Float;

	public var rotation:Float;

	public function new() {
		super();
		reset();
		parent = null;
	}

	public override function update() {

		super.update();
		_updatePos();

		// Children on top receive events first
		var i = children.length - 1;
		while (i >= 0) {
			if (children[i] != null) children[i].update();
			i--;
		}
	}

	public function render(painter:Painter) {

		for (i in 0...children.length) if (children[i] != null) children[i].render(painter);
	}

	public function addChild(child:Object2D) {
		children.push(child);
		child.parent = this;
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

		x = y = w = h = 0;
		a = 1;
		rotation = 0;
	}

	public function hitTest(x:Float, y:Float):Bool {
		if (x >= this._x && x <= this._x + w &&
			y >= this._y && y <= this._y + h) {
			return true;
		}

		return false;
	}

	function _updatePos() {
		_x = x;
		_y = y;

		var p:Object2D = parent;
		while (p != null) {
			_x += p.x;
			_y += p.y;
			p = p.parent;
		}

		_x = Std.int(_x);
		_y = Std.int(_y);
	}
}
