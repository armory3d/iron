package lue.math;

// https://github.com/mrdoob/three.js/
// https://github.com/schteppe/cannon.js
// https://github.com/ncannasse/h3d

import kha.math.Vector2;

class Math {
	
	public static inline var PI = 3.14159265358979323;
	public static inline var EPSILON = 1e-10;

	public static inline var Rad2Deg = 180.0 / PI;    
	public static inline var Deg2Rad = PI / 180.0;
	
	// Round to 4 significant digits, eliminates < 1e-10
	public static function fmt(v:Float ) {
		var neg;
		if (v < 0) {
			neg = -1.0;
			v = -v;
		}
		else
			neg = 1.0;

		if (std.Math.isNaN(v))
			return v;

		var digits = Std.int(4 - std.Math.log(v) / std.Math.log(10));
		if (digits < 1)
			digits = 1;
		else if (digits >= 10)
			return 0.0;

		var exp = std.Math.pow(10, digits);
		return std.Math.floor(v * exp + 0.49999) * neg / exp;
	}

	public static inline function invSqrt(f:Float) {
		return 1.0 / std.Math.sqrt(f);
	}
	
	public static inline function clamp(f:Float, min = 0.0, max = 1.0) {
		return f < min ? min : f > max ? max : f;
	}
	
	public static inline function abs(f:Float) {
		return f < 0 ? -f : f;
	}

	public static inline function max(a:Float, b:Float) {
		return a < b ? b : a;
	}

	public static inline function min(a:Float, b:Float ) {
		return a > b ? b : a;
	}
	
	public static inline function iabs(i:Int) {
		return i < 0 ? -i : i;
	}

	public static inline function imax(a:Int, b:Int) {
		return a < b ? b : a;
	}

	public static inline function imin(a:Int, b:Int) {
		return a > b ? b : a;
	}

	public static inline function iclamp(v:Int, min:Int, max:Int) {
		return v < min ? min : (v > max ? max : v);
	}

	// Linear interpolation between two values. When k is 0 a is returned, when it's 1, b is returned.
	public inline static function lerp(a:Float, b:Float, k:Float) {
		return a + k * (b - a);
	}
	
	public inline static function bitCount(v:Int) {
		var k = 0;
		while (v != 0) {
			k += v & 1;
			v >>>= 1;
		}
		return k;
	}
	
	// Linear interpolation between two colors (ARGB)
	public static function colorLerp(c1:Int, c2:Int, k:Float) {
		var a1 = c1 >>> 24;
		var r1 = (c1 >> 16) & 0xFF;
		var g1 = (c1 >> 8) & 0xFF;
		var b1 = c1 & 0xFF;
		var a2 = c2 >>> 24;
		var r2 = (c2 >> 16) & 0xFF;
		var g2 = (c2 >> 8) & 0xFF;
		var b2 = c2 & 0xFF;
		var a = Std.int(a1 * (1-k) + a2 * k);
		var r = Std.int(r1 * (1-k) + r2 * k);
		var g = Std.int(g1 * (1-k) + g2 * k);
		var b = Std.int(b1 * (1 - k) + b2 * k);
		return (a << 24) | (r << 16) | (g << 8) | b;
	}
	
	// Clamp an angle into the [-PI,+PI] range. Can be used to measure the direction between two angles : if Math.angle(A-B) < 0 go left else go right.
	public static inline function angle(da:Float) {
		da %= PI * 2;
		if (da > PI) da -= 2 * PI else if (da <= -PI) da += 2 * PI;
		return da;
	}

	public static inline function angleLerp(a:Float, b:Float, k:Float) {
		return a + angle(b - a) * k;
	}
	
	// Move angle a towards angle b with a max increment. Return the new angle.
	public static inline function angleMove(a:Float, b:Float, max:Float) {
		var da = angle(b - a);
		return if (da > -max && da < max) b else a + (da < 0 ? -max : max);
	}

	// Converts specified angle in radians to degrees.
	// Returns angle in degrees (not normalized to 0...360)
	public inline static function radToDeg(rad:Float):Float {
	    return 180 / Math.PI * rad;
	}

	// Converts specified angle in degrees to radians.
	// Returns angle in radians (not normalized to 0...Math.PI*2)
	public inline static function degToRad(deg:Float):Float {
	    return Math.PI / 180 * deg;
	}

	public inline static function mix(a:Float, b:Float, k:Float):Float {
		return a * (1.0 - k) + b * k;
	}

	static function sign(p1:Vector2, p2:Vector2, p3:Vector2):Float {
	  return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
	}

	public static inline function distance1d(x1:Float, x2:Float) {
        return std.Math.abs(x2 - x1);
    }

    public static function distance2d(x1:Float, y1:Float, x2:Float, y2:Float):Float {
        return std.Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
    }

    public static function distance3d(v1:Vec4, v2:Vec4):Float {
        var vx = v1.x - v2.x;
        var vy = v1.y - v2.y;
        var vz = v1.z - v2.z;
        return std.Math.sqrt(vx * vx + vy * vy + vz * vz);
    }

    public static function planeDotCoord(planeNormal:Vec4, point:Vec4, planeDistance:Float):Float {
        // Point is in front of plane if > 0
        return planeNormal.dot(point) + planeDistance;
    }
}
