package iron.system;

import kha.input.KeyCode;

class Input {

	public static var occupied = false;
	static var mouse:Mouse = null;
	static var pen:Pen = null;
	static var keyboard:Keyboard = null;
	static var gamepads:Array<Gamepad> = [];
	static var sensor:Sensor = null;
	static var registered = false;
	public static var virtualButtons:Map<String, VirtualButton> = null; // Button name

	public static function reset() {
		occupied = false;
		if (mouse != null) mouse.reset();
		if (pen != null) pen.reset();
		if (keyboard != null) keyboard.reset();
		for (gamepad in gamepads) gamepad.reset();
	}

	public static function endFrame() {
		if (mouse != null) mouse.endFrame();
		if (pen != null) pen.endFrame();
		if (keyboard != null) keyboard.endFrame();
		for (gamepad in gamepads) gamepad.endFrame();

		if (virtualButtons != null) {
			for (vb in virtualButtons) vb.started = vb.released = false;
		}
	}

	public static function getMouse():Mouse {
		if (!registered) register();
		if (mouse == null) mouse = new Mouse();
		return mouse;
	}

	public static function getPen():Pen {
		if (!registered) register();
		if (pen == null) pen = new Pen();
		return pen;
	}

	public static function getSurface():Surface {
		if (!registered) register();
		// Map to mouse for now..
		return getMouse();
	}

	/**
	 * Get the Keyboard object. If it is not registered yet then register a new Keyboard.
	 */
	public static function getKeyboard():Keyboard {
		if (!registered) register();
		if (keyboard == null) keyboard = new Keyboard();
		return keyboard;
	}

	public static function getGamepad(i = 0):Gamepad {
		if (i >= 4) return null;
		if (!registered) register();
		while (gamepads.length <= i) gamepads.push(new Gamepad(gamepads.length));
		return gamepads[i].connected ? gamepads[i] : null;
	}

	public static function getSensor():Sensor {
		if (!registered) register();
		if (sensor == null) sensor = new Sensor();
		return sensor;
	}

	public static function getVirtualButton(virtual:String):VirtualButton {
		if (!registered) register();
		if (virtualButtons == null) return null;
		return virtualButtons.get(virtual);
	}

	static inline function register() {
		registered = true;
		App.notifyOnEndFrame(endFrame);
		App.notifyOnReset(reset);
	}
}

class VirtualButton {
	public var started = false;
	public var released = false;
	public var down = false;
	public function new() {}
}

class VirtualInput {
	var virtualButtons:Map<String, VirtualButton> = null; // Button id

	public function setVirtual(virtual:String, button:String) {
		if (Input.virtualButtons == null) Input.virtualButtons = new Map<String, VirtualButton>();
		
		var vb = Input.virtualButtons.get(virtual);
		if (vb == null) {
			vb = new VirtualButton();
			Input.virtualButtons.set(virtual, vb);
		}

		if (virtualButtons == null) virtualButtons = new Map<String, VirtualButton>();
		virtualButtons.set(button, vb);
	}

	function downVirtual(button:String) {
		if (virtualButtons != null) {
			var vb = virtualButtons.get(button);
			if (vb != null) { vb.down = true; vb.started = true; }
		}
	}

	function upVirtual(button:String) {
		if (virtualButtons != null) {
			var vb = virtualButtons.get(button);
			if (vb != null) { vb.down = false; vb.released = true; }
		}
	}
}

typedef Surface = Mouse;

class Mouse extends VirtualInput {

	static var buttons = ['left', 'right', 'middle'];
	var buttonsDown = [false, false, false];
	var buttonsStarted = [false, false, false];
	var buttonsReleased = [false, false, false];

	public var x(default, null) = 0.0;
	public var y(default, null) = 0.0;
	public var moved(default, null) = false;
	public var movementX(default, null) = 0.0;
	public var movementY(default, null) = 0.0;
	public var wheelDelta(default, null) = 0;
	public var locked(default, null) = false;
	public var hidden(default, null) = false;
	public var lastX = -1.0;
	public var lastY = -1.0;

	public function new() {
		kha.input.Mouse.get().notify(downListener, upListener, moveListener, wheelListener);
	}

	public function endFrame() {
		buttonsStarted[0] = buttonsStarted[1] = buttonsStarted[2] = false;
		buttonsReleased[0] = buttonsReleased[1] = buttonsReleased[2] = false;
		moved = false;
		movementX = 0;
		movementY = 0;
		wheelDelta = 0;
	}

	public function reset() {
		buttonsDown[0] = buttonsDown[1] = buttonsDown[2] = false;
		endFrame();
	}

	function buttonIndex(button:String) {
		return button == "left" ? 0 : (button == "right" ? 1 : 2);
	}

