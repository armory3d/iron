package wings.w2d;

import kha.Painter;
import kha.Image;
import wings.math.Rect;

class Image2D extends Object2D {

	public var image(default, set):Image;
	public var source:Rect;

	public var customShader:Bool = false;

	public function new(image:Image, x:Float = 0, y:Float = 0) {
		super();

		rel.x = x;
		rel.y = y;
		
		this.image = image;

		source = new Rect(this, 0, 0, w, h);
	}

	public override function render(painter:Painter) {
		if (image == null || !visible) return;

		painter.setColor(abs.color);
		painter.opacity = abs.color.A;

		if (abs.rotation.angle == 0 && source.w == 0 && scaleX == 1 && scaleY == 1) {
			if (!customShader) painter.drawImage(image, abs.x, abs.y);
			//else painter.drawCustom(image, abs.x, abs.y);
		}
		else {
			// TODO: calc center only when needed in updateTransform()
			abs.rotation.center = new kha.math.Vector2(abs.w / 2, abs.h / 2);

			// TODO: auto-set source size
			if (source.w == 0) source.w = image.width;
			if (source.h == 0) source.h = image.height;

			// TODO: shader support in painter
			// TODO: abs.x * parent.scaleX
			if (!customShader) {
				painter.drawImage2(image, source.x, source.y, source.w * source.scaleX, source.h * source.scaleY,
							   abs.x, abs.y, abs.w * abs.scaleX, abs.h * abs.scaleY,
							   abs.rotation);
			}
			else {
				//painter.drawCustom2(image, source.x, source.y, source.w * source.scaleX, source.h * source.scaleY,
				//			   abs.x, abs.y, abs.w * abs.scaleX, abs.h * abs.scaleY,
				//			   abs.rotation);
			}
		}

		super.render(painter);
	}

	function set_image(img:Image):Image {
		// Update object size
		if (img != null) {
			w = img.width;
			h = img.height;
		}

		return image = img;
	}
}
