package wings.w2d;

import kha.Painter;
import kha.Image;

class Image2D extends Object2D {

	var image:Image;

	public function new(image:Image, x:Float = 0, y:Float = 0) {
		super();

		this.x = x;
		this.y = y;
		w = image.width;
		h = image.height;
		this.image = image;
	}

	public override function render(painter:Painter) {
		painter.opacity = a;
		painter.drawImage(image, _x, _y);

		super.render(painter);
		// TODO: proper rendering order
	}
}
