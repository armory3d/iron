package wings.w2d.ui;

import kha.Image;
import wings.w2d.Image2D;

class ImageButton extends Tapable {

	public function new(image:Image, onTap:Void->Void, x:Float = 0, y:Float = 0) {

		super(onTap);

		this.x = x;
		this.y = y;

		// Image
		addChild(new Image2D(image));
	}
}
