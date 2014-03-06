package wings.w2d.ui.popups;
import flash.display.Sprite;
import wings.w2d.TextItem;
import wings.w2d.ui.Tapable;
import wings.services.Pos;
import wings.services.Act;
import wings.w2d.Item;

class Popup extends Item
{
	public var textItem:TextItem;

	var fadeTime:Int;
	var offset:Float;
	
	public function new(text:String, sizeRel:Float = 0.3, fadeTime:Int = 200, yPosRel:Float = 0.7) 
	{
		super();
		this.fadeTime = fadeTime;

		// Dark bg TODO: dont move background
		graphics.beginFill(0x000000, 0.6);
		graphics.drawRect(-Pos.x(0.2), 0, Pos.w + Pos.x(0.4), Pos.h);
		graphics.endFill();

		// Text
		textItem = new TextItem(text, Pos.w / 2, Pos.x(yPosRel + 0.05) - Pos.x((sizeRel - 0.3) / 2), Pos.x(0.05), 0x000000, 1, TextItem.ALIGN_CENTER, TextItem.ALIGN_CENTER);
		var textOffset:Float = textItem.h - Pos.x(0.07);
		textItem.y -= textOffset;

		// Rect
		graphics.beginFill(0xffffff, 1);
		#if html5
		graphics.drawRoundRect(Pos.x(0.1), Pos.x(yPosRel) - Pos.x((sizeRel - 0.3) / 2) - textOffset, Pos.x(0.8), Pos.x(sizeRel) + textOffset, 15, 15);
		#else
		graphics.drawRoundRect(Pos.x(0.1), Pos.x(yPosRel) - Pos.x((sizeRel - 0.3) / 2) - textOffset, Pos.x(0.8), Pos.x(sizeRel) + textOffset, 15);
		#end
		graphics.endFill();

		// Add text
		addChild(textItem);

		alpha = 0;
		x = -Pos.x(0.2);
		Act.tween(this, fadeTime / 1000, {alpha: 1, x: 0});
	}

	function onCancelTap()
	{
		// Fade away
		Act.tween(this, fadeTime / 1000, {alpha: 0, x: Pos.x(0.2)}).onComplete( remove );
	}

	public function addText(text:String, x:Float, y:Float)
	{
		addChild(new TextItem(text, Pos.x(x), Pos.x(y) - offset, Pos.x(0.05), 0x007aff, 1, TextItem.ALIGN_CENTER));
	}

	public function addButton(onTap:Void->Void, x:Float, y:Float, w:Float = 0.4, h:Float = 0.15)
	{
		var buttonS:Tapable = new Tapable(onTap, 0, 0.1);
		buttonS.graphics.beginFill(0x000000, 1);
		buttonS.graphics.drawRect(Pos.x(x), Pos.x(y) - offset, Pos.x(w), Pos.x(h));
		buttonS.graphics.endFill();
		addChild(buttonS);
	}
}
