package wings;

import kha.Painter;
import kha.LoadingScreen;
import kha.Configuration;
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
	}

	public static inline function addChild(item:Object) {
		root.addChild(item);
	}

	public static inline function getChild(name:String):Object {
		return root.getChild(name);
	}

	public static inline function reset() {
		root.removeAllItem();
		Input.reset();
		motion.Actuate.reset();
	}

	public static inline function setScene(scene:Class<Dynamic>, args:Array<Dynamic> = null) {
		reset();

		if (args == null) args = [];
		Type.createInstance(scene, args);
	}

	override public function init() {
        Configuration.setScreen(new LoadingScreen());

        Loader.the.loadRoom(room, loadingFinished);
    }

    function loadingFinished() {
        w = width;
        h = height;

        new Time();
		//new Storage();

		root = new Object();

		frameUpdater = new FrameUpdater();
		root.addTrait(frameUpdater);

		frameRenderer = new FrameRenderer();
		root.addTrait(frameRenderer);

		frameRenderer2D = new FrameRenderer2D();
		root.addTrait(frameRenderer2D);

        Configuration.setScreen(this);

        Type.createInstance(game, []);

        if (kha.Sys.screenRotation == kha.ScreenRotation.RotationNone) {
        	kha.input.Mouse.get().notify(downListener, upListener, moveListener, null);
        }
        else {
        	kha.input.Surface.get().notify(touchStartListener, touchEndListener, touchMoveListener);
        }
    }

	override public inline function update() {
		frameUpdater.update();

		Time.update();
		Input.update();
	}

	override public inline function render(painter:Painter) {

		// Render 3D objects
		frameRenderer.begin();
		frameRenderer.render();
		frameRenderer.end();

		// Render 2D objects
		painter.begin();
		frameRenderer2D.render(painter);
		painter.end();
	}


	function downListener(button:Int, x:Int, y:Int) {
		Input.onTouchBegin(x, y);
	}

    function upListener(button:Int, x:Int, y:Int) {
		Input.onTouchEnd(x, y);
    }

    function moveListener(x:Int, y:Int) {
		Input.onMove(x, y);
    }


    function touchStartListener(index:Int, x:Int, y:Int) {
		Input.onTouchBegin(1136 - y, x);
    }

    function touchEndListener(index:Int, x:Int, y:Int) {
		Input.onTouchEnd(1136 - y, x);
    }

    function touchMoveListener(index:Int, x:Int, y:Int) {
		Input.onMove(1136 - y, x);
    }
}
