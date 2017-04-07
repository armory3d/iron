package iron.object;

import iron.Scene;
import iron.data.SceneFormat;

class SpeakerObject extends Object {

	var data:TSpeakerData;
	var sound:kha.Sound = null;

	public function new(data:TSpeakerData) {
		super();

		this.data = data;

		Scene.active.speakers.push(this);

		if (data.sound == "") return;
		
		iron.data.Data.getSound(data.sound, function(sound:kha.Sound) {
			this.sound = sound;
			if (!data.muted) Scene.active.notifyOnInit(play);
		});
	}

	public function play() {
		if (sound == null) return;
		iron.system.Audio.playSound(sound, data.loop);
	}

	public override function remove() {
		Scene.active.speakers.remove(this);
		super.remove();
	}
}
