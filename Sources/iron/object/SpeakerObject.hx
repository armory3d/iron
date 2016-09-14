package iron.object;

import iron.Scene;
import iron.data.SceneFormat;

class SpeakerObject extends Object {

	var data:TSpeakerData;

	public function new(data:TSpeakerData) {
		super();

		this.data = data;

		Scene.active.speakers.push(this);

		iron.data.Data.getSound(data.sound, function(sound:kha.Sound) {
			iron.sys.Audio.playSound(sound);
		});
	}

	public override function remove() {
		Scene.active.speakers.remove(this);
		super.remove();
	}
}
