package wings.trait2d.animation;

import wings.sys.Time;
import wings.core.Trait;
import wings.core.IRenderable2D;
import wings.core.IUpdateable;
import wings.trait2d.tiles.TileSheet;
import wings.trait.Transform;

class Sprite extends Trait implements IRenderable2D implements IUpdateable {

	public var transform:Transform;

	var tilesheet:TileSheet;

	var animations:Array<Animation>;
	var currentAnimation:Int;
	var currentFrame:Int;
	var currentFrameTime:Float;

	var paused:Bool;
	var reversed:Bool;
	var flipped:Bool;

	public var repeat:Bool;

	public function new(tilesheet:TileSheet) {
		super();

		animations = new Array();
		currentAnimation = 0;
		currentFrame = 0;
		currentFrameTime = 0;

		repeat = true;
		paused = false;

		this.tilesheet = tilesheet;
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;

        transform.w = tilesheet.tileW;
        transform.h = tilesheet.tileH;
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

	public function play() {
		paused = false;
	}

	public function pause() {
		paused = true;
	}

	public function stop() {
		paused = true;
		currentFrame = 0;
		currentFrameTime = 0;
	}

	public function update() {

		if (paused) return;

		// Add time
		currentFrameTime += Time.delta;

		// Frame passed
		if (currentFrameTime >= animations[currentAnimation].frameTime) {
			// Next frame
			currentFrame++;
			currentFrameTime = 0;

			// Animation passed
			if (currentFrame >= animations[currentAnimation].frames.length) {
				if (!repeat) { currentFrame--; paused = true; } // TODO: stops only at end, make possible to stop it at the start
				else currentFrame = 0;
			}
		}
	}

	public function render(g:kha.graphics2.Graphics) {

		g.color = transform.color;
		g.opacity = transform.a;

		// Actual frame on tileset
		var frame:Int = animations[currentAnimation].frames[currentFrame];
		
		// Pos on tileset
		var posX:Int = Std.int(frame % tilesheet.tilesX);
		var posY:Int = Std.int(frame / tilesheet.tilesX);

		var frameX:Int = posX * tilesheet.tileW;
		var frameY:Int = posY * tilesheet.tileH;

		g.drawScaledSubImage(tilesheet.image, frameX, frameY, tilesheet.tileW, tilesheet.tileH,
						     transform.absx, transform.absy, transform.w, transform.h);
	}
}
