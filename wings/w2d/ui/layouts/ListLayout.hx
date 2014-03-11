package wings.w2d.ui.layouts;

class ListLayout extends Layout {

	var spacing:Float;
	var offset:Float;
	var vertical:Bool;

	public function new(spacing:Float = 35, vertical:Bool = true) {
		super();

		this.spacing = spacing;
		this.vertical = vertical;
		offset = 0;
	}

	public function addUI(child:Object2D) {
		super.addChild(child);

		updateSize();

		// Adjust pos
		if (children.length > 1) {
			if (vertical)
				child.y = children[children.length - 2].y + children[children.length - 2].h;
			else
				child.x = children[children.length - 2].x + children[children.length - 2].w;
		}
	}

	public function addSeparator() {
		offset += spacing;
	}

	public override function updateLayout() {

		for (i in 1...children.length) {
			if (vertical)
				children[i].y = children[i - 1].y + children[i - 1].h;
			else
				children[i].x = children[i - 1].x + children[i - 1].w;
		}

		updateSize();
	}

	function updateSize() {
		if (children.length > 0) {
			w = children[children.length - 1].x + children[children.length - 1].w;
			h = children[children.length - 1].y + children[children.length - 1].h;
		}

		// TODO: proper size calculation
		h = 0;
		for (i in 0...children.length) {
			if (vertical) h += children[i].h;
		}
	}
}
