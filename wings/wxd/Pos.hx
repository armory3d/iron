package wings.wxd;

class Pos {

	public static var w(default, null):Int;
	public static var h(default, null):Int;

	public function new(width:Int = 1136, height:Int = 640) {
		w = width;	// TODO: Get resolution from kha
		h = height;
	}
	
	public static inline function x(f:Float):Float {
		return w * f;
	}
	
	public static inline function y(f:Float):Float {
		return h * f;
	}
	
	public static inline function cw(size:Float):Float {
		return (w / 2 - size / 2);
	}
	
	public static inline function ch(size:Float):Float {
		return (h / 2 - size / 2);
	}
}
