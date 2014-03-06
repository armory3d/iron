package wings.w2d.ui;
import wings.w2d.Item;
import wings.w2d.TextItem;
import wings.w2d.ui.layouts.Layout;
import wings.w2d.ui.popups.OkPopup;
import wings.services.Pos;
import wings.services.Storage;
import wings.w2d.shapes.RectItem;

class StickerUI extends Tapable {
	var onStickerTap:Void->Void;
	var layout:Layout;

	public function new(title:String, text:String, caption:String = "", onStickerTap:Void->Void, layout:Layout = null) {
		super(onFade);

		this.onStickerTap = onStickerTap;
		this.layout = layout;

		var size:Float = Pos.x(0.3);

		var container:Item = new Item();
		addChild(container);

		container.addChild(new RectItem(0, 0, size, size, Theme.COLORS[Theme.currentColor]));

		// Cycle colors
		if ((++Theme.currentColor) >= Theme.COLORS.length) Theme.currentColor = 0;

		// Title
		container.addChild(new TextItem(title,
							 size / 2, size / 8, Pos.x(0.054), 0xf6f6f6, 1, TextItem.ALIGN_CENTER));

		// Text
		container.addChild(new TextItem(text,
							 size / 2, size / 2.6, Pos.x(0.1), 0xf6f6f6, 1, TextItem.ALIGN_CENTER));

		// Caption
		container.addChild(new TextItem(caption,
							 size / 2, size / 1.3, Pos.x(0.054), 0xf6f6f6, 1, TextItem.ALIGN_CENTER));
	}

	function onFade() {
		if (onStickerTap != null) {
			if (layout != null) layout.transition(onStickerTap);
			else cast(owner.owner.owner, Layout).transition(onStickerTap);	// TODO: local layout variable
		}
	}
}
