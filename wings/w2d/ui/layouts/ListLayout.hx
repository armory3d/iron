package wings.w2d.ui.layouts;

class ListLayout extends Layout {

	var spacing:Float;
	var offset:Float;
	var vertical:Bool;

	public function new(spacing:Float = 20, vertical:Bool = true) {
		super();

		this.spacing = spacing;
		this.vertical = vertical;
		offset = 0;
	}

	public override function addChild(child:Object2D) {
		super.addChild(child);

		// Adjust y pos
		if (vertical)
			child.y = (children.length - 1) * spacing + offset;
		else
			child.x = (children.length - 1) * spacing + offset;
	}

	public function addSeparator() {
		offset += spacing;
	}
}
