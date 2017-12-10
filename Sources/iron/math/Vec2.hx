package iron.math;

class Vec2 {
	public var x:Float;
	public var y:Float;

	public function new(x:Float = 0.0, y:Float = 0.0) {
		this.x = x;
		this.y = y;
	}

	public function cross(v:Vec2):Float {
		return x * v.y - y * v.x;
	}
	
	public function set(x:Float, y:Float):Vec2{
		this.x = x;
		this.y = y;
		return this;
	}

	public function add(v:Vec2):Vec2 {
		x += v.x;
		y += v.y;
		return this;
	}

	public function addf(x:Float, y:Float):Vec2 {
		this.x += x;
		this.y += y;
		return this;
	}

	public function addvecs(a:Vec2, b:Vec2):Vec2 {
		x = a.x + b.x;
		y = a.y + b.y;
		return this;
	}

	public function subvecs(a:Vec2, b:Vec2):Vec2 {
		x = a.x - b.x;
		y = a.y - b.y;
		return this;
	}

	public function normalize():Vec2 {
		var a = this.x;
        var b = this.y;
        var l = a * a + b * b;
        if(l > 0.0) {
            l = 1.0 / Math.sqrt(l);
            this.x = a * l;
            this.y = b * l;
        }
        return this;
	}

	public function mult(f:Float):Vec2 {
		x *= f; y *= f;
		return this;
	}

	public function dot(v:Vec2):Float {
		return x * v.x + y * v.y;
	}
	
	public function setFrom(v:Vec2):Vec2 {
		x = v.x; y = v.y;
		return this;
	}

	public function clone():Vec2 {
		return new Vec2(x, y);
	}
	
	public static function lerp(v1:Vec2, v2:Vec2, t:Float):Vec2 {
		var target = new Vec2();
		target.x = v2.x + (v1.x - v2.x) * t;
		target.y = v2.y + (v1.y - v2.y) * t;
		return target;
	}

	public inline function equals(v:Vec2):Bool {
		return x == v.x && y == v.y;
	}

	public inline function length():Float {
		return Math.sqrt(x * x + y * y);
	}

	public function sub(v:Vec2):Vec2 {
		x -= v.x; y -= v.y;
		return this;
	}

	public static inline function distance(v1:Vec2, v2:Vec2):Float {
		return distancef(v1.x, v1.y, v2.x, v2.y);
	}

	public static inline function distancef(v1x:Float, v1y:Float, v2x:Float, v2y:Float):Float {
		var vx = v1x - v2x;
		var vy = v1y - v2y;
		return Math.sqrt(vx * vx + vy * vy);
	}

	public function distanceTo(p:Vec2):Float {
		return Math.sqrt((p.x - x) * (p.x - x) + (p.y - y) * (p.y - y));
	}

	public static function xAxis():Vec2 { return new Vec2(1.0, 0.0); }
	public static function yAxis():Vec2 { return new Vec2(0.0, 1.0); }
	public static function one():Vec2 { return new Vec2(1.0, 1.0); }
	public static function zero():Vec2 { return new Vec2(0.0, 0.0); }
	public static function back():Vec2 { return new Vec2(0.0, -1.0); }
	public static function forward():Vec2 { return new Vec2(0.0, 1.0); }
	public static function left():Vec2 { return new Vec2(-1.0, 0.0); }
	public static function right():Vec2 { return new Vec2(1.0, 0.0); }
	public static function negativeInfinity():Vec2 { return new Vec2(Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY); }
	public static function positiveInfinity():Vec2 { return new Vec2(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY); }

	public function toString():String {
		return "(" + this.x + ", " + this.y + ")";
	}
}
