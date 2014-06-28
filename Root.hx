package wings;

import kha.Painter;
import kha.LoadingScreen;
import kha.Configuration;
import kha.graphics.CompareMode;
import kha.Painter;
import kha.Loader;

import wings.sys.Time;
import wings.sys.Storage;
import wings.sys.Assets;
import wings.core.Object;
import wings.core.FrameUpdater;
import wings.core.FrameRenderer;
import wings.core.FrameRenderer2D;
import wings.trait.Input;

// Scaling and nested size calc - remove abs
// Code doc

class Root extends kha.Game {

	public static var root:Object;

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

		new Time();
		//new Storage();

		root = new Object();

		frameUpdater = new FrameUpdater();
		root.addTrait(frameUpdater);

		frameRenderer = new FrameRenderer();
		root.addTrait(frameRenderer);

		frameRenderer2D = new FrameRenderer2D();
		root.addTrait(frameRenderer2D);
	}

	public static inline function addChild(item:Object) {
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

    override public inline function mouseMove(x:Int, y:Int) { 
    	Input.onMove(x, y);
    }
}