	public function down(button = "left"):Bool {
		return buttonsDown[buttonIndex(button)];
	}

	public function started(button = "left"):Bool {
		return buttonsStarted[buttonIndex(button)];
	}

	public function released(button = "left"):Bool {
		return buttonsReleased[buttonIndex(button)];
	}

	public function lock() {
		if (kha.input.Mouse.get().canLock()) {
			kha.input.Mouse.get().lock();
			locked = true;
			hidden = true;
		}
	}
	public function unlock() {
		if (kha.input.Mouse.get().canLock()) {
			kha.input.Mouse.get().unlock();
			locked = false;
			hidden = false;
		}
	}

	public function hide() {
		kha.input.Mouse.get().hideSystemCursor();
		hidden = true;
	}

	public function show() {
		kha.input.Mouse.get().showSystemCursor();
		hidden = false;
	}
	
	function downListener(index:Int, x:Int, y:Int) {
		buttonsDown[index] = true;
		buttonsStarted[index] = true;
		this.x = x - iron.App.x();
		this.y = y - iron.App.y();
		#if (kha_android || kha_ios || kha_webgl) // For movement delta using touch
		if (index == 0) { lastX = x; lastY = y; }
		#end

		downVirtual(buttons[index]);
	}
	
	function upListener(index:Int, x:Int, y:Int) {
		buttonsDown[index] = false;
		buttonsReleased[index] = true;
		this.x = x - iron.App.x();
		this.y = y - iron.App.y();

		upVirtual(buttons[index]);
	}
	
	function moveListener(x:Int, y:Int, movementX:Int, movementY:Int) {
		if (lastX == -1.0 && lastY == -1.0) { lastX = x; lastY = y; } // First frame init
		if (locked) {
			// Can be called multiple times per frame
			this.movementX += movementX;
			this.movementY += movementY;
		}
		else {
			this.movementX += x - lastX;
			this.movementY += y - lastY;
		}
		lastX = x;
		lastY = y;
		this.x = x - iron.App.x();
		this.y = y - iron.App.y();
		moved = true;
	}

	function wheelListener(delta:Int) {
		wheelDelta = delta;
	}
}

class Pen extends VirtualInput {

	static var buttons = ['tip'];
	var buttonsDown = [false];
	var buttonsStarted = [false];
	var buttonsReleased = [false];

	public var x(default, null) = 0.0;
	public var y(default, null) = 0.0;
	public var moved(default, null) = false;
	public var movementX(default, null) = 0.0;
	public var movementY(default, null) = 0.0;
	public var pressure(default, null) = 0.0;
	var lastX = -1.0;
	var lastY = -1.0;

	public function new() {
		kha.input.Pen.get().notify(downListener, upListener, moveListener);
	}

	public function endFrame() {
		buttonsStarted[0] = false;
		buttonsReleased[0] = false;
		moved = false;
		movementX = 0;
		movementY = 0;
	}

	public function reset() {
		buttonsDown[0] = false;
		endFrame();
	}

	function buttonIndex(button:String) {
		return 0;
	}

	public function down(button = "tip"):Bool {
		return buttonsDown[buttonIndex(button)];
	}

	public function started(button = "tip"):Bool {
		return buttonsStarted[buttonIndex(button)];
	}

	public function released(button = "tip"):Bool {
		return buttonsReleased[buttonIndex(button)];
	}
	
	function downListener(x:Float, y:Float, pressure:Float) {
		buttonsDown[0] = true;
		buttonsStarted[0] = true;
		this.x = x - iron.App.x();
		this.y = y - iron.App.y();
		this.pressure = pressure;
	}

	function upListener(x:Float, y:Float, pressure:Float) {
		buttonsDown[0] = false;
		buttonsReleased[0] = true;
		this.x = x - iron.App.x();
		this.y = y - iron.App.y();
		this.pressure = pressure;
	}
	
	function moveListener(x:Int, y:Int, pressure:Float) {
		if (lastX == -1.0 && lastY == -1.0) { lastX = x; lastY = y; } // First frame init
		this.movementX = x - lastX;
		this.movementY = y - lastY;
		lastX = x;
		lastY = y;
		this.x = x - iron.App.x();
		this.y = y - iron.App.y();
		moved = true;
		this.pressure = pressure;
	}
}

class Keyboard extends VirtualInput {

