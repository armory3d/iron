package fox.math;

// https://github.com/mrdoob/three.js/
// https://github.com/schteppe/cannon.js
// https://github.com/ncannasse/h3d

class Math {
	
	public static inline var PI = 3.14159265358979323;
	public static inline var EPSILON = 1e-10;

	static public var Rad2Deg = 180.0 / PI;    
	static public var Deg2Rad = PI / 180.0;

	public static var POSITIVE_INFINITY(get, never):Float;
	public static var NEGATIVE_INFINITY(get, never):Float;
	public static var NaN(get, never):Float;
	
	static inline function get_POSITIVE_INFINITY() {
		return std.Math.POSITIVE_INFINITY;
	}

	static inline function get_NEGATIVE_INFINITY() {
		return std.Math.NEGATIVE_INFINITY;
	}

	static inline function get_NaN() {
		return std.Math.NaN;
	}
	
	public static inline function isNaN(v:Float) {
		return std.Math.isNaN(v);
	}
	
	// round to 4 significant digits, eliminates < 1e-10
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

		var exp = pow(10, digits);
		return floor(v * exp + 0.49999) * neg / exp;
	}
	
	public static inline function floor(f : Float) {
		return std.Math.floor(f);
	}

	public static inline function ceil(f : Float) {
		return std.Math.ceil(f);
	}

	public static inline function round(f : Float) {
		return std.Math.round(f);
	}
	
	public static inline function clamp(f : Float, min = 0.0, max = 1.0) {
		return f < min ? min : f > max ? max : f;
	}

	public static inline function pow(v:Float, p:Float ) {
		return std.Math.pow(v,p);
	}
	
	public static inline function cos(f:Float) {
		return std.Math.cos(f);
	}

	public static inline function sin(f:Float) {
		return std.Math.sin(f);
	}

	public static inline function tan(f:Float) {
		return std.Math.tan(f);
	}

	public static inline function acos(f:Float) {
		return std.Math.acos(f);
	}

	public static inline function asin(f:Float) {
		return std.Math.asin(f);
	}

	public static inline function atan(f:Float) {
		return std.Math.atan(f);
	}
	
	public static inline function sqrt(f:Float) {
		return std.Math.sqrt(f);
	}

	public static inline function invSqrt(f:Float) {
		return 1.0 / sqrt(f);
	}
	
	public static inline function atan2(dy:Float, dx:Float) {
		return std.Math.atan2(dy, dx);
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

	public static inline function iclamp(v:Int, min:Int, max:Int ) {
		return v < min ? min : (v > max ? max : v);
	}

	/**
		Linear interpolation between two values. When k is 0 a is returned, when it's 1, b is returned.
	**/
	public inline static function lerp(a:Float, b:Float, k:Float) {
		return a + k * (b - a);
	}
	//static inline public function Lerp(p_a:Float, p_b:Float, p_ratio : Float):Float { return p_a + (p_b - p_a) * p_ratio; }
	
	public inline static function bitCount(v:Int) {
		var k = 0;
		while( v != 0 ) {
			k += v & 1;
			v >>>= 1;
		}
		return k;
	}
	
	public static inline function distanceSq(dx : Float, dy : Float, dz = 0.0) {
		return dx * dx + dy * dy + dz * dz;
	}
	
	public static inline function distance(dx : Float, dy : Float, dz = 0.0) {
		return sqrt(distanceSq(dx, dy, dz));
	}
	
	/**
		Linear interpolation between two colors (ARGB).
	**/
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
	
	/*
		Clamp an angle into the [-PI,+PI[ range. Can be used to measure the direction between two angles : if Math.angle(A-B) < 0 go left else go right.
	*/
	public static inline function angle(da:Float) {
		da %= PI * 2;
		if (da > PI) da -= 2 * PI else if (da <= -PI) da += 2 * PI;
		return da;
	}

	public static inline function angleLerp(a:Float, b:Float, k:Float) {
		return a + angle(b - a) * k;
	}
	
	/**
		Move angle a towards angle b with a max increment. Return the new angle.
	**/
	public static inline function angleMove(a:Float, b:Float, max:Float) {
		var da = angle(b - a);
		return if (da > -max && da < max) b else a + (da < 0 ? -max : max);
	}
	
	public inline static function random(max = 1.0) {
		return std.Math.random() * max;
	}
	
	/**
		Returns a signed random between -max and max (both included).
	**/
	public static function srand(max = 1.0) {
		return (std.Math.random() - 0.5) * (max * 2);
	}

	/**
	* Converts specified angle in radians to degrees.
	* @return angle in degrees (not normalized to 0...360)
	*/
	public inline static function radToDeg(rad:Float):Float {
	    return 180 / Math.PI * rad;
	}
	/**
	* Converts specified angle in degrees to radians.
	* @return angle in radians (not normalized to 0...Math.PI*2)
	*/
	public inline static function degToRad(deg:Float):Float {
	    return Math.PI / 180 * deg;
	}

	public inline static function mix(a:Float, b:Float, k:Float):Float {
		return a * (1.0 - k) + b * k;
	}


	static function sign(p1:Vec2, p2:Vec2, p3:Vec2):Float {
	  return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);
	}

	public static function pointInTriangle(point:Vec2, triangle:Tri2):Bool {
	  var b1, b2, b3:Bool;

	  b1 = sign(point, triangle.v1, triangle.v2) < 0.0;
	  b2 = sign(point, triangle.v2, triangle.v3) < 0.0;
	  b3 = sign(point, triangle.v3, triangle.v1) < 0.0;

	  return ((b1 == b2) && (b2 == b3));
	}

	/**
	 * ...
	 * @author Eduardo Pons - eduardo@thelaborat.org
	 */
	static inline public function Oscilate(p_v:Float, p_v0:Float, p_v1:Float) {			
        var w:Float = -Math.Abs(Loop(p_v - 1.0, -1.0, 1.0)) + 1.0;
        return Math.lerp(w, p_v0, p_v1);
	}

	static public function Loop(p_v:Float, p_v0:Float, p_v1:Float):Float { 
		var vv0:Float = Math.min(p_v0, p_v1);
		var vv1:Float = Math.max(p_v0, p_v1);
		var dv:Float = (vv1 - vv0);
		if (dv <= 0) return vv0;
		var n:Float  = (p_v - p_v0) / dv;			
		var r:Float  = p_v < 0 ? 1.0 - Math.Frac(Math.Abs(n)) : Math.Frac(n);			
		return Math.lerp(p_v0, p_v1, r); 
	}

	static inline public function Frac(p_v:Float):Float {
		return p_v - Math.Floor(p_v);
	}

	static public inline function Abs(p_a:Float):Float  {
		return p_a < 0 ? -p_a : p_a;
	}

	static inline public function Floor(p_v : Float):Float {
		return cast Std.int(p_v);
	}

	static public function Min(p_v:Array<Float>):Float {
        if (p_v.length <= 0) return 0;
		if (p_v.length <= 1) return p_v[0];
        var m:Float = p_v[0];
		var i:Int = 0;
		for (i in 1...p_v.length) {
			m = m > p_v[i] ? p_v[i] : m;
		}
        return m;
    }

    static public function Max(p_v:Array<Float>):Float {
        if (p_v.length <= 0) return 0;
		if (p_v.length <= 1) return p_v[0];
        var m:Float = p_v[0];
		var i:Int = 0;
		for (i in 1...p_v.length) {
			m = m < p_v[i] ? p_v[i] : m;
		}
        return m;
    }

    static public function MinInt(p_v:Array<Int>):Int {
        if (p_v.length <= 0) return 0;
		if (p_v.length <= 1) return p_v[0];
        var m:Int = p_v[0];
		var i:Int = 0;
		for (i in 1...p_v.length) {
			m = m > p_v[i] ? p_v[i] : m;
		}
        return Std.int(m);
    }

    static public inline function Clamp(p_v:Float, p_min:Float, p_max:Float):Float {
    	return p_v <= p_min ? p_min : (p_v>=p_max ? p_max : p_v);
    }

    static public inline function Clamp01(p_v:Float):Float {
    	return Clamp(p_v, 0.0, 1.0);
    }

    static public inline function ClampInt(p_v:Int, p_min:Int, p_max:Int):Int {
    	return Std.int(p_v <= p_min ? p_min : (p_v>=p_max ? p_max : p_v));
    }
}
