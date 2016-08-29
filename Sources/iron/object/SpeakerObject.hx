package iron.object;

import iron.Scene;
import iron.data.SceneFormat;

class SpeakerObject extends Object {

	var data:TSpeakerData;

	public function new(data:TSpeakerData) {
		super();

		this.data = data;

		Scene.active.speakers.push(this);

		iron.sys.Audio.playSound(Reflect.field(kha.Assets.sounds, data.sound));
	}

	public override function remove() {
		Scene.active.speakers.remove(this);
		super.remove();
	}
}
