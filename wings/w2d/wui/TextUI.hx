package wings.w2d.ui;
import wings.w2d.TextItem;
import wings.services.Pos;
import wings.w2d.shapes.RectItem;

class TextUI extends Item {
	public var textItem:TextItem;
	
	public function new(text:String, size:Float = Theme.UI_TEXT_SIZE, addLine:Bool = true,
						align:Int = TextItem.ALIGN_CENTER, caption:String = null,
						bgColor:Int = 0xffffff, bgAlpha:Float = 0, textColor:Int = -1) {
		super();

		// Text
		var textX:Float;
		if (align == TextItem.ALIGN_CENTER) textX = Pos.w / 2;
		else if (align == TextItem.ALIGN_RIGHT) textX = Pos.x(0.95);
		else textX = Pos.x(0.05);

		if (textColor == -1) textColor = Theme.UI_TEXT_COLOR[Theme.THEME];
		textItem = new TextItem(text, textX, Pos.x(0.046), Pos.x(size), textColor, 1,
											 align, align);
		
		// Rect
		graphics.beginFill(bgColor, bgAlpha);
		graphics.drawRect(0, 0, Pos.w, Pos.x(0.075) + textItem.h);
		graphics.endFill();

		if (addLine) {
			graphics.beginFill(Theme.UI_LINE_COLOR[Theme.THEME]);
			graphics.drawRect(Pos.x(0.025), Pos.x(0.075) + textItem.h, Pos.x(0.95), 1);
			graphics.endFill();
		}

		// Text
		addChild(textItem);

		// Caption
		if (caption != null) {
			addChild(new TextItem(caption, Pos.x(0.95), Pos.x(0.046), Pos.x(size), Theme.UI_TEXT_COLOR[Theme.THEME], 1,
								 TextItem.ALIGN_RIGHT, TextItem.ALIGN_RIGHT));
		}
	}
}
