package wings.w2d.ui.item;

import kha.Image;
import wings.w2d.Image2D;
import wings.wxd.event.UpdateEvent;
import wings.wxd.Time;

class LoadingItem extends Image2D {

	var finishImage:Image;
	var progress:Float = 0;

	public function new(circleImage:Image, finishImage:Image) {
		super(circleImage);

		this.finishImage = finishImage;

		addEvent(new UpdateEvent(onUpdate));
	}

	function onUpdate() {
		rotation.angle += Time.delta * 0.01;

		progress += 0.01;
		if (progress >= 1) {
			image = finishImage;
			rotation.angle = 0;
		}

		rel.changed = true;
	}
}
