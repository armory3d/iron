package wings.w2d.ui;
import kha.Image;
import wings.w2d.Item;
import wings.w2d.ImageItem;
import wings.services.Pos;
import wings.w2d.shapes.RoundItem;

class LabelUI extends RectUI {
	
	public function new(text:String, icon:BitmapData, onTap:Void->Void, addLine:Bool = true)  {
		var sizeRel:Float = 0.2;

		super(onTap, sizeRel, addLine);

		// Arrow 0.14
		/*var s:Sprite = new Sprite();
		s.graphics.lineStyle(Pos.x(0.007), 0xcccccc);
		s.graphics.moveTo(0, 0);
		s.graphics.lineTo(Pos.x(0.02), Pos.x(0.02));
		s.graphics.lineTo(0, Pos.x(0.04));
		s.x = w - Pos.x(0.05) - s.width;
		s.y = Pos.x(0.083);
		addChild(s);*/

		var image:ImageItem = new ImageItem(icon, Pos.x(0.02), Pos.x(0.01));
		addChild(image);

		// Text
		addChild(new TextItem(text, Pos.x(0.2), Pos.x(0.076), Pos.x(Theme.UI_TEXT_SIZE),
							 Theme.UI_TEXT_COLOR[Theme.THEME]));
	}
}
