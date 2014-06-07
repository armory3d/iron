package wings;

import kha.Painter;
import composure.core.ComposeRoot;
import composure.core.ComposeItem;

import wings.sys.Input;
import wings.sys.Time;
import wings.sys.Storage;
import wings.core.FrameUpdater;
import wings.core.FrameRenderer;

class Root {

	static var root:ComposeRoot;

	static var frameUpdater:FrameUpdater;
	static var frameRenderer:FrameRenderer;

	public static var w(default, null):Int;
	public static var h(default, null):Int;

	public function new(width:Int, height:Int) {

		w = width;
		h = height;

		// Init systems
		new Input();
		new Time();
		//new Storage();

		// Root item
		root = new ComposeRoot();

		frameUpdater = new FrameUpdater();
		root.addTrait(frameUpdater);

		frameRenderer = new FrameRenderer();
		root.addTrait(frameRenderer);
	}

	public static inline function addChild(item:ComposeItem) {
		root.addChild(item);
	}

	public static inline function update() {
		Time.update();
		Input.update();

		frameUpdater.update();
	}

	public static inline function render(painter:Painter) {
		kha.Sys.graphics.clear(null, 1, null);

		// Render 3D objects

		// Render 2D objects
		painter.begin();
		frameRenderer.render(painter);
		painter.end();
	}

	public static inline function reset() {
		root.removeAllItem();
	}

	public static inline function mouseDown(x:Int, y:Int) { Input.onTouchBegin(x, y); }

    public static inline function mouseUp(x:Int, y:Int) { Input.onTouchEnd(x, y); }

    public static inline function rightMouseDown(x:Int, y:Int) { Input.onTouchAltBegin(x, y); }

    public static inline function rightMouseUp(x:Int, y:Int) { Input.onTouchAltEnd(x, y); }

    public static inline function mouseMove(x:Int, y:Int) { Input.onMove(x, y); }

    public static inline function buttonDown(button:kha.Button) { Input.onButtonDown(button); }

	public static inline function buttonUp(button:kha.Button) { Input.onButtonUp(button); }

	public static inline function mouseWheel(delta:Int) { Input.onWheel(delta); }
}
