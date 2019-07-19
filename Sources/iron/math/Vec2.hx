package iron.math;

import kha.FastFloat;

class Vec2 {
	public var x:FastFloat;
	public var y:FastFloat;

	inline public function new(x:FastFloat = 0.0, y:FastFloat = 0.0) {
		this.x = x;
		this.y = y;
	}

	inline public function cross(v:Vec2):FastFloat {
		return x * v.y - y * v.x;
	}
	
	inline public function set(x:FastFloat, y:FastFloat):Vec2{
		this.x = x;
		this.y = y;
		return this;
	}

	inline public function add(v:Vec2):Vec2 {
		x += v.x;
		y += v.y;
		return this;
	}

	inline public function addf(x:FastFloat, y:FastFloat):Vec2 {
		this.x += x;
		this.y += y;
		return this;
	}

	inline public function addvecs(a:Vec2, b:Vec2):Vec2 {
		x = a.x + b.x;
		y = a.y + b.y;
		return this;
	}

	inline public function subvecs(a:Vec2, b:Vec2):Vec2 {
		x = a.x - b.x;
		y = a.y - b.y;
		return this;
	}

	inline public function normalize():Vec2 {
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

	inline public function mult(f:FastFloat):Vec2 {
		x *= f;
		y *= f;
		return this;
	}

	inline public function dot(v:Vec2):FastFloat {
		return x * v.x + y * v.y;
	}
	
	inline public function setFrom(v:Vec2):Vec2 {
		x = v.x;
		y = v.y;
		return this;
	}

	inline public function clone():Vec2 {
		return new Vec2(x, y);
	}
	
	inline public function lerp(from:Vec2, to:Vec2, s:FastFloat):Vec2 {
		x = from.x + (to.x - from.x) * s;
		y = from.y + (to.y - from.y) * s;
		return this;
	}

	inline public function slerp(from:Vec2, to:Vec2, s:FastFloat):Vec2 {
		var fromx = from.x;
		var fromy = from.y;
		var dot = from.dot(to) / (from.length() * to.length());
		if (dot < 0) {
			fromx = -fromx;
			fromy = -fromy;
			dot = -dot;
		}
		if (dot > 0.9995) {
			x = fromx + (to.x - fromx) * s;
			y = fromy + (to.y - fromy) * s;
			return this;
		}
		var theta = Math.acos(dot);
		var f = Math.sin(theta * s) / Math.sin(theta);
		var s = Math.cos(theta * s) - dot * f;
		x = s * fromx + f * to.x;
		y = s * fromy + f * to.y;
		return this;
	}

	inline public function equals(v:Vec2):Bool {
		return x == v.x && y == v.y;
	}

	inline public function length():FastFloat {
		return Math.sqrt(x * x + y * y);
	}

	inline public function sub(v:Vec2):Vec2 {
		x -= v.x;
		y -= v.y;
		return this;
	}

	public static inline function distance(v1:Vec2, v2:Vec2):FastFloat {
		return distancef(v1.x, v1.y, v2.x, v2.y);
	}

	public static inline function distancef(v1x:FastFloat, v1y:FastFloat, v2x:FastFloat, v2y:FastFloat):FastFloat {
		var vx = v1x - v2x;
		var vy = v1y - v2y;
		return Math.sqrt(vx * vx + vy * vy);
	}

	inline public function distanceTo(p:Vec2):FastFloat {
		return Math.sqrt((p.x - x) * (p.x - x) + (p.y - y) * (p.y - y));
	}

	inline public function clamp(min:FastFloat, max:FastFloat):Vec2 {
		var l = length();
		if (l < min) normalize().mult(min);
		else if (l > max) normalize().mult(max);
		return this;
	}

	public static inline function xAxis():Vec2 { return new Vec2(1.0, 0.0); }
	public static inline function yAxis():Vec2 { return new Vec2(0.0, 1.0); }
	
	public function toString():String {
		return "(" + this.x + ", " + this.y + ")";
	}
}
