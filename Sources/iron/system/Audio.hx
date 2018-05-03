package iron.system;

import kha.Sound;

class Audio {

	public function new() {

	}

	public static function play(sound:Sound, loop = false, stream = false):kha.audio1.AudioChannel {
		#if arm_no_audio
		return null;
		#end
		if (stream && sound.compressedData != null) {
			return kha.audio1.Audio.stream(sound, loop); 
		}
		else if (sound.uncompressedData != null) {
			return kha.audio1.Audio.play(sound, loop);
		}
		else return null;
	}
}
