package iron.object;

import iron.Scene;
import iron.data.Data;
import iron.data.SceneFormat;
import iron.object.tilesheet.TilesheetActionData;
import iron.object.tilesheet.TilesheetActionData.TilesheetAction;
import iron.object.tilesheet.TilesheetFrameData;
import iron.object.tilesheet.TilesheetFrameData.TilesheetFrame;
import iron.system.Time;

@:allow(iron.Scene)
class Tilesheet {

	/**
	 * Raw tilesheet data
	 */
	public var raw:TTilesheetData;

	/**
	 * Parsed frame data for this tilesheet
	 */
	public var frameData:TilesheetFrameData;

	/**
	 * Parsed action data for this tilesheet
	 */
	public var actionData:TilesheetActionData;

	/**
	 * Parsed action data for the current action
	 */
	public var currentAction:TilesheetAction;

	/**
	 * RAW data for the current action.
	 */
	public var action(get, null):TTilesheetAction;

	function get_action():TTilesheetAction {
		return currentAction.raw;
	}

	public var textureWidth(get, null):Int;

	function get_textureWidth():Int {
		return frameData.textureWidth;
	}

	public var textureHeight(get, null):Int;

	function get_textureHeight():Int {
		return frameData.textureHeight;
	}

	public var framerate(get, null):Float;

	function get_framerate():Float {
		return raw.framerate;
	}

	public var frameTime(get, null):Float;

	function get_frameTime():Float {
		return 1 / this.framerate;
	}

	public var tileUVX(get, null):Float;

	function get_tileUVX():Float {
		if (currentFrame == null) return 0.0;
		return currentFrame.x / textureWidth;
	}

	public var tileUVY(get, null):Float;

	function get_tileUVY():Float {
		if (currentFrame == null) return 0.0;
		return currentFrame.y / textureHeight;
	}

	public var tileUVFrameX(get, null):Float;

	function get_tileUVFrameX():Float {
		if (currentFrame == null) return 0.0;
		return (currentFrame.x + currentFrame.frameX) / textureWidth;
	}

	public var tileUVFrameY(get, null):Float;

	function get_tileUVFrameY():Float {
		if (currentFrame == null) return 0.0;
		return (currentFrame.y + currentFrame.frameY) / textureHeight;
	}

	public var tileUVFrameWidth(get, null):Float;

	function get_tileUVFrameWidth():Float {
		if (currentFrame == null) return 0.0;
		return (currentFrame.x + currentFrame.frameX + currentFrame.frameWidth) / textureWidth;
	}

	public var tileUVFrameHeight(get, null):Float;

	function get_tileUVFrameHeight():Float {
		if (currentFrame == null) return 0.0;
		return (currentFrame.y + currentFrame.frameY + currentFrame.frameHeight) / textureHeight;
	}

	public var tileUVWidth(get, null):Float;

	function get_tileUVWidth():Float {
		if (currentFrame == null) return 0;
		return (currentFrame.x + currentFrame.frameWidth) / textureWidth;
	}

	public var tileUVHeight(get, null):Float;

	function get_tileUVHeight():Float {
		if (currentFrame == null) return 0;
		return (currentFrame.y + currentFrame.frameHeight) / textureHeight;
	}

	public var currentFrame(get, null):TilesheetFrame;
	
	function get_currentFrame():TilesheetFrame {
		if (currentAction == null) return null;
		return currentAction.frames[actionFrameIndex];
	}

	/**
	 * Whether tilesheet action playback is paused.
	 */
	public var paused = false;

	/**
	 * A callback that is called when the current action completes.
	 */
	var onActionComplete: Void->Void = null;

	var ready:Bool;
	
	/**
	 * A counter to track real time since the last animation frame.
	 */
	var time = 0.0;

	/**
	 * Current frame index in the current action.
	 */
	var actionFrameIndex = 0;

	public function new(sceneName: String, tilesheet_ref: String, tilesheet_action_ref: String) {
		ready = false;
		Data.getSceneRaw(sceneName, function(format: TSceneFormat) {
			for (ts in format.tilesheet_datas) {
				if (ts.name == tilesheet_ref) {
					raw = ts;
					frameData = buildFrameData();
					actionData = buildActionData();

					Scene.active.tilesheets.push(this);

					// Play the starting action.
					play(tilesheet_action_ref);

					ready = true;
					break;
				}
			}
		});
	}

	function buildFrameData():TilesheetFrameData {
		switch(raw.format) {
			case "GRID":
				return TilesheetFrameData.fromGrid(raw.tilesx, raw.tilesy);
			case "SPARROW":
				return TilesheetFrameData.fromSparrow(raw.atlas_data);
			default:
				return null;
		}
	}

	function buildActionData():TilesheetActionData {
		switch(raw.format) {
			case "GRID":
				return TilesheetActionData.fromGrid(frameData, raw.actions);
			case "SPARROW":
				return TilesheetActionData.fromSparrow(frameData, raw.actions);
			default:
				return null;
		}
	}

	public function play(action_ref: String, onActionComplete: Void->Void = null) {
		this.onActionComplete = onActionComplete;

		this.currentAction = actionData.getAction(action_ref);

		actionFrameIndex = 0;

		paused = false;
	}

	public function pause() {
		paused = true;
	}

	public function resume() {
		paused = false;
	}

	public function restart() {
		actionFrameIndex = 0;
		paused = false;
	}

	public function stop() {
		actionFrameIndex = 0;
		paused = true;
	}

	public function remove() {
		Scene.active.tilesheets.remove(this);
	}

	function update() {
		if (!ready || paused) return;
		if (currentAction == null) return;
		if (currentAction.frames.length == 0) return;

		time += Time.realDelta;

		var framesToAdvance = 0;

		// Check how many animation frames passed during the last render frame
		// and catch up if required. The remaining `time` that couldn't fit in
		// another animation frame will be used in the next `update()`.
		while (time >= frameTime) {
			time -= frameTime;
			framesToAdvance++;
		}

		if (framesToAdvance != 0) {
			setFrame(actionFrameIndex + framesToAdvance);
		}
	}

	function setFrame(f: Int) {
		actionFrameIndex = f;

		// Action end
		if (currentAction.frames.length > 0 && actionFrameIndex >= currentAction.frames.length) {
			if (onActionComplete != null) onActionComplete();
			if (action.loop) actionFrameIndex = 0;
			else paused = true;
		}
	}
}
