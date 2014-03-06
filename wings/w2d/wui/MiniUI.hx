package wings.w2d.ui;
import wings.w2d.Item;
import wings.w2d.TextItem;
import wings.w2d.ui.layouts.Layout;
import wings.w2d.ui.popups.OkPopup;
import wings.services.Pos;
import wings.services.Storage;
import wings.w2d.shapes.RectItem;

class MiniUI extends Tapable {
	var onMiniTap:Void->Void;
	var layout:Layout;

	public function new(text:String, onMiniTap:Void->Void, layout:Layout = null, fading:Bool = true) {
		this.onMiniTap = onMiniTap;
		this.layout = layout;

		if (fading) super(onFade);
		else super(onMiniTap);

		var size:Float = Pos.x(0.4);

		var container:Item = new Item();
		addChild(container);

		container.addChild(new RectItem(0, 0, size, size / 3, Theme.COLORS[Theme.currentColor]));

		// Cycle colors
		if ((++Theme.currentColor) >= Theme.COLORS.length) Theme.currentColor = 0;

		// Text
		container.addChild(new TextItem(text,
							 size / 2, size / 10, Pos.x(0.06), 0xf6f6f6, 1, TextItem.ALIGN_CENTER));
	}

	function onFade() {
		if (onMiniTap != null) {
			if (layout != null) layout.transition(onMiniTap);
			else cast(owner.owner.owner, Layout).transition(onMiniTap);	// TODO: local layout variable
		}
	}
}
