package wings.w2d.ui;
import kha.Image;
import wings.w2d.ImageItem;
import wings.w2d.shapes.CircleItem;
import wings.w2d.shapes.RectItem;
import wings.w2d.ui.layouts.Layout;
import wings.services.Pos;

class IconUI extends Tapable {
	var onIconTap:Void->Void;
	var layout:Layout;
	public var iconImage:ImageItem;
	
	public function new(text:String, icon:Image, onIconTap:Void->Void, fading:Bool = true,
						sizeRel:Float = 0.3, fontSizeRel:Float = 0.054, sizeWAdd:Float = 0,
						layout:Layout = null) {
		this.onIconTap = onIconTap;
		this.layout = layout;
		
		if (fading) super(onFade);
		else super(onIconTap);
		
		var sizeW:Float = Pos.x(sizeRel + sizeWAdd);
		var sizeH:Float = Pos.x(sizeRel);

		// Rect
		//fontSizeRel = 0.044;
		//addChild(new CircleItem(sizeW / 2, sizeH / 2, sizeW / 2, Theme.COLORS[Theme.currentColor]));
		addChild(new RectItem(0, 0, sizeW, sizeH, Theme.COLORS[Theme.currentColor]));

		// Cycle colors
		if ((++Theme.currentColor) >= Theme.COLORS.length) Theme.currentColor = 0;

		// Icon
		iconImage = new ImageItem(icon, sizeW / 2 - icon.width / 2, sizeH / 2 - icon.height / 2, 1, true);
		
			// Icon too big/small
			/*if (iconImage.width > sizeW * 0.6 || iconImage.width < sizeW * 0.35)
			{
				iconImage.scaleX = sizeW * 0.4 / iconImage.width;
				iconImage.scaleY = iconImage.scaleX;

				iconImage.x = sizeW / 2 - iconImage.width / 2;
				iconImage.y = sizeH / 2 - iconImage.height / 2;
			}
			else *//*if (iconImage.height > sizeH * 0.6 || iconImage.height < sizeH * 0.25)
			{
				iconImage.scaleX = sizeH * 0.4 / iconImage.height;
				iconImage.scaleY = iconImage.scaleX;

				iconImage.x = sizeW / 2 - iconImage.width / 2;
				iconImage.y = sizeH / 2 - iconImage.height / 2;
			}*/
		
		addChild(iconImage);

		// Text
		addChild(new TextItem(text, sizeW / 2, sizeH / 1.29, Pos.x(fontSizeRel), 0xffffff, 1, TextItem.ALIGN_CENTER));
	}

	function onFade() {
		if (onIconTap != null) {
			if (layout != null) layout.transition(onIconTap);
			else cast(owner.owner.owner, Layout).transition(onIconTap);	// TODO: local layout variable
		}
	}
}
