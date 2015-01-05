package fox;

import kha.Framebuffer;
import kha.LoadingScreen;
import kha.Configuration;
import kha.Loader;
import fox.sys.Time;
import fox.sys.Storage;
import fox.sys.Assets;
import fox.sys.material.VertexStructure;
import fox.sys.material.Shader;
import fox.core.Object;
import fox.core.FrameUpdater;
import fox.core.FrameRenderer;
import fox.core.FrameRenderer2D;
import fox.trait.Input;
import fox.trait.GameScene;

class Root extends kha.Game {

	public static var root:Object;
    public static var gameScene:GameScene;
    public static var currentScene:Object;

	static var frameUpdater:FrameUpdater;
	static var frameRenderer:FrameRenderer;
	static var frameRenderer2D:FrameRenderer2D;

	public static var w(default, null):Int;
	public static var h(default, null):Int;

	var game:Class<Dynamic>;
    var room:String;
	var initCB:Void->Void;

	public function new(name:String, room:String, game:Class<Dynamic>, initCB:Void->Void = null) {
		super(name);

		this.game = game;
		this.room = room;
        this.initCB = initCB;
	}

    public static inline function registerInit(cb:Void->Void) {
        gameScene.registerInit(cb);
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

	public static inline function setScene(name:String) {
		reset();
		var scene = new Object();
        addChild(scene);
        gameScene = new GameScene(Assets.getString(name));
        scene.addTrait(gameScene);
        currentScene = scene;
	}

    public static inline function addScene(name:String):Object {
        return gameScene.addScene(Assets.getString(name));
    }

	override public function init() {
        Configuration.setScreen(new LoadingScreen());

        Loader.the.loadRoom(room, loadingFinished);
    }

    function loadingFinished() {
        w = width;
        h = height;

        if (initCB != null) initCB();

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
        // TODO: proper detection
        if (kha.Sys.screenRotation == kha.ScreenRotation.RotationNone) {
        	kha.input.Mouse.get().notify(downListener, upListener, moveListener, null);
        }
        else {
        	kha.input.Surface.get().notify(touchStartListener, touchEndListener, touchMoveListener);
        }

        initShaders();

        Type.createInstance(game, []);
    }

    function initShaders() {
        var struct = new VertexStructure();
        struct.addFloat3("vertexPosition");
        struct.addFloat2("texturePosition");
        struct.addFloat3("normalPosition");
        struct.addFloat4("vertexColor");

        // Shadow map
        var shadowShader = new Shader("shadowmap.frag", "shadowmap.vert", struct);
        shadowShader.addConstantMat4("mvpShadowMatrix");
        Assets.addShader("shadowmapshader", shadowShader);

        // Water
        /*
        var waterShader = new Shader("water.frag", "water.vert", struct);
        waterShader.addConstantMat4("mvpMatrix");
        waterShader.addConstantVec3("time");
        Assets.addShader("watershader", waterShader);*/

        // Billboard
        var billboardShader = new Shader("billboard.frag", "billboard.vert", struct);
        billboardShader.addConstantMat4("mvpMatrix");
        billboardShader.addConstantVec3("billboardCenterWorld");
        billboardShader.addConstantVec3("billboardSize");
        billboardShader.addConstantVec3("camRightWorld");
        billboardShader.addConstantVec3("camUpWorld");
        billboardShader.addConstantBool("texturing");
        billboardShader.addTexture("tex");
        Assets.addShader("billboardshader", billboardShader);

        // Particles
        var particlesShader = new Shader("particles.frag", "particles.vert", struct);
        particlesShader.addConstantMat4("mvpMatrix");
        particlesShader.addConstantVec3("billboardCenterWorld");
        particlesShader.addConstantVec3("billboardSize");
        particlesShader.addConstantVec3("camRightWorld");
        particlesShader.addConstantVec3("camUpWorld");
        particlesShader.addConstantBool("texturing");
        particlesShader.addTexture("tex");
        Assets.addShader("particlesshader", particlesShader);

        // Mesh
        var shader = new Shader("mesh.frag", "mesh.vert", struct);
        shader.addConstantMat4("mvpMatrix");
        shader.addConstantMat4("dbmvpMatrix");
        shader.addConstantMat4("viewMatrix");
        shader.addConstantBool("texturing");
        shader.addConstantBool("lighting");
        shader.addConstantBool("rim");
        shader.addConstantBool("castShadow");
        shader.addConstantBool("receiveShadow");
        shader.addTexture("tex");
        shader.addTexture("shadowMap");
        Assets.addShader("shader", shader);

        // Skinned mesh
        var struct = new VertexStructure();
        struct.addFloat3("vertexPosition");
        struct.addFloat2("texturePosition");
        struct.addFloat3("normalPosition");
        struct.addFloat4("vertexColor");
        struct.addFloat4("bone");
        struct.addFloat4("weight");

        var skinnedshader = new Shader("skinnedmesh.frag", "skinnedmesh.vert", struct);
        skinnedshader.addConstantMat4("mvpMatrix");
        skinnedshader.addConstantMat4("dbmvpMatrix");
        skinnedshader.addConstantMat4("viewMatrix");
        skinnedshader.addConstantMat4("projectionMatrix");
        skinnedshader.addConstantBool("texturing");
        skinnedshader.addConstantBool("lighting");
        skinnedshader.addConstantBool("rim");
        skinnedshader.addConstantBool("castShadow");
        skinnedshader.addConstantBool("receiveShadow");
        skinnedshader.addTexture("tex");
        skinnedshader.addTexture("shadowMap");
        skinnedshader.addTexture("skinning");
        Assets.addShader("skinnedshader", skinnedshader);
    }

	override public inline function update() {
		frameUpdater.update();

		Time.update();
		Input.update();
	}

	override public inline function render(frame:Framebuffer) {
		// Render 3D objects
		frameRenderer.begin(frame.g4);
		frameRenderer.render(frame.g4);
		frameRenderer.end(frame.g4);

		// Render 2D objects
	    frameRenderer2D.begin(frame.g2);
	    frameRenderer2D.render(frame.g2);
	    frameRenderer2D.end(frame.g2);
	}

    // Events
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
		Input.onTouchBegin(y, x);
    }

    function touchEndListener(index:Int, x:Int, y:Int) {
		Input.onTouchEnd(y, x);
    }

    function touchMoveListener(index:Int, x:Int, y:Int) {
		Input.onMove(y, x);
    }
}
