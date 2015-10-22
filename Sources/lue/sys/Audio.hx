package lue.sys;

import kha.Loader;
import kha.audio1.MusicChannel;

class Audio {

	static var currentMusic:MusicChannel = null;

	public static var musicOn:Bool = true;
	public static var soundOn:Bool = true;

	public static var musicPlaying = false;

	public function new() {

	}

	public static function playMusic(name:String) {
		if (currentMusic != null) {
			currentMusic.stop();
		}

		if (musicOn) {
			currentMusic = kha.audio1.Audio.playMusic(Loader.the.getMusic(name), true);
			musicPlaying = true;
			currentMusic.volume = 0;
			lue.sys.Tween.to(currentMusic, 1, {volume:1}, null, 0, lue.sys.Tween.LINEAR);
		}
	}

	public static function resumeMusic() {
		if (musicOn && currentMusic != null && !musicPlaying) {
			currentMusic.volume = 0;
			currentMusic.play();
			lue.sys.Tween.to(currentMusic, 1, {volume:1}, null, 0, lue.sys.Tween.LINEAR);
			musicPlaying = true;
		}
	}

	public static function stopMusic() {
		if (currentMusic != null) {
			lue.sys.Tween.to(currentMusic, 1, {volume:0}, function() {
				currentMusic.stop();
			}, 0, lue.sys.Tween.LINEAR);
			musicPlaying = false;
		}
	}

	public static function pauseMusic() {
		if (currentMusic != null) {
			lue.sys.Tween.to(currentMusic, 1, {volume:0}, function() {
				currentMusic.pause();
			}, 0, lue.sys.Tween.LINEAR);
			musicPlaying = false;
		}
	}

	public static function fadeOutMusic(time:Float) {
		if (currentMusic != null) {
			lue.sys.Tween.to(currentMusic, time, {volume:0}, null, 0, lue.sys.Tween.LINEAR);
		}
	}
	public static function fadeInMusic(time:Float) {
		if (currentMusic != null) {
			lue.sys.Tween.to(currentMusic, time, {volume:1}, null, 0, lue.sys.Tween.LINEAR);
		}
	}

	public static function playSound(name:String) {
		if (soundOn) {
			kha.audio1.Audio.playSound(Loader.the.getSound(name));
		}
	}
}
