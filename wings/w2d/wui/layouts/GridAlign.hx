package wings.w2d.ui.layouts;
import wings.Events.UpdateEvent;
import wings.Root;
import wings.services.Input;
import wings.services.Pos;
import wings.services.Time;

class GridAlign extends Item
{
	var row:Item;
	var nextY:Float;
	var lastY:Float;
	
	public function new() 
	{ 
		super();

		// Row
		row = new Item();
		addChild(row);
		
		nextY = 0;
		lastY = 0;
	}

	public function addUI(item:Item, separator:Bool = true, nextRow:Bool = false, independent:Bool = false,
						  yOffset:Float = 0)
	{
		if (independent)
		{
			row.addChild(item);

			// Center row
			row.x = Pos.cw(row.w);

			// Add new row
			row = new Item();
			addChild(row);

			return;
		}

		// Set row position
		if (row.numChildren == 0)
		{
			row.y = nextY + Pos.x(yOffset);
		}

		// Add item
		item.x = row.numChildren * item.w * 1.1;
		row.addChild(item);

		// Center row
		row.x = Pos.cw(row.w);

		// Next row
		if ((item.w > Pos.w / 2 && row.numChildren >= 1) ||
			(item.w > Pos.w / 3 && row.numChildren >= 2) ||
			(item.w <= Pos.w / 3 && row.numChildren >= 3) ||
			nextRow) 
		{
			// Store position
			nextY = row.y + row.h + Pos.x(0.06);
			if (!separator) nextY -= Pos.x(0.06);

			// Add new row
			row = new Item();
			addChild(row);
		}
	}
}
