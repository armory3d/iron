package wings.w2d.ui;
import wings.services.Pos;

class RectUI extends Tapable {
	
	public function new(onTap:Void->Void, sizeRel:Float = 0.14, addLine:Bool = true) {
		super(onTap);

		graphics.beginFill(Theme.UI_BG_COLOR[Theme.THEME]);
		graphics.drawRect(0, 0, Pos.w, Pos.x(sizeRel));
		graphics.endFill();

		// Cycle colors
		if ((++Theme.currentColor) >= Theme.COLORS.length) Theme.currentColor = 0;

		// Line
		if (addLine) {
			graphics.beginFill(Theme.UI_LINE_COLOR[Theme.THEME]);
			graphics.drawRect(0, Pos.x(sizeRel), Pos.w, 1);
			graphics.endFill();
		}

		graphics.beginFill(Theme.COLORS[Theme.currentColor]);
		graphics.drawRect(0, 0, Pos.x(0.015), Pos.x(sizeRel));
		graphics.endFill();
	}
}
