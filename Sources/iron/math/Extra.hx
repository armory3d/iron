package iron.math;

class Extra {
	/**
 	* Converts an angle in radians to degrees.
	* @return angle in degrees
	*/
  	inline public static function radToDeg(radians:Float):Float {
		return 180 / Math.PI * radians;
  	}
	/**
	* Converts an angle in degrees to radians.
	* @return angle in radians
	*/
  	inline public static function degToRad(degrees:Float):Float {
		return Math.PI / 180 * degrees;
  	}
	/**
	* rounds the precision of a float (default 2).
	* @return float with rounded precision
	*/
  	public static function roundfp(f:Float, precision = 2):Float {	
		f *= std.Math.pow(10, precision);	
		return std.Math.round(f) / std.Math.pow(10, precision);	
	}
	/**
	* clamps a float within some limits.
	* @return same float, min or max if exceeded limits.
	*/
  	public static function clamp(f:Float, min:Float, max:Float):Float {	
		return f < min ? min : f > max ? max : f;	
	}
        /*  
        * Convenience function to map a variable from one coordinate space	
        * to another. Equivalent to unlerp() followed by lerp().	
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
}
