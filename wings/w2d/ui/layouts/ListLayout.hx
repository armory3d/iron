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

	public function addUI(child:Object2D) {
		super.addChild(child);

		// Adjust pos
		if (children.length > 1) {
			if (type == Vertical)
				child.y = children[children.length - 2].y + children[children.length - 2].h + spacing;
			else
				child.x = children[children.length - 2].x + children[children.length - 2].w + spacing;
		}
	}
}
