package wings.w2d.ui.layouts;
import flash.display.Sprite;
import wings.w2d.Item;
import wings.w2d.shapes.CircleItem;
import wings.w2d.shapes.RectItem;
import wings.Events.UpdateEvent;
import wings.w2d.ui.Theme;
import wings.services.Pos;

class Layout extends RectItem
{
	var uiItem:Item;
	var titleMenuContainer:Item;
	var onTransition:Void->Void;

	var titleItem:TitleItem;

	public function new() 
	{
		// Bg
		super(0, 0, Pos.w, Pos.h, Theme.BG_COLOR[Theme.THEME]);

		/*if (addBg)
		{
			for (i in 0...9)
			{
				for (j in 0...14)
				{
					var x:Float = i * 60;
					if (j % 2 == 0) x += 30;
					addChild(new CircleItem(x, j * 60, 15, Theme.getColor(), 0.05));
				}
			}
		}*/

		Root.addChild(this);
		
		addEvent(new UpdateEvent(onLayoutFrame));

		// UI layer
		uiItem = new Item();
		addChild(uiItem);

		// Title menu
		titleMenuContainer = new Item();
		addChild(titleMenuContainer);
	}

	function addTitle(title:String, onBackTap:Void->Void = null, fading:Bool = true, forceArrow:Bool = false)
	{
		// Title
		titleItem = new TitleItem(title, onBackTap, fading, forceArrow);
		titleItem.uiContainer = titleMenuContainer;
		addChild(titleItem);
	}

	inline function addTitleUI(item:TitleUI)
	{
		titleItem.addUI(item);
	}
	
	function onLayoutFrame(item:Item)
	{
		
	}

	public function transition(onTransition:Void->Void)
	{

	}
}
