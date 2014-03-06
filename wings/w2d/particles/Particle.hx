package wings.w2d.particles;

import wings.wxd.Time;
import wings.wxd.Random;

class Particle {

	public var x:Float;
	public var y:Float;

	var gravityX:Float;
	var gravityY:Float;

	var velocityX:Float;
	var velocityY:Float;

	var speed:Float;
	var time:Int;

	public function new() {
		x = 0;
		y = 0;

		gravityX = ((Random.int(600) - 300) / 100);
		gravityY = ((Random.int(200) + 200) / 100);

		velocityX = 0;
		velocityY = -4;
	}

	public function update() {
		
		velocityX += gravityX / Time.delta;
		velocityY += gravityY / Time.delta;

		if (velocityX > 4) velocityX = 4;
		else if (velocityX < -4)velocityX = -4;
		if (velocityY > 7) velocityY = 7;

		x += velocityX / 10;
		y += velocityY / 10;
	}
}
