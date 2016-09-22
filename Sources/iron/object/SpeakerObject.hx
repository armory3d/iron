package iron.object;

import iron.Scene;
import iron.data.SceneFormat;

class SpeakerObject extends Object {

	var data:TSpeakerData;
	var sound:kha.Sound;

	public function new(data:TSpeakerData) {
		super();

		this.data = data;

		Scene.active.speakers.push(this);

		iron.data.Data.getSound(data.sound, function(sound:kha.Sound) {
			this.sound = sound;
			Scene.active.notifyOnInit(init);
		});
	}

	function init() {
		iron.system.Audio.playSound(sound, data.loop);
	}

	public override function remove() {
		Scene.active.speakers.remove(this);
		super.remove();
	}
}
