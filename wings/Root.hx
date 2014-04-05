package wings;

import kha.Painter;
import kha.Sys;
import wings.w2d.Object2D;
import wings.w3d.Object;
import wings.wxd.events.Event;
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
		new Random(Std.random(999999));
	}

	public static function update() {
		Time.update();
		root.update();
		root2D.update();

		Input.released = false;
		Input.started = false;
		Input.releasedAlt = false;
		Input.startedAlt = false;
		Input.moved = false;
		Input.deltaX = 0;
		Input.deltaY = 0;
		Input.wheel = 0;
	}

	public static function render(painter:Painter) {
		kha.Sys.graphics.clear(null, 1, null);

		root.render(painter);

		painter.begin();
		root2D.render(painter);
		painter.end();
	}

	public static inline function mouseDown(x:Int, y:Int) { 
		Input.onTouchBegin();
	}

    public static inline function mouseUp(x:Int, y:Int) { 
    	Input.onTouchEnd();
    }

    public static inline function rightMouseDown(x:Int, y:Int) { 
		Input.onTouchAltBegin();
	}

    public static inline function rightMouseUp(x:Int, y:Int) { 
    	Input.onTouchAltEnd();
    }

    public static inline function mouseMove(x:Int, y:Int) { 
    	Input.update(x, y);
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

	public static function addEvent(event:Event) {
		root.addEvent(event);
	}

	public static function removeEvent(event:Event) {
		root.removeEvent(event);
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

	/*public static function draw(image:Image, x:Float, y:Float, a:Float = 1,
								sx:Float = -1, sy:Float = 0, sw:Float = 0, sh:Float = 0) {
		painter.opacity = a;

		if (sx == -1) painter.drawImage(image, x, y);
		else painter.drawImage2(image, sx, sy, sw, sh, x, y, sw, sh);
	}

	public static function drawS(s:String, x:Int, y:Int, font:Image, charWidths:Array<Int>, lineSpacing:Int = 17, a:Float = 1) {
		var code:Int;
		var cellW:Int = Std.int(font.width / 16);
		var sourceX:Float = 0;
		var sourceY:Float = 0;
		var sourceW:Float = cellW;
		var sourceH:Float = cellW;
		var posX:Int = x, posY:Int = y;
		
		for (i in 0...s.length) 
		{
			code = s.charCodeAt(i);
			
			// New line
			if (code == 10)
			{
				posX = x;
				posY += lineSpacing;
			}
			// Draw character
			else
			{
				sourceX = ((code % 16) * cellW) + (cellW / 2) - (charWidths[code * 2] / 2);
				sourceY = Std.int(code / 16) * cellW;
				sourceW = charWidths[code * 2] + widthOffset;
				
				draw(font, posX, posY, a, sourceX, sourceY, sourceW, sourceH);
				
				posX += charWidths[code * 2] + charOffset;
			}
		}
	}

	public static function measureW(s:String, charWidths:Array<Int>):Int {
		var code:Int;
		var w:Int = 0;
		var topW:Int = 0;
		
		for (i in 0...s.length) 
		{
			code = s.charCodeAt(i);
			
			if (code == 10)
			{
				if (w >= topW) topW = w;
				w = 0;
				
				continue;
			}
			
			w += charWidths[code * 2] + charOffset;
		}
		
		if (w >= topW) topW = w;
		
		return topW;
	}

	public static var charOffset:Int = -1;
	public static var widthOffset:Int = 0;*/
}
