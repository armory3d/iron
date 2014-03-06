package wings.wxd;

import kha.Sound;
import kha.Music;

class Audio {

	public static var soundOn(default, set):Bool;
	public static var musicOn(default, set):Bool;

	static var currentMusic:Music;
	
	public function new() {	
		soundOn = true;
		musicOn = true;
		currentMusic = null;
	}
	
	public static function playSound(sound:Sound) {
		if (soundOn) {
			sound.play();
		}
	}
	
	public static function playMusic(music:Music) {
		if (currentMusic != null) currentMusic.stop();
		currentMusic = music;

		if (musicOn) {
			//music.setPosition(0);
			music.play();
		}
	}
	
	static function set_soundOn(b:Bool):Bool {	
		soundOn = b;
		
		return b;
	}
	
	static function set_musicOn(b:Bool):Bool {
		musicOn = b;
		
		if (b && currentMusic != null) {
			playMusic(currentMusic);
		}
		else if (!b && currentMusic != null) {
			currentMusic.stop();
		}
		
		return b;
	}
}
