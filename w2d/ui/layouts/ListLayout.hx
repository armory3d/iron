package wings.w2d.ui.layouts;

enum ListType {
	Vertical; Horizontal;
}

class ListLayout extends Layout {

	var spacing:Float;
	var type:ListType;

	var addLine:Bool = false;

	public function new(spacing:Float = 0, type:ListType = null) {
		if (type == null) type = ListType.Vertical;
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

			if (type == ListType.Vertical)
				child.x = w;
			else
				child.y = h;
		}
		else if (children.length > 0) {
			if (type == ListType.Vertical) {
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
