package wings.w2d;

import kha.Painter;
import kha.Image;

class Image2D extends Object2D {

	var image:Image;

	public function new(image:Image, x:Float = 0, y:Float = 0) {
		super();

		rel.x = x;
		rel.y = y;
		rel.w = image.width;
		rel.h = image.height;
		this.image = image;
	}

	public override function render(painter:Painter) {
		painter.opacity = abs.color.A;
		painter.drawImage(image, abs.x, abs.y);

		super.render(painter);
		// TODO: proper rendering order
	}
}
