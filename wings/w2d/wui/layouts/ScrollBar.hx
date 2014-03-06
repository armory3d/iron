package wings.w2d.ui.layouts;

import flash.display.Sprite;
import wings.w2d.Item;
import wings.services.Pos;

class ScrollBar extends Item
{
	var bar:Sprite;
	var yOffset:Float;

	var size:Float;

	public function new()
	{
		super();

		bar = new Sprite();
		//bar.graphics.lineStyle(4, 0x000000);
		bar.graphics.beginFill(0x000000, 0.15);
		bar.graphics.drawRect(0, 0, Pos.x(0.01), 1);
		bar.graphics.endFill();
		bar.x = Pos.w - (bar.width * 1.5);
		//addChild(bar);

		yOffset = Pos.x(0.35);
		bar.y = yOffset;
	}

	public function setSize(f:Float)
	{
		size = f;
		bar.height = Pos.y(1 / size * 140);
	}

	public function setPos(f:Float)
	{
		//bar.y = (Pos.h - yOffset) / size * (-f) + yOffset;

		// Scrolling length
		var length:Float = size - Pos.h;

		bar.y = ( (-f) + yOffset) * (size / Pos.h);
	}
}
