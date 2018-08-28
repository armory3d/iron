package iron.math;

class Math {
		
	/*
		e
	*/
	public static inline var E = 2.7182818284590452354;
	
	/*
		log 2(e)
	*/
	public static inline var LOG2E = 1.4426950408889634074;
	
	/*
		log 10(e)
	*/
	public static inline var LOG10E = 0.43429448190325182765;
	
	/*
		ln(2), natural logarithm of 2
	*/
	public static inline var LN2 = 0.69314718055994530942;
	
	/*
		ln(10)
	*/
	public static inline var LN10 = 2.30258509299404568402;
	
	/*
		pi
	*/
	public static inline var PI = 3.14159265358979323846;
	
	/*
		pi/2
	*/
	public static inline var PI_2 = 1.57079632679489661923;
	
	/*
		pi/4
	*/
	public static inline var PI_4 = 0.78539816339744830962;
	
	/*
		1/pi
	*/
	public static inline var ONE_PI = 0.31830988618379067154;
	
	/*
		2/pi
	*/
	public static inline var TWO_PI = 0.63661977236758134308;
	
	/*
		2/sqrt(pi)
	*/
	public static inline var TWO_SQRTPI = 1.12837916709551257390;
	
	/*
		sqrt(2)
	*/
	public static inline var SQRT2 = 1.41421356237309504880;
	
	/*
		1/sqrt(2)
	*/
	public static inline var SQRT1_2 = 0.70710678118654752440;
	
	/*
		Positive infinity
	*/
	public static var POSITIVE_INFINITY(get, never) : Float;

	static inline function get_POSITIVE_INFINITY() {
		return std.Math.POSITIVE_INFINITY;
	}

	/*
		Negative infinity
	*/
	public static var NEGATIVE_INFINITY(get, never) : Float;
	
	static inline function get_NEGATIVE_INFINITY() {
		return std.Math.NEGATIVE_INFINITY;
	}

	/*
		Not a number (NaN)
	*/
	public static var NaN(get, never) : Float;

	static inline function get_NaN() {
		return std.Math.NaN;
	}

	/*
		Absolute value (magnitude)
	*/
	public static inline function abs(v:Float):Float {
		return std.Math.abs(v);
	}
	
	/*
		Inverse cosine in radians
	*/	
	public static inline function acos(v:Float):Float {
		return std.Math.acos(v);
	}

	/*
		Inverse sine in radians
	*/	
	public static inline function asin(v:Float):Float {
		return std.Math.asin(v);
	}
	
	/*
		Inverse tangent in radians
	*/
	public static inline function atan(v:Float):Float {
		return std.Math.atan(v);
	}
	
	/*
		Four-quadrant inverse tangent
	*/
	public static inline function atan2(y:Float, x:Float):Float {
		return std.Math.atan2(y, x);
	}
	
	/*
		Round toward positive infinity
	*/
	public static inline function ceil(v:Float):Int {
		return std.Math.ceil(v);
	}
	
	/*
		Cosine of argument in radians
	*/
	public static inline function cos(v:Float):Float {
		return std.Math.cos(v);
	}
	
	/*
		Exponential
	*/
	public static inline function exp(v:Float):Float {
		return std.Math.exp(v);
	}
	
	/*
		Round toward negative infinity
	*/
	public static inline function floor(v:Float):Int {
		return std.Math.floor(v);
	}
	
	/*
		Natural logarithm
	*/
	public static inline function log(v:Float):Float {
		return std.Math.log(v);
	}
	
	/*
		Maximum value
	*/
	public static inline function max(a:Float, b:Float):Float {
		return std.Math.max(a, b);
	}
	
	/*
		Minimum value
	*/
	public static inline function min(a:Float, b:Float):Float {
		return std.Math.min(a, b);
	}

	/*
		Raise to power
	*/
	public static inline function pow(v:Float, exp:Float):Float {
		return std.Math.pow(v, exp);
	}
	
	/*
		Generate random number between 0 and 1
	*/
	public static inline function random(): Float {
		return std.Math.random();
	}
	
	/*
		Round float to closest integer
	*/
	public static inline function round(v:Float):Int {
		return std.Math.round(v);
	}
	
	/*
		Sine of argument in radians
	*/
	public static inline function sin(v:Float):Float {
		return std.Math.sin(v);
	}
	
	/*
		Square root
	*/
	public static inline function sqrt(v:Float):Float {
		return std.Math.sqrt(v);
	}
	
	/*
		Tangent of argument in radians
	*/
	public static inline function tan(v:Float):Float {
		return std.Math.tan(v);
	}

	/*
		Round toward negative infinity
	*/
	public static inline function ffloor(v:Float): Float {
		return std.Math.ffloor(v);
	}

	/*
		Round toward positive infinity
	*/
	public static inline function fceil(v:Float): Float {
		return std.Math.fceil(v);
	}

	/*
		Round float to closest integer
	*/
	public static inline function fround(v:Float): Float {
		#if js
		return untyped __js__("Math.fround")(v);
		#else
		return std.Math.fround(v);
		#end
	}

	/*
		Determine whether element is finite
	*/
	public static inline function isFinite(f:Float): Bool {
		return std.Math.isFinite(f);
	}

	/*
		Determine whether element is NaN
	*/
	public static inline function isNaN(f:Float) {
		return std.Math.isNaN(f);
	}

	/* Extended */

	/*
		Round float with precision (default two digits)
	*/
	public static function roundfp(f:Float, precision = 2):Float {
    	f *= std.Math.pow(10, precision);
    	return std.Math.round(f) / std.Math.pow(10, precision);
	}

	/*
		Clamp float to interval
	*/
	public static function clamp(f:Float, min:Float, max:Float):Float {
		return f < min ? min : f > max ? max : f;
	}

    /*
		Convert radians to degrees
	*/
	public static inline function toDegrees(radians:Float):Float {
		return radians * 57.29578;
	}

	/*
		Convert degrees to radians
	*/
	public static inline function toRadians(degrees:Float):Float {
		return degrees * 0.0174532924;
	}

	/*
		Convenience function to map a variable from one coordinate space
		to another. Equivalent to unlerp() followed by lerp().
	*/
	public static inline function map(value:Float, leftMin:Float, leftMax:Float, rightMin:Float, rightMax:Float):Float {
		return rightMin + (value - leftMin) / (leftMax - leftMin) * (rightMax- rightMin);
	}

	public static inline function mapInt(value:Int, leftMin:Int, leftMax:Int, rightMin:Int, rightMax:Int ):Int {
		var result =  Std.int(map(value, leftMin, leftMax, rightMin, rightMax));
		return result;
	}

	public static inline function mapClamped(value:Float, leftMin:Float, leftMax:Float, rightMin:Float, rightMax:Float):Float {
		if (value >= leftMax) return rightMax;
		if (value <= leftMin) return rightMin;
		return map(value, leftMin, leftMax, rightMin, rightMax);
	}

	/*
		mod returns the remaainder when dividing a/b
		remainder = numerator - denominator * quotient as int (to round towards 0)
	*/
	public static inline function mod(a:Float, b:Float):Float {
		return a - (b * Std.int(a / b));
	}

	public static inline function fract(v:Float):Float {
		return v - Std.int(v);
	}
}
