package wings.w2d;

import kha.Painter;
import kha.Image;

class Image2D extends Object2D {

	public var image(default, set):Image;

	public var sourceX:Float = 0;
	public var sourceY:Float = 0;
	public var sourceW:Float = 0;
	public var sourceH:Float = 0;

	public function new(image:Image, x:Float = 0, y:Float = 0) {
		super();

		rel.x = x;
		rel.y = y;
		
		this.image = image;
		sourceW = w;
		sourceH = h;
	}

	public override function render(painter:Painter) {
		if (image == null) return;

		painter.opacity = abs.color.A;

		if (abs.rotation.angle == 0 && sourceW == 0 && scaleX == 1 && scaleY == 1) {
			painter.drawImage(image, abs.x, abs.y);
		}
		else {
			// TODO: calc center only when needed in updateTransform()
			abs.rotation.center = new kha.math.Vector2(abs.w / 2, abs.h / 2);

			// TODO: auto-set source size
			if (sourceW == 0) sourceW = image.width;
			if (sourceH == 0) sourceH = image.height;

			painter.drawImage2(image, sourceX, sourceY, sourceW, sourceH,
									  abs.x, abs.y, abs.w, abs.h, abs.rotation);
		}

		super.render(painter);
		// TODO: proper rendering order
	}

	function set_image(img:Image):Image {
		// Update object size
		if (img != null) {
			rel.w = img.width;
			rel.h = img.height;
		}

		return image = img;
	}
}
