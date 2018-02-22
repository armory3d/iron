package iron.system;

import kha.Sound;

class Audio {

	public function new() {

	}

	public static function play(sound:Sound, loop = false):kha.audio1.AudioChannel {
		#if arm_no_audio
		return null;
		#end
		return kha.audio1.Audio.play(sound, loop);
	}
}
