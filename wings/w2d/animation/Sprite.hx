package wings.w2d.animation;

import kha.Painter;
import wings.wxd.Time;
import wings.w2d.Object2D;

class Sprite extends Object2D {

	var tilesheet:Tilesheet;

	var animations:Array<Animation>;
	var currentAnimation:Int;
	var currentFrame:Int;
	var currentFrameTime:Int;

	var pause:Bool;
	var reversed:Bool;
	var flipped:Bool;
	public var repeat:Bool;

	public function new(tilesheet:Tilesheet, x:Float = 0, y:Float = 0) {
		super();

		animations = new Array();
		currentAnimation = 0;
		currentFrame = 0;
		currentFrameTime = 0;

		repeat = true;
		pause = false;

		this.tilesheet = tilesheet;
		this.x = x;
		this.y = y;
		w = tilesheet.tileW;
		h = tilesheet.tileH;
	}

	public function addAnimation(anim:Animation) {
		animations.push(anim);
	}

	public function setAnimation(name:String) {
		for (i in 0...animations.length) {
			if (animations[i].name == name) {
				currentAnimation = i;
				currentFrame = 0;
				currentFrameTime = 0;
			}
		}
	}

	public function getCurrentAnimationName():String {
		return animations[currentAnimation].name;
	}

	public override function update() {
		super.update();

		if (pause) return;

		// Add time
		currentFrameTime += Time.delta;

		// Frame passed
		if (currentFrameTime >= animations[currentAnimation].frameTime) {
			// Next frame
			currentFrame++;
			currentFrameTime = 0;

			// Animation passed
			if (currentFrame >= animations[currentAnimation].frames.length) {
				if (!repeat) {currentFrame--; pause = true;} // TODO: stops only at end, make possible to stop it at the start
				else currentFrame = 0;
			}
		}
	}

	public override function render(painter:Painter) {
		super.render(painter);

		// Actual frame on tileset
		var frame:Int = animations[currentAnimation].frames[currentFrame];
		
		// Pos on tileset
		var posX:Int = Std.int(frame % tilesheet.tilesW);
		var posY:Int = Std.int(frame / tilesheet.tilesW);

		var frameX:Int = posX * tilesheet.tileW;
		var frameY:Int = posY * tilesheet.tileH;

		painter.drawImage2(tilesheet.image, frameX, frameY, tilesheet.tileW, tilesheet.tileH,
						   _x, _y, tilesheet.tileW, tilesheet.tileH);
	}
}
