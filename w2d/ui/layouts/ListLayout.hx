package wings.w2d.ui.layouts;

enum ListType {
	Vertical; Horizontal;
}

class ListLayout extends Layout {

	var spacing:Float;
	var type:ListType;

	public function new(spacing:Float = 0, type:ListType = null) {
		if (type == null) type = Vertical;
		super();

		this.spacing = spacing;
		this.type = type;
	}

	// TODO: override addChild instead
	public function addUI(child:Object2D) {

		// Adjust pos
		if (children.length > 0) {
			if (type == Vertical)
				child.y = children[children.length - 1].y + children[children.length - 1].h + spacing;
			else
				child.x = children[children.length - 1].x + children[children.length - 1].w + spacing;
		}

		super.addChild(child);
	}
}
