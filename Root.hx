package wings;

import kha.Painter;
import kha.LoadingScreen;
import kha.Configuration;
import kha.graphics.CompareMode;
import kha.Painter;
import kha.Loader;
import composure.core.ComposeRoot;
import composure.core.ComposeItem;

import wings.sys.Input;
import wings.sys.Time;
import wings.sys.Storage;
import wings.sys.Factory;
import wings.core.FrameUpdater;
import wings.core.FrameRenderer;
import wings.core.FrameRenderer2D;

class Root extends kha.Game {

	static var root:ComposeRoot;

	static var frameUpdater:FrameUpdater;
	static var frameRenderer:FrameRenderer;
	static var frameRenderer2D:FrameRenderer2D;

	public static var w(default, null):Int;
	public static var h(default, null):Int;

	var game:Class<Dynamic>;
	var room:String;

	public function new(name:String, room:String, game:Class<Dynamic>) {
		super(name);

		this.game = game;
		this.room = room;

		// Init systems
		new Input();
		new Time();
		//new Storage();
		new Factory();

		// Root item
		root = new ComposeRoot();

		frameUpdater = new FrameUpdater();
		root.addTrait(frameUpdater);

		frameRenderer = new FrameRenderer();
		root.addTrait(frameRenderer);

		frameRenderer2D = new FrameRenderer2D();
		root.addTrait(frameRenderer2D);
	}

	public static inline function addChild(item:ComposeItem) {
		root.addChild(item);
	}

	public static inline function reset() {
		root.removeAllItem();
	}

	override public function init() {
        Configuration.setScreen(new LoadingScreen());

        Loader.the.loadRoom(room, loadingFinished);
    }

    function loadingFinished() {
        w = width;
        h = height;

        Configuration.setScreen(this);

        Type.createInstance(game, []);
    }

	override public inline function update() {
		frameUpdater.update();

		Time.update();
		Input.update();
	}

	override public inline function render(painter:Painter) {
		kha.Sys.graphics.setDepthMode(true, CompareMode.Less);
		kha.Sys.graphics.clear(null, 1, null);

		// Render 3D objects
		frameRenderer.render();

		// Render 2D objects
		painter.begin();
		frameRenderer2D.render(painter);
		painter.end();
	}

	override public inline function mouseDown(x:Int, y:Int) { 
		Input.onTouchBegin(x, y);
	}

    override public inline function mouseUp(x:Int, y:Int) { 
    	Input.onTouchEnd(x, y);
    }

    override public inline function rightMouseDown(x:Int, y:Int) { 
        Input.onTouchAltBegin(x, y);
    }

    override public inline function rightMouseUp(x:Int, y:Int) { 
        Input.onTouchAltEnd(x, y);
    }

    override public inline function mouseMove(x:Int, y:Int) { 
    	Input.onMove(x, y);
    }

    override public inline function buttonDown(button:kha.Button) { 
    	Input.onButtonDown(button);
    }

    override public inline function buttonUp(button:kha.Button) { 
    	Input.onButtonUp(button);
    }

    override public inline function mouseWheel(delta:Int) {
        Input.onWheel(delta);
    }
}
