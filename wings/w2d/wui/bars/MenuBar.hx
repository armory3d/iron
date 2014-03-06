package wings.w2d.ui.bars;

import flash.display.BitmapData;
import wings.w2d.ImageItem;
import wings.w2d.shapes.RectItem;
import wings.w2d.TextItem;
import wings.w2d.ui.Tapable;
import wings.w2d.ui.Theme;
import wings.services.Pos;

class MenuBar extends Item
{

	public function new(texts:Array<String>, icons:Array<BitmapData>, onTaps:Array<Void->Void>,
						tab:Int = 0, isChildScene:Bool = false)
	{
		super();

		// Rect
		graphics.beginFill(0x000000);
		graphics.drawRect(0, Pos.h - Pos.x(0.15), Pos.w, Pos.x(0.15));
		graphics.endFill();

		// Line
		graphics.beginFill(0x222222);
		graphics.drawRect(0, Pos.h - Pos.x(0.15), Pos.w, 1);
		graphics.endFill();

		// Icon with text
		var posY:Float = Pos.h - Pos.x(0.044);
		var stepX:Float = Pos.w / (texts.length);

		for (i in 0...texts.length)
		{
			var posX:Float = stepX * (i + 1) - stepX / 2;

			// Taps
			var rect:Tapable;

			// Highlight current tab or child scene of tab
			if (i == tab && isChildScene) rect = new Tapable(onTaps[i], 0.7, 0.7);
			else if (i != tab) rect = new Tapable(onTaps[i]);
			else rect = new Tapable(null, 0.7, 0.7);

			rect.graphics.beginFill(0x302c2f);
			rect.graphics.drawRect(0, 0, stepX, Pos.x(0.15));
			rect.graphics.endFill();
			rect.x = stepX * i;
			rect.y = Pos.h - Pos.x(0.15);
			addChild(rect);

			// Icon
			var ii:ImageItem = new ImageItem(icons[i], posX, Pos.h - Pos.x(0.085));
			ii.x -= ii.w / 2;
			ii.y -= ii.h / 2;
			ii.mouseEnabled = false;
			if (i != tab) ii.alpha = 0.7;
			addChild(ii);

			// Text
			var ti:TextItem = new TextItem(texts[i], posX, posY, Pos.x(0.04), 0xeeeeee, 1, TextItem.ALIGN_CENTER);
			ti.mouseEnabled = false;
			if (i != tab) ti.alpha = 0.7;
			addChild(ti);
		}
	}
}
