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

	public override function removeChild(o:Node) {
		RootNode.speakers.remove(cast o);
		super.removeChild(o);
	}
}
