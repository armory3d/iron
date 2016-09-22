package iron.system;

import kha.Sound;

class Audio {

	public function new() {

	}

	public static function playSound(sound:Sound, loop = false) {
		kha.audio1.Audio.play(sound, loop);
	}
}
