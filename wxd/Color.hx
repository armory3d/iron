package wings.wxd;

class Color {

	public static function r(c:Int):Int {
		return c >> 16;
	}

	public static function g(c:Int):Int {
		return (c >> 8) & 0xFF;
	}

	public static function b(c:Int):Int {
		return c & 0x00FF;
	}
}
