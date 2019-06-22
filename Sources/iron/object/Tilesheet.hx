package iron.object;

import iron.data.Data;
import iron.data.SceneFormat;
import iron.system.Time;

class Tilesheet {

	public var tileX = 0.0; // Tile offset on tilesheet texture 0-1
	public var tileY = 0.0;

	public var raw:TTilesheetData;
	var action:TTilesheetAction = null;
	var ready:Bool;

	var paused = false;
	var frame = 0;
	var time = 0.0;
	var onActionComplete:Void->Void = null;

	public function new(sceneName:String, tilesheet_ref:String, tilesheet_action_ref:String) {
		ready = false;
		Data.getSceneRaw(sceneName, function(format:TSceneFormat) {
			for (ts in format.tilesheet_datas) {
				if (ts.name == tilesheet_ref) {
					raw = ts;
					play(tilesheet_action_ref);
					ready = true;
					break;
				}
			}
		});
	}

	public function play(action_ref:String, onActionComplete:Void->Void = null) {
		this.onActionComplete = onActionComplete;
		for (a in raw.actions) if (a.name == action_ref) { action = a; break; }
		setFrame(action.start);
		paused = false;
	}

	public function pause() {
		paused = true;
	}

	public function resume() {
		paused = false;
	}

	public function remove() {}

	public function update() {
		if (!ready || paused || action.start >= action.end) return;

		time += Time.delta;

		// Next frame
		if (time >= 1 / raw.framerate) {
			setFrame(frame + 1);
		}
	}

	function setFrame(f:Int) {
		frame = f;
		time = 0;

		var tx = frame % raw.tilesx;
		var ty = Std.int(frame / raw.tilesx);
		tileX = tx * (1 / raw.tilesx);
		tileY = ty * (1 / raw.tilesy);

		// Action end
		if (frame >= action.end && action.start < action.end) {
			if (onActionComplete != null) onActionComplete();
			if (action.loop) setFrame(action.start);
			else paused = true;
		}
	}
}
