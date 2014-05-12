package wings;

import kha.Painter;
import kha.Sys;
import wings.w2d.Object2D;
import wings.w3d.Object;
import wings.wxd.event.Event;
import wings.wxd.*;

class Root  {

	public static var root:Object;
	public static var root2D:Object2D;

	public function new() {
		root = new Object();
		root2D = new Object2D();

		// TODO: set root size

		new Assets();
		new Pos();
		new Time();
		new Input();
		new Storage();
		new Audio();
		new Net();
		new Log();
		new Random(Std.random(999999));
	}

	public static function update() {
		Time.update();
		root.update();
		root2D.update();
		Input.update();
	}

	public static function render(painter:Painter) {
		kha.Sys.graphics.clear(null, 1, null);

		root.render(painter);

		painter.begin();
		root2D.render(painter);
		Sys.mouse.render(painter);
		painter.end();
	}

	public static inline function mouseDown(x:Int, y:Int) { 
		Input.onTouchBegin(x, y);
	}

    public static inline function mouseUp(x:Int, y:Int) { 
    	Input.onTouchEnd(x, y);
    }

    public static inline function rightMouseDown(x:Int, y:Int) { 
		Input.onTouchAltBegin(x, y);
	}

    public static inline function rightMouseUp(x:Int, y:Int) { 
    	Input.onTouchAltEnd(x, y);
    }

    public static inline function mouseMove(x:Int, y:Int) { 
    	Input.onMove(x, y);
    }

    public static inline function buttonDown(button:kha.Button) {
    	Input.onButtonDown(button);
    }

	public static inline function buttonUp(button:kha.Button) {
		Input.onButtonUp(button);
	}

	public static inline function mouseWheel(delta:Int) {
		Input.onWheel(delta);
	}

	public static function addChild(child:Object) {
		root.addChild(child);
	}

	public static function removeChild(child:Object) {
		root.removeChild(child);
	}

	public static function addChild2D(child2D:Object2D) {
		root2D.addChild(child2D);
	}

	public static function removeChild2D(child2D:Object2D) {
		root2D.removeChild(child2D);
	}

	public static function addEvent(event:Event, permanent:Bool = false) {
		root.addEvent(event, permanent);
	}

	public static function removeEvent(event:Event, permanent:Bool = false) {
		root.removeEvent(event, permanent);
	}

	public static function addEvent2D(event:Event) {
		root2D.addEvent(event);
	}

	public static function removeEvent2D(event:Event) {
		root2D.removeEvent(event);
	}

	public static function reset() {
		root.reset();
		root2D.reset();
		Input.reset();
	}
}
