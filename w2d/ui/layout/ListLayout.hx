package wings.w2d.ui.layout;

class ListLayout extends Layout {

	var spacing:Float;
	var type:LayoutType;

	var addLine:Bool = false;

	public function new(spacing:Float = 0, type:LayoutType = null) {
		if (type == null) type = LayoutType.Vertical;
		super();

		this.spacing = spacing;
		this.type = type;
	}

	public function nextLine() {
		addLine = true;
	}

	public override function addChild(child:Object2D) {

		// Adjust pos
		if (addLine) {
			addLine = false;

			if (type == LayoutType.Vertical)
				child.x = w;
			else
				child.y = h;
		}
		else if (children.length > 0) {
			if (type == LayoutType.Vertical) {
				child.x = children[children.length - 1].x;
				child.y = children[children.length - 1].y + children[children.length - 1].h + spacing;
			}
			else {
				child.x = children[children.length - 1].x + children[children.length - 1].w + spacing;
				child.y = children[children.length - 1].y;
			}
		}

		super.addChild(child);
	}
}
