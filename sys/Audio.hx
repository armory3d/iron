package wings.sys;

import kha.Loader;
import kha.Music;

class Audio {

	static var currentMusic:Music = null;

	public static var musicOn:Bool = true;
	public static var soundOn:Bool = true;

	public function new() {

	}

	public static function playMusic(name:String) {

		if (currentMusic != null) currentMusic.stop();
		currentMusic = Loader.the.getMusic(name);

		if (musicOn) {
			currentMusic.play(true);
		}
	}

	public static function resumeMusic() {
		if (musicOn && currentMusic != null) {
			currentMusic.play(true);
		}
	}

	public static function stopMusic() {
		currentMusic.stop();
	}

	public static function playSound(name:String) {

		if (soundOn) {
			Loader.the.getSound(name).play();
		}
	}
}