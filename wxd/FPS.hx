package wings.wxd;

class FPS {
	static var time:Int = 0;
	static var frames:Int = 0;
	public static var fps:Int = 0;
	public static var ms:Float = 0;

	public static inline function update(delta:Int) {
		frames++;

		if ((time += delta) >= 1000) {
			fps = frames;
			ms = 1000 / frames;
			time = 0;
			frames = 0;
		}
	}
}
