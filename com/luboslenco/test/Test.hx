package com.luboslenco.test;

import kha.LoadingScreen;
import kha.Configuration;
import kha.graphics.CompareMode;
import kha.Painter;
import kha.Loader;
import wings.Root;

class Test extends kha.Game {

	public function new() {
		super("Test", false);

		new Root();
	}

	override public function init() {
        Configuration.setScreen(new LoadingScreen());

        Loader.the.loadRoom("room1", loadingFinished);
    }

    function loadingFinished() {
        new R();
        new wings.wxd.Pos(width, height);
        Configuration.setScreen(this);

        new com.luboslenco.test.Game();
    }

	override public function update() {
		Root.update();
	}

	override public function render(painter:Painter) {
		kha.Sys.graphics.setDepthMode(true, CompareMode.Less);
		
		Root.render(painter);
	}

	override public function mouseDown(x:Int, y:Int) { 
		Root.mouseDown(x, y);
	}

    override public function mouseUp(x:Int, y:Int) { 
    	Root.mouseUp(x, y);
    }

    override public function rightMouseDown(x:Int, y:Int) { 
        Root.rightMouseDown(x, y);
    }

    override public function rightMouseUp(x:Int, y:Int) { 
        Root.rightMouseUp(x, y);
    }

    override public function mouseMove(x:Int, y:Int) { 
    	Root.mouseMove(x, y);
    }

    override public function buttonDown(button:kha.Button) { 
    	Root.buttonDown(button);
    }

    override public function buttonUp(button:kha.Button) { 
    	Root.buttonUp(button);
    }
}
