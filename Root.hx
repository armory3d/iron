package fox;

import kha.Framebuffer;
import kha.LoadingScreen;
import kha.Configuration;
import kha.Loader;

import fox.sys.Time;
import fox.sys.Storage;
import fox.sys.Assets;
import fox.core.Object;
import fox.core.FrameUpdater;
import fox.core.FrameRenderer;
import fox.core.FrameRenderer2D;
import fox.trait.Input;
import fox.sys.material.VertexStructure;
import fox.sys.material.Shader;

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

        // Input
        if (kha.Sys.screenRotation == kha.ScreenRotation.RotationNone) {
        	kha.input.Mouse.get().notify(downListener, upListener, moveListener, null);
        }
        else {
        	kha.input.Surface.get().notify(touchStartListener, touchEndListener, touchMoveListener);
        }

        // Define shader structure
        /*var struct = new VertexStructure();
        struct.addFloat3("vertexPosition");
        struct.addFloat2("texturePosition");
        struct.addFloat3("normalPosition");
        struct.addFloat4("vertexColor");

        // Create default shader
        var shader = new Shader("mesh.frag", "mesh.vert", struct);
        shader.addConstantMat4("mvpMatrix");
        shader.addConstantBool("texturing");
        shader.addTexture("tex");
        Assets.addShader("shader", shader);
        

        var struct = new VertexStructure();
        struct.addFloat3("vertexPosition");
        struct.addFloat2("texturePosition");
        struct.addFloat3("normalPosition");
        struct.addFloat4("vertexColor");
        struct.addFloat4("bone");
        struct.addFloat4("weight");

        var skinnedshader = new Shader("skinnedmesh.frag", "skinnedmesh.vert", struct);
        skinnedshader.addConstantMat4("mvpMatrix");
        skinnedshader.addConstantMat4("viewMatrix");
        skinnedshader.addConstantMat4("projectionMatrix");
        skinnedshader.addConstantBool("texturing");
        skinnedshader.addTexture("tex");
        skinnedshader.addTexture("skinning");
        Assets.addShader("skinnedshader", skinnedshader);

        fox.sys.importer.Animation.init();*/

        Type.createInstance(game, []);
    }

	override public inline function update() {
		frameUpdater.update();

		//fox.sys.importer.Animation.update();
		Time.update();
		Input.update();
	}

	override public inline function render(frame:Framebuffer) {

		// Render 3D objects
		//frameRenderer.begin(frame.g4);
		//frameRenderer.render(frame.g4);
		//frameRenderer.end(frame.g4);

		// Render 2D objects
	    frameRenderer2D.begin(frame.g2);
	    frameRenderer2D.render(frame.g2);
	    frameRenderer2D.end(frame.g2);
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
		Input.onTouchBegin(Root.w - y, x);
    }

    function touchEndListener(index:Int, x:Int, y:Int) {
		Input.onTouchEnd(Root.w - y, x);
    }

    function touchMoveListener(index:Int, x:Int, y:Int) {
		Input.onMove(Root.w - y, x);
    }
}