	static var keys = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'period', 'comma', 'space', 'backspace', 'tab', 'enter', 'shift', 'control', 'alt', 'escape', 'delete', 'back', 'up', 'right', 'left', 'down', 'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12'];
	var keysDown = new Map<String, Bool>();
	var keysStarted = new Map<String, Bool>();
	var keysReleased = new Map<String, Bool>();

	var keysFrame:Array<String> = [];

	public function new() {
		reset();
		kha.input.Keyboard.get().notify(downListener, upListener, pressListener);
	}

	public function endFrame() {
		if (keysFrame.length > 0) {
			for (s in keysFrame) {
				keysStarted.set(s, false);
				keysReleased.set(s, false);
			}
			keysFrame.splice(0, keysFrame.length);
		}
	}

	public function reset() {
		// Use Map for now..
		for (s in keys) {
			keysDown.set(s, false);
			keysStarted.set(s, false);
			keysReleased.set(s, false);
		}
		endFrame();
	}

	/**
	 * Check if a key is currently pressed.
	 *
	 * @param	key A String representing the physical keyboard key to check.
	 * @return	Bool. Returns true or false depending on the keyboard state.
	 */
	public function down(key:String):Bool {
		return keysDown.get(key);
	}

	/**
	 * Check if a key has started being pressed down. Will only be run once until the key is released and pressed again.
	 *
	 * @param	key A String representing the physical keyboard key to check.
	 * @return	Bool. Returns true or false depending on the keyboard state.
	 */
	public function started(key:String):Bool {
		return keysStarted.get(key);
	}

	/**
	 * Check if a key has been released from being pressed down. Will only be run once until the key is pressed again and release again.
	 *
	 * @param	key A String representing the physical keyboard key to check.
	 * @return	Bool. Returns true or false depending on the keyboard state.
	 */
	public function released(key:String):Bool {
		return keysReleased.get(key);
	}

	public static function keyCode(key: KeyCode):String {
		if (key == KeyCode.Space) return "space";
		else if (key == KeyCode.Backspace) return "backspace";
		else if (key == KeyCode.Tab) return "tab";
		else if (key == KeyCode.Return) return "enter";
		else if (key == KeyCode.Shift) return "shift";
		else if (key == KeyCode.Control) return "control";
		else if (key == KeyCode.Alt) return "alt";
		else if (key == KeyCode.Escape) return "escape";
		else if (key == KeyCode.Delete) return "delete";
		else if (key == KeyCode.Up) return "up";
		else if (key == KeyCode.Down) return "down";
		else if (key == KeyCode.Left) return "left";
		else if (key == KeyCode.Right) return "right";
		else if (key == KeyCode.Back) return "back";
		else if (key == KeyCode.Comma) return "comma";
		else if (key == KeyCode.Period) return "period";
		else if (key == KeyCode.Colon) return ":";
		else if (key == KeyCode.Semicolon) return ";";
		else if (key == KeyCode.LessThan) return "<";
		else if (key == KeyCode.Equals) return "=";
		else if (key == KeyCode.GreaterThan) return ">";
		else if (key == KeyCode.Add) return "+";
		else if (key == KeyCode.Plus) return "+";
		else if (key == KeyCode.Subtract) return "-";
		else if (key == KeyCode.HyphenMinus) return "-";
		else if (key == KeyCode.Zero) return "0";
		else if (key == KeyCode.Numpad0) return "0";
		else if (key == KeyCode.One) return "1";
		else if (key == KeyCode.Numpad1) return "1";
		else if (key == KeyCode.Two) return "2";
		else if (key == KeyCode.Numpad2) return "2";
		else if (key == KeyCode.Three) return "3";
		else if (key == KeyCode.Numpad3) return "3";
		else if (key == KeyCode.Four) return "4";
		else if (key == KeyCode.Numpad4) return "4";
		else if (key == KeyCode.Five) return "5";
		else if (key == KeyCode.Numpad5) return "5";
		else if (key == KeyCode.Six) return "6";
		else if (key == KeyCode.Numpad6) return "6";
		else if (key == KeyCode.Seven) return "7";
		else if (key == KeyCode.Numpad7) return "7";
		else if (key == KeyCode.Eight) return "8";
		else if (key == KeyCode.Numpad8) return "8";
		else if (key == KeyCode.Nine) return "9";
		else if (key == KeyCode.Numpad9) return "9";
		else if (key == KeyCode.F1) return "f1";
		else if (key == KeyCode.F2) return "f2";
		else if (key == KeyCode.F3) return "f3";
		else if (key == KeyCode.F4) return "f4";
		else if (key == KeyCode.F5) return "f5";
		else if (key == KeyCode.F6) return "f6";
		else if (key == KeyCode.F7) return "f7";
		else if (key == KeyCode.F8) return "f8";
		else if (key == KeyCode.F9) return "f9";
		else if (key == KeyCode.F10) return "f10";
		else if (key == KeyCode.F11) return "f11";
		else if (key == KeyCode.F12) return "f12";
		else return String.fromCharCode(cast key).toLowerCase();
	}

	function downListener(code: KeyCode) {
		var s = keyCode(code);
		keysFrame.push(s);
		keysStarted.set(s, true);
		keysDown.set(s, true);

		downVirtual(s);
	}

	function upListener(code: KeyCode) {
		var s = keyCode(code);
		keysFrame.push(s);
		keysReleased.set(s, true);
		keysDown.set(s, false);

		upVirtual(s);
	}

	function pressListener(char: String) {}
}

