package wings.w2d.ui.bars;

import wings.w2d.shapes.RectItem;
import wings.services.Pos;

class SideBar extends Item
{	


	public function new()
	{
		super();

		addChild(new RectItem(0, 0, Pos.x(0.9), Pos.h, 0x333333));
	}

	public function addUI(item:Item, separator:Bool = true, nextRow:Bool = false)
	{

	}
}
