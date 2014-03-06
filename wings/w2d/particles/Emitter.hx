package wings.w2d.particles;

// Unfinished

import kha.Color;
import kha.Painter;
import wings.wxd.Time;
import wings.w2d.Object2D;

class Emitter extends Object2D {

	var particles:Array<Particle>;

	var time:Int;

	public function new(x:Float, y:Float) {
		super();

		this.x = x;
		this.y = y;
		time = 0;

		particles = new Array();

		for (i in 0...10) {
			particles.push(new Particle());
		}
	}

	public override function update() {
		super.update();

		for (i in 0...particles.length) {
			particles[i].update();
		}

		// Auto-remove
		time += Time.delta;
		if (time >= 750) parent.removeChild(this);
	}

	public override function render(painter:Painter) {
		super.render(painter);

		painter.setColor(Color.fromValue(0xffff0066));

		for (i in 0...particles.length) {
			painter.fillRect(_x + particles[i].x, _y + particles[i].y, 1, 1);
		}
	}
}