class GamepadStick {
	public var x = 0.0;
	public var y = 0.0;
	public var lastX = 0.0;
	public var lastY = 0.0;
	public var moved = false;
	public var movementX = 0.0;
	public var movementY = 0.0;
	public function new() {}
}

class Gamepad extends VirtualInput {

	public static var buttonsPS = ['cross', 'circle', 'square', 'triangle', 'l1', 'r1', 'l2', 'r2', 'share', 'options', 'l3', 'r3', 'up', 'down', 'left', 'right', 'home', 'touchpad'];
	public static var buttonsXBOX = ['a', 'b', 'x', 'y', 'l1', 'r1', 'l2', 'r2', 'share', 'options', 'l3', 'r3', 'up', 'down', 'left', 'right', 'home', 'touchpad'];
	public static var buttons = buttonsPS;

	var buttonsDown:Array<Float> = []; // Intensity 0 - 1
	var buttonsStarted:Array<Bool> = [];
	var buttonsReleased:Array<Bool> = [];

	var buttonsFrame:Array<Int> = [];

	public var leftStick = new GamepadStick();
	public var rightStick = new GamepadStick();

	public var connected = false;
	var num = 0;

	public function new(i:Int, virtual = false) {
		for (s in buttons) {
			buttonsDown.push(0.0);
			buttonsStarted.push(false);
			buttonsReleased.push(false);
		}
		num = i;
		reset();
		virtual ? connected = true : connect();
	}

	var connects = 0;
	function connect() {
		var gamepad = kha.input.Gamepad.get(num);
		if (gamepad == null) {
			// if (connects < 10) armory.system.Tween.timer(1, connect);
			// connects++;
			return;
		}
		connected = true;
		gamepad.notify(axisListener, buttonListener);
	}

	public function endFrame() {
		if (buttonsFrame.length > 0) {
			for (i in buttonsFrame) {
				buttonsStarted[i] = false;
				buttonsReleased[i] = false;
			}
			buttonsFrame.splice(0, buttonsFrame.length);
		}
		leftStick.moved = false;
		leftStick.movementX = 0;
		leftStick.movementY = 0;
		rightStick.moved = false;
		rightStick.movementX = 0;
		rightStick.movementY = 0;
	}

	public function reset() {
		for (i in 0...buttonsDown.length) {
			buttonsDown[i] = 0.0;
			buttonsStarted[i] = false;
			buttonsReleased[i] = false;
		}
		endFrame();
	}

	public static function keyCode(button:Int):String {
		return buttons[button];
	}

	function buttonIndex(button:String):Int {
		for (i in 0...buttons.length) if (buttons[i] == button) return i;
		return 0;
	}

	public function down(button:String):Float {
		return buttonsDown[buttonIndex(button)];
	}

	public function started(button:String):Bool {
		return buttonsStarted[buttonIndex(button)];
	}

	public function released(button:String):Bool {
		return buttonsReleased[buttonIndex(button)];
	}

	function axisListener(axis:Int, value:Float) {
		var stick = axis <= 1 ? leftStick : rightStick;

		if (axis == 0 || axis == 2) { // X
			stick.lastX = stick.x;
			stick.x = value;
			stick.movementX = stick.x - stick.lastX;
		}
		else if (axis == 1 || axis == 3) { // Y
			stick.lastY = stick.y;
			stick.y = value;
			stick.movementY = stick.y - stick.lastY;
		}
		stick.moved = true;
	}

	function buttonListener(button:Int, value:Float) {
		buttonsFrame.push(button);

		buttonsDown[button] = value;
		if (value > 0) buttonsStarted[button] = true; // Will trigger L2/R2 multiple times..
		else buttonsReleased[button] = true;

		if (value == 0.0) upVirtual(buttons[button]);
		else if (value == 1.0) downVirtual(buttons[button]);
	}
}

class Sensor {

	public var x = 0.0;
	public var y = 0.0;
	public var z = 0.0;

	public function new() {
		kha.input.Sensor.get(kha.input.SensorType.Accelerometer).notify(listener);
	}

	function listener(x:Float, y:Float, z:Float) {
		this.x = x;
		this.y = y;
		this.z = z;
	}
}
