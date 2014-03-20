package wings.w2d;

import kha.Painter;
import kha.Image;

class Image2D extends Object2D {

	var image:Image;

	public var sourceX:Float = 0;
	public var sourceY:Float = 0;
	public var sourceW:Float = 0;
	public var sourceH:Float = 0;

	public function new(image:Image, x:Float = 0, y:Float = 0) {
		super();

		rel.x = x;
		rel.y = y;
		rel.w = image.width;
		rel.h = image.height;
		this.image = image;
		sourceW = w;
		sourceH = h;
	}

	public override function render(painter:Painter) {
		painter.opacity = abs.color.A;

		if (abs.rotation.angle == 0 && sourceW == 0) {
			painter.drawImage(image, abs.x, abs.y);
		}
		else {
			// TODO: calc center only when needed in updateTransform()
			abs.rotation.center = new kha.math.Vector2(abs.w / 2, abs.h / 2);
			painter.drawImage2(image, sourceX, sourceY, sourceW, sourceH,
									  abs.x, abs.y, abs.w, abs.h, abs.rotation);
		}

		super.render(painter);
		// TODO: proper rendering order
	}
}
