package iron.system;

import kha.Sound;

class Audio {

	public function new() {

	}

	public static function play(sound:Sound, loop = false) {
		#if arm_no_audio
		return;
		#end
		kha.audio1.Audio.play(sound, loop);
	}
}
