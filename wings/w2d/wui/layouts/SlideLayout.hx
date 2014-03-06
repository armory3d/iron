package wings.w2d.ui.layouts;
import wings.Events.UpdateEvent;
import wings.w2d.Item;
import wings.services.Input;
import wings.services.Pos;
import wings.services.Time;
import wings.Root;

class SlideLayout extends Layout
{
	var slidesA:Array<Item>;
	var slidesX:Float;
	var dots:Item;
	
	var numSlides:Int;
	var currentSlide:Int;
	
	var sliding:Bool;
	var lastX:Float;
	
	var moving:Bool;
	var targetX:Float;
	
	var slideW:Float;

	public function new(title:String, onBackTap:Void->Void = null) 
	{
		super();

		// TODO: local layout variable
		var layer:Item = new Item();
		uiItem.remove();
		layer.addChild(uiItem);
		addChild(layer);

		// TODO: local layout and remove this
		titleMenuContainer.remove();
		addChild(titleMenuContainer);

		// Title
		addTitle(title, onBackTap);
		
		slidesA = new Array();
		
		dots = new Item();
		addChild(dots);
		
		numSlides = 0;
		currentSlide = 0;
		
		sliding = false;
		moving = false;
	}
	
	public function setCurrentSlide(slide:Int)
	{
		currentSlide = slide;

		// No such slide
		if (currentSlide >= numSlides) currentSlide = 0;

		targetX = Pos.cw(slideW) - uiItem.getChildAt(currentSlide).x;
		moving = true;
		
		setDot();
	}

	public function getCurrentSlide():Int
	{
		return currentSlide;
	}
	
	public function addUI(item:Item, spacing:Float = 1.2)
	{
		// Items are stacked on x axis
		if (Std.is(item, Tapable))
		{
			cast(item, Tapable).yAxis = false;
		}

		// Slided item
		slideW = item.w;
		item.x = item.w * spacing * numSlides;
		item.y = Pos.ch(item.h);
		//slidesX = Pos.cw(item.w);
		//uiItem.x = slidesX;
		uiItem.addChild(item);
		
		// Dot
		var dotW:Float = Pos.x(0.03);
		dots.addChild(new SlideDot(dotW * 1.2 /*spacing*/ * 1.2 * numSlides, dotW / 10, dotW / 2));
		dots.x = Pos.cw(dots.w) + dotW / 2;
		if (Pos.w != Pos.h) dots.y = Pos.h - dotW - Pos.y(0.1);
		else 				dots.y = Pos.h - dotW - Pos.y(0.08);	// TODO: remove
		setDot();
		
		numSlides++;

		// Sliding-in transition
		if (numSlides == 1)
		{
			slidesX = Pos.w;
			uiItem.x = slidesX;
		}
	}
	
	override function onLayoutFrame(item:Item)
	{
		// Begin sliding
		if (Input.touch && !sliding)
		{
			sliding = true;
			moving = false;
			lastX = Input.x;
		}
		else if (!Input.touch)
		{
			sliding = false;
		}
		
		// Slide items
		if (sliding)
		{
			var deltaX:Float = Input.x - lastX;
			slidesX += deltaX;
			uiItem.x = slidesX;
			lastX = Input.x;
		}
		// Sliding over, arrange items
		else
		{
			// Not moving yet
			if (!moving)
			{
				var startX:Float = Pos.cw(slideW) - uiItem.getChildAt(currentSlide).x;
				var deltaX:Float = slidesX - startX;
				
				// Swipe to left
				if (deltaX <= -Pos.x(0.2) && currentSlide < uiItem.numChildren - 1)
				{
					currentSlide++;
					setDot();
				}
				// Swipe to right
				else if (deltaX >= Pos.x(0.2) && currentSlide > 0)
				{
					currentSlide--;
					setDot();
				}
				
				// Return to correct position
				targetX = Pos.cw(slideW) - uiItem.getChildAt(currentSlide).x;
				
				// Start moving
				if (slidesX != targetX)
				{
					moving = true;
				}
			}
			// Move
			else
			{
				var deltaX:Float = Math.abs(targetX - slidesX);
				var velocity:Float = Time.delta * (deltaX + 5) / 120;				
				
				if (slidesX > targetX) velocity *= -1;
				
				slidesX += velocity;
				uiItem.x = slidesX;
				
				if ((slidesX >= targetX && velocity > 0) ||
					(slidesX <= targetX && velocity < 0))
				{
					slidesX = targetX;
					uiItem.x = slidesX;
					moving = false;
				}
			}
		}
	}

	public override function transition(onTransition:Void->Void)
	{
		this.onTransition = onTransition;
		
		targetX = Pos.w * 1.5;
		moving = true;

		addEvent(new UpdateEvent(onTransitionFrame));
	}

	function onTransitionFrame(item:Item)
	{
		if (uiItem.x >= Pos.w * 1.1)
		{
			Root.reset();
			onTransition();
		}
	}
	
	function setDot()
	{
		for (i in 0...dots.numChildren) 
		{
			if (i == currentSlide) cast(dots.getChildAt(i), SlideDot).alpha = 1;
			else cast(dots.getChildAt(i), SlideDot).alpha = 0.2;
		}
		
		// Display only needed slides
		/*for (i in 0...slidesA.length)
		{
			if (i == currentSlide || i == currentSlide - 1 || i == currentSlide + 1)
			{
				if (slidesA[i].owner != uiItem)
				{
					//slidesA[i].x = slidesA[i].w * 1.2 * numSlides;
					//slidesA[i].y = Pos.ch(slidesA[i].h);
					//uiItem.addChild(slidesA[i]);
					slidesA[i].alpha = 0.2;
				}
			}
			else
			{
				//if (slidesA[i].owner == uiItem) uiItem.removeItem(slidesA[i]);
				slidesA[i].alpha = 0;
			}
		}*/
	}
}
