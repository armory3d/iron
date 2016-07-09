package iron.node;

import iron.resource.SceneFormat;

class SpeakerNode extends Node {

	var resource:TSpeakerResource;

	public function new(resource:TSpeakerResource) {
		super();

		this.resource = resource;

		RootNode.speakers.push(this);

		iron.sys.Audio.playSound(Reflect.field(kha.Assets.sounds, resource.sound));
	}
}
