package wings.w2d.ui.layouts;
import flash.display.Sprite;
import wings.w2d.TextItem;
import wings.w2d.ui.Tapable;
import wings.w2d.ui.Theme;
import wings.services.Pos;
import wings.w2d.shapes.RectItem;

class TitleUI extends Tapable
{
	public var titleItem:TitleItem; // Set in TitleItem
	public var textItem:TextItem;

	var autoMenuHiding:Bool;
	
	public function new(text:String, onTap:Void->Void) 
	{
		super(onTap);

		autoMenuHiding = true;

		graphics.beginFill(Theme.UI_BG_COLOR[Theme.THEME]);
		graphics.drawRect(0, 0, Pos.w, Pos.x(0.14));
		graphics.endFill();

		// Line
		graphics.beginFill(Theme.UI_LINE_COLOR[Theme.THEME]);
		graphics.drawRect(0, Pos.x(0.14), Pos.w, 1);
		graphics.endFill();

		// Text
		textItem = new TextItem(text, Pos.w / 2, Pos.x(0.044), Pos.x(0.06), Theme.UI_TEXT_COLOR[Theme.THEME], 1, TextItem.ALIGN_CENTER);
		addChild(textItem);
	}

	override function onTapped(item:Item)
	{
		super.onTapped(item);

		// Automatically hide menu
		if (titleItem != null && autoMenuHiding)
		{
			titleItem.displayMenu(false);

			titleItem.arrowSprite.rotation = 270;
			titleItem.arrowSprite.y = Pos.x(0.058);
		}
	}
}
