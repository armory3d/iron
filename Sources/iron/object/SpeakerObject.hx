package iron.object;

import iron.Root;
import iron.data.SceneFormat;

class SpeakerObject extends Object {

	var data:TSpeakerData;

	public function new(data:TSpeakerData) {
		super();

		this.data = data;

		Root.speakers.push(this);

		iron.sys.Audio.playSound(Reflect.field(kha.Assets.sounds, data.sound));
	}

	public override function remove() {
		Root.speakers.remove(this);
		super.remove();
	}
}
