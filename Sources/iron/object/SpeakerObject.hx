package iron.object;

import kha.audio1.AudioChannel;
import iron.math.Vec4;
import iron.data.Data;
import iron.data.SceneFormat;
import iron.system.Audio;

class SpeakerObject extends Object {

#if arm_audio

	public var data:TSpeakerData;
	var sound:kha.Sound = null;
	var channels:Array<AudioChannel> = [];
	var paused = false;

	public function new(data:TSpeakerData) {
		super();

		this.data = data;

		Scene.active.speakers.push(this);

		if (data.sound == "") return;
		
		Data.getSound(data.sound, function(sound:kha.Sound) {
			this.sound = sound;
			App.notifyOnInit(init);
		});
	}

	function init() {
		if (visible && data.play_on_start) play();
	}

	public function play() {
		if (sound == null || data.muted) return;
		if (paused) {
			for (c in channels) c.play();
			paused = false;
			return;
		}
		var channel = Audio.play(sound, data.loop, data.stream);
		channels.push(channel);
		if (data.attenuation > 0 && channels.length == 1) App.notifyOnUpdate(update);
	}

	public function pause() {
		for (c in channels) c.pause();
		paused = true;
	}

	public function stop() {
		for (c in channels) c.stop();
		channels.splice(0, channels.length);
	}

	function update() {
		if (paused) return;
		for (c in channels) if (c.finished) channels.remove(c);
		if (channels.length == 0) {
			App.removeUpdate(update);
			return;
		}
		
		var cam = Scene.active.camera;
		var loc1 = cam.transform.world.getLoc();
		var loc2 = transform.world.getLoc();

		var d = Vec4.distance(loc1, loc2);
		d *= data.attenuation;
		var vol = 1.0 - Math.min(d / 100, 1);

		for (c in channels) c.volume = vol * data.volume;
	}

	public override function remove() {
		if (Scene.active != null) Scene.active.speakers.remove(this);
		super.remove();
	}

#end

}
