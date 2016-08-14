package iron.node;

import iron.Root;
import iron.resource.SceneFormat;

class SpeakerNode extends Node {

	var resource:TSpeakerResource;

	public function new(resource:TSpeakerResource) {
		super();

		this.resource = resource;

		Root.speakers.push(this);

		iron.sys.Audio.playSound(Reflect.field(kha.Assets.sounds, resource.sound));
	}

	public override function remove() {
		Root.speakers.remove(this);
		super.remove();
	}
}
