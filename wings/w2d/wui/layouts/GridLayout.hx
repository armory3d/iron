package wings.w2d.ui.layouts;
import wings.Events.UpdateEvent;
import wings.Root;
import wings.services.Act;
import wings.services.Input;
import wings.services.Pos;
import wings.services.Time;

class GridLayout extends Layout
{
	var row:Item;
	var nextY:Float;
	var lastY:Float;

	var startY:Float;
	public var targetY:Float;

	var sliding:Bool;
	public var moving:Bool;
	var slideY:Float;

	// Scrolling
	var distance:Float;
	var touchTime:Float;

	var rowOffset:Float;

	// Scrollbar
	var scrollBar:ScrollBar;
	
	public function new(title:String, onBackTap:Void->Void = null, rowOffset = 0.06, forceArrow:Bool = false) 
	{ 
		super();

		// Title
		addTitle(title, onBackTap, true, forceArrow);

		// Row
		row = new Item();
		uiItem.addChild(row);
		this.rowOffset = rowOffset;

		startY = Pos.x(0.2);
		uiItem.y = startY;
		nextY = 0;
		lastY = 0;
		sliding = false;
		moving = false;

		distance = 0;
		touchTime = 0;

		// Scrollbar
		scrollBar = new ScrollBar();
		scrollBar.alpha = 0;
		addChild(scrollBar);
	}

	override function onLayoutFrame(item:Item)
	{
		// Start sliding
		if (Input.touch && !sliding)
		{
			lastY = Input.y;
			sliding = true;
			moving = false;

			// Scrolling
			distance = 0;
			touchTime = 0;
		}
		// End sliding
		else if (!Input.touch && !moving)
		{
			// Slide back to start
			if (uiItem.y > startY || uiItem.h < Pos.h - Pos.x(0.3))
			{
				targetY = startY;
			}
			// Slide back to bottom
			else if (uiItem.y + uiItem.h < Pos.h - Pos.x(0.2))
			{
				targetY = -uiItem.h + Pos.h - Pos.x(0.2);
			}
			else
			{
				// Scrolling
				if (distance != 0)
				{
					targetY = uiItem.y + distance * 2;

					// Stay in bounds
					if (targetY > startY) targetY = startY;
					else if (targetY < (-uiItem.h + Pos.h - Pos.x(0.2))) targetY = (-uiItem.h + Pos.h - Pos.x(0.2));
				}
				// Stay at current position
				else
				{
					// Scrollbar
					if (scrollBar.alpha > 0) scrollBar.alpha = 0; //Act.tween(scrollBar, 0.5, {alpha : 0});

					targetY = uiItem.y;
				}
			}

			sliding = false;
			if (targetY != uiItem.y) moving = true;	// Need to arrange?
			distance = 0;
		}

		// Slide
		if (sliding)
		{
			var delta:Float = Input.y - lastY;
			uiItem.y += delta;
			lastY = Input.y;

			// Count distance slided
			distance += delta;
			touchTime += Time.delta;

			// Cancel scrolling
			if (touchTime > 300) distance = 0;

			// Scrollbar
			if (delta != 0)
			{
				scrollBar.visible = true;
				scrollBar.alpha = 1;
			}

			// Update scrollbar
			scrollBar.setPos(uiItem.y);
		}

		// Arrange
		if (moving)
		{
			var delta:Float = Math.abs(targetY - uiItem.y);
			#if html5
			var velocity:Float = 15 * (delta + 5) / 120;
			#else
			var velocity:Float = Time.delta * (delta + 5) / 120;
			#end
			
			if (uiItem.y > targetY) velocity *= -1;
			
			uiItem.y += velocity;

			// Update scrollbar
			scrollBar.setPos(uiItem.y);
			
			// Finish arranging
			if ((uiItem.y > targetY && velocity > 0) ||
				(uiItem.y < targetY && velocity < 0))
			{
				uiItem.y = targetY;
				moving = false;

				// Scrollbar
				if (scrollBar.alpha > 0) scrollBar.alpha = 0; //Act.tween(scrollBar, 0.5, {alpha : 0});
			}
		}
	}

	public function addUI(item:Item, separator:Bool = true, nextRow:Bool = false, yOffset:Float = 0)
	{
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
			(item.w > Pos.w / 4 && row.numChildren >= 3) || 
			(item.w <= Pos.w / 4 && row.numChildren >= 4) || nextRow) 
		{
			// Store position
			nextY = row.y + row.h + Pos.x(rowOffset);
			if (!separator) nextY -= Pos.x(rowOffset);

			// Add new row
			row = new Item();
			uiItem.addChild(row);

			// Update scrollbar
			scrollBar.setSize(uiItem.h);
		}

		// Sliding-in transition
		uiItem.y = -nextY;
		sliding = false;
		moving = true;
		targetY = startY;
	}

	public override function transition(onTransition:Void->Void)
	{
		this.onTransition = onTransition;
		
		targetY = Pos.h * 1.5;
		moving = true;

		addEvent(new UpdateEvent(onTransitionFrame));
	}

	function onTransitionFrame(item:Item)
	{
		if (uiItem.y >= Pos.h * 1.1)
		{
			Root.reset();
			onTransition();
		}
	}
}
