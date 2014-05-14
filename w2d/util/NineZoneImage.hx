package wings.w2d.util;

import kha.Painter;
import kha.Image;
import wings.math.Rect;

class NineZoneImage extends Object2D {

	public static inline var CornerSize:Int = 9;

	public var image:Image;

	public function new(image:Image, x:Float = 0, y:Float = 0, w:Float = 100, h:Float = 50) {
		super();

		rel.x = x;
		rel.y = y;
		abs.w = w;
		abs.h = h;
		
		this.image = image;
	}

	public override function render(painter:Painter) {
		if (image == null || !visible) return;

		painter.setColor(abs.color);
		painter.opacity = abs.a;

		// Draw top left section
		painter.drawImage2(image, 0, 0, CornerSize, CornerSize,
						   abs.x, abs.y, CornerSize, CornerSize, abs.rotation);

		// Draw left section
		painter.drawImage2(image, 0, CornerSize, CornerSize, 1,
						   abs.x, abs.y + CornerSize, CornerSize, abs.h, abs.rotation);

		// Draw bottom left section
		painter.drawImage2(image, 0, CornerSize + 1, CornerSize, CornerSize,
						   abs.x, abs.y + CornerSize + abs.h, CornerSize, CornerSize, abs.rotation);



		// Draw center
		painter.drawImage2(image, CornerSize, CornerSize, 1, 1,
						   abs.x + CornerSize, abs.y, abs.w * abs.scaleX, abs.h * abs.scaleY + CornerSize * 2,
						   abs.rotation);



		// Draw top right section
		painter.drawImage2(image, image.width - CornerSize, 0, CornerSize, CornerSize,
						   abs.x + CornerSize + abs.w * scaleX, abs.y, CornerSize, CornerSize, abs.rotation);

		// Draw right section
		painter.drawImage2(image, image.width - CornerSize, CornerSize, CornerSize, 1,
						   abs.x + CornerSize + abs.w * scaleX, abs.y + CornerSize, CornerSize, abs.h, abs.rotation);

		// Draw bottom right section
		painter.drawImage2(image, image.width - CornerSize, CornerSize + 1, CornerSize, CornerSize,
						   abs.x + CornerSize + abs.w * scaleX, abs.y + CornerSize + abs.h, CornerSize, CornerSize, abs.rotation);

		super.render(painter);
	}
}
