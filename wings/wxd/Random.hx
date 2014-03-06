package wings.wxd;

/**
 * Adapted from Nicolas Cannasse code.
 *
 * @author Franco Ponticelli
 * @author Nicolas Cannasse
 */

class Random {
	
	public static var seed:Int;
	
	public function new(s:Int = 1) {
		seed = s;
	}
	
	public static inline function int(to:Int):Int {
//#if neko
//		return untyped (__dollar__int( seed = (seed * 16807.0) % 2147483647.0 ) & 0x3FFFFFFF) % to;
//#elseif flash9
		return ((seed = Std.int((seed * 16807.0) % 2147483647.0)) & 0x3FFFFFFF) % to;
//#else
		//return (((seed = (seed * 16807) % 0x7FFFFFFF) & 0x3FFFFFFF) % to);
//#end
	}

	public static inline function float(to:Int):Float {
		return int(to) / 1073741823.0; // divided by 2^30-1
	}
}
