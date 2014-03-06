package wings.w2d.ui;
import kha.Sound;
import wings.Events.TapEvent;
import wings.Events.UpdateEvent;
import wings.w2d.Item;
import wings.services.Audio;
import wings.services.Input;
import wings.services.Pos;

class Tapable extends Item {
	var onPress:Void->Void;
	var cancel:Bool;
	public var enabled(default, set):Bool;
	
	var tapped:Bool;
	var startPos:Float;
	public var yAxis:Bool;

	var tap:Sound;

	var defaultAlpha:Float;
	var tapAlpha:Float;

	public function new(onPress:Void->Void, defaultAlpha:Float = 1, tapAlpha:Float = 0.7) {
		super();
		
		this.onPress = onPress;
		this.defaultAlpha = defaultAlpha;
		this.tapAlpha = tapAlpha;
		alpha = defaultAlpha;
		cancel = false;
		enabled = true;
		tapped = false;
		yAxis = true;
		tap = Theme.SOUND_TAP;
		
		addEvent(new UpdateEvent(onFrame));
		addEvent(new TapEvent(onTapped, onTapDown, onTapUp));
	}
	
	function onFrame(item:Item) {
		// Cancel tap event if button is being slided
		if (Input.touch && !tapped) {
			tapped = true;
			if (yAxis) startPos = Input.y;
			else startPos = Input.x;
		}
		else if (!Input.touch) {
			tapped = false;
		}
		
		var currentPos:Float;
		if (yAxis) currentPos = Input.y;
		else currentPos = Input.x;

		if (Input.touch && Math.abs(currentPos - startPos) >= Pos.x(0.07) && !cancel) {
			cancel = true;
			onTapUp(item);
		}
		else if (!Input.touch) {
			cancel = false;
		}
	}
	
	function onTapped(item:Item) {
		if (!enabled) return;

		if (!cancel) {
			Audio.playSound(tap);
			if (onPress != null) onPress();
		}
		else {
			cancel = false;
		}
	}
	
	function onTapDown(item:Item) {
		if (!enabled) return;

		item.alpha = tapAlpha;
	}
	
	function onTapUp(item:Item) {
		if (!enabled) return;

		item.alpha = defaultAlpha;
	}

	function set_enabled(b:Bool):Bool {
		if (b) alpha = defaultAlpha;
		else alpha = tapAlpha;

		return enabled = b;
	}
}
