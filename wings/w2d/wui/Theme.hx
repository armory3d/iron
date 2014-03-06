package wings.w2d.ui;
import kha.Sound;

class Theme {
	public static var BG_COLOR:Array<Int> = [0xe5e5e5, 0x302c2f];

	public static var TITLE_COLOR:Array<Int> = [0xf5f5f4, 0x444444];
	public static var TITLE_LINE_COLOR:Array<Int> = [0xa0a0a0, 0x222222];
	public static var TITLE_ARROW_COLOR:Array<Int> = [0x7f7f7f, 0xdddddd];
	public static var TITLE_TEXT_COLOR:Array<Int> = [0x000000, 0xdfdfdf];

	// Blue title bar
	// public static var TITLE_COLOR:Array<Int> = [0x55acee, 0x444444];
	// public static var TITLE_LINE_COLOR:Array<Int> = [0xb2b2b2, 0x222222];
	// public static var TITLE_ARROW_COLOR:Array<Int> = [0xffffff, 0xdddddd];
	// public static var TITLE_TEXT_COLOR:Array<Int> = [0xffffff, 0xdfdfdf];

	public static var UI_BG_COLOR:Array<Int> = [0xffffff, 0x101010];
	public static var UI_LINE_COLOR:Array<Int> = [0xc8c8c8, 0x444444];
	public static var UI_TEXT_COLOR:Array<Int> = [0x000000, 0xd8d8d8];
	public static inline var UI_TEXT_SIZE:Float = 0.055;

	public static var THEME:Int = 0;


	public static var COLORS:Array<Int> = [0x48bbe1, 0x4ba4c4, 0xdbaa1f, 0xbadb1f, 0xcd0789,
										   0xc95972, 0x6b89b9, 0xec9073, 0x59c974];
	public static var currentColor:Int = 0;


	public static var SOUND_TAP:Sound = null;
	public static var SOUND_BACK:Sound = null;
	public static var SOUND_TOGGLE:Sound = null;

	public static var FONT:String = "Arial";
	public static var FONT_BOLD:String = "Arial";

	public function new() {
	}

	public static function getColor():Int {
		// Cycle colors
		if ((++currentColor) >= COLORS.length) currentColor = 0;

		return COLORS[currentColor - 1];
	}
}
