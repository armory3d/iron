package wings.w2d.ui.layouts;
import wings.w2d.ui.Theme;
import wings.services.Act;
import flash.display.Sprite;
#if android
import flash.events.Event;
import flash.events.KeyboardEvent;
#end
import wings.Events.UpdateEvent;
import wings.services.Audio;
import wings.services.Pos;
import wings.Root;
import wings.services.Time;

class TitleItem extends Tapable
{
	var onBackTap:Void->Void;
	var fading:Bool;
	var forceArrow:Bool;

	public var uiContainer:Item;
	var uiItem:Item;
	public var arrowSprite:Sprite;

	var targetY:Float;

	// var tapOverlay:Sprite;
	
	public function new(title:String, onBackTap:Void->Void, fading:Bool = true, forceArrow:Bool = false)
	{
		super(onFade);

		tap = Theme.SOUND_BACK;

		this.onBackTap = onBackTap;
		this.fading = fading;
		this.forceArrow = forceArrow;	// TODO: check if titleuis are present instead
		uiItem = null;

		// Sprite
		var f:Float = Pos.x(0.004);
		var s:Sprite = new Sprite();

		// Title
		s.graphics.beginFill(Theme.TITLE_COLOR[Theme.THEME]);
		s.graphics.drawRect(0, 0, Pos.w, f * 35);
		s.graphics.endFill();

		// Line
		s.graphics.beginFill(Theme.TITLE_LINE_COLOR[Theme.THEME]);
		s.graphics.drawRect(0, f * 35, Pos.w, 1);
		s.graphics.endFill();

		// Back arrow
		if (onBackTap != null || forceArrow)
		{
			arrowSprite = new Sprite();
			arrowSprite.graphics.lineStyle(Pos.x(0.009), Theme.TITLE_ARROW_COLOR[Theme.THEME]);
			arrowSprite.graphics.moveTo(0, -Pos.x(0.03));
			arrowSprite.graphics.lineTo(-Pos.x(0.03), 0);
			arrowSprite.graphics.lineTo(0, Pos.x(0.03));
			arrowSprite.x = Pos.x(0.09);
			arrowSprite.y = Pos.x(0.072);
			s.addChild(arrowSprite);
		}

		addChild(s);

		// Tap overlay
		// tapOverlay = new Sprite();
		// tapOverlay.graphics.beginFill(0x000000);
		// tapOverlay.graphics.drawRect(0, 0, Pos.w, f * 35);
		// tapOverlay.graphics.endFill();
		// tapOverlay.alpha = 0;
		// addChild(tapOverlay);

		// Text
		/*var font:String = Theme.FONT;
		Theme.FONT = Theme.FONT_BOLD;

		addChild(new TextItem(title, Pos.w / 2, Pos.x(0.06), Pos.x(0.07),
							 Theme.TITLE_TEXT_COLOR[Theme.THEME], 1, TextItem.ALIGN_CENTER));

		Theme.FONT = font;*/

		#if html5
		addChild(new TextItem(title, Pos.w / 2, Pos.x(0.025), Pos.x(0.07),
		#else
		addChild(new TextItem(title, Pos.w / 2, Pos.x(0.04), Pos.x(0.07),
		#end
							 Theme.TITLE_TEXT_COLOR[Theme.THEME], 1, TextItem.ALIGN_CENTER));


		// Back key
		#if android
		if (onBackTap != null)
		{
			flash.Lib.current.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
		}
		#end
	}

	public function addUI(item:TitleUI)
	{
		// Create UI item first
		if (uiItem == null)
		{
			uiItem = new Item();

			// Exit button
			if (onBackTap != null)
			{
				var exitUI:TitleUI = new TitleUI("Exit", onTransition);
				exitUI.titleItem = this;
				uiItem.addChild(exitUI);
			}

			// Rotate arrow to point down
			arrowSprite.rotation = 270;
			arrowSprite.y = Pos.x(0.058);
		}

		// Add UI
		item.y = uiItem.h;
		item.titleItem = this;
		uiItem.addChild(item);
	}

	#if android
	function onKeyUp(event:KeyboardEvent)
	{	
		if (event.keyCode == 27)
		{	
			event.stopImmediatePropagation();
			onFade();
		}
	}

	function onRemovedFromStage(event:Event)
	{
		flash.Lib.current.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		removeEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
	}
	#end

	function onFade()
	{
		// Call assigned method
		if (uiItem == null)
		{
			onTransition();
		}
		// Show/hide title menu
		else
		{
			if (uiItem.parent == null)
			{
				displayMenu(true);

				Act.tween(arrowSprite, 0.2, {y: Pos.x(0.085), rotation: 90});//.ease(motion.easing.Bounce.easeOut);
			}
			else
			{
				displayMenu(false);

				Act.tween(arrowSprite, 0.2, {y: Pos.x(0.058), rotation: -90});//.ease(motion.easing.Bounce.easeOut);
			}
		}
	}

	function onTransition()
	{
		if ((onBackTap != null || forceArrow) && !fading)
		{
			Root.reset();
			onBackTap();
		}
		else if (onBackTap != null || forceArrow)
		{
			cast(owner, Layout).transition(onBackTap);	// TODO: local layout variable
		}
	}

	public function displayMenu(show:Bool)
	{
		if (show)
		{
			uiItem.y = h - uiItem.h;
			targetY = h;
			uiContainer.addChild(uiItem);	// Added to layout, separated from title Events
		
			Act.tween(uiItem, 0.2, {y: targetY});//.ease(motion.easing.Elastic.easeOut);
		}
		else
		{
			targetY = h - uiItem.h;
		
			Act.tween(uiItem, 0.2, {y: targetY}).onComplete( uiContainer.removeChild(uiItem) );//.ease(motion.easing.Bounce.easeOut);
		}
	}

	function onTweenComplete()
	{
		uiContainer.removeChild(uiItem);
	}

	override function onTapped(item:Item)
	{
		if (!cancel && (onBackTap != null || forceArrow))
		{
			Audio.playSound(tap);
			onPress();
		}
		else
		{
			cancel = false;
		}
	}
	
	override function onTapDown(item:Item)
	{
		if (onBackTap != null || forceArrow)
		{
			item.alpha = tapAlpha;
			//tapOverlay.alpha = 0.05;
		}
	}
	
	override function onTapUp(item:Item)
	{
		if (onBackTap != null || forceArrow)
		{
			item.alpha = defaultAlpha;
			//tapOverlay.alpha = 0;
		}
	}
}
