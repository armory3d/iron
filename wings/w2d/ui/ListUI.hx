package wings.w2d.ui;

import wings.w2d.shapes.PolyShape;
import wings.wxd.events.TapEvent;
import wings.w2d.ui.layouts.Layout;
import wings.w2d.ui.layouts.ListLayout;
import wings.w2d.shapes.RectShape;
import wings.w2d.Text2D;

class ListUI extends ButtonUI {

	var layout:ListLayout;
	var arrow:PolyShape;

	public function new(title:String /*TODO , show:Bool = false*/) {
		super(title, onTap, 0xff1a1a1a);

		// Arrow
		arrow = new PolyShape(10, 15, 10, 10);
		addChild(arrow);

		layout = new ListLayout();
		layout.y = h;
		addChild(layout);
	}

	public function addUI(child:ObjectUI) {
		layout.addUI(child);

		// Offset
		var offset = 5;
		child.x = offset;

		// Find depth
		var depth:Int = 0;
		var p = child;
		while(p != null) {
			if (Std.is(p.parent.parent, ListUI)) {
				depth++;
				p = cast(p.parent.parent, ObjectUI);
			}
			else p = null;
		}

		// Set child size based on depth
		child.w -= offset * depth;
		child.shapeW = child.w;
		child.lineRect.w -= offset * depth;
		child.lineRect.shapeW = child.lineRect.w;
		
		// Set size
		w = layout.w;
		if (layout.parent != null) {
			// Update size if contents are visible
			h = shapeH + layout.h;
		}
	}

	function onTap() {
		// Switch contents
		if (layout.parent == null) {
			showContents(true);
		}
		else {
			showContents(false);
		}

		// Update items in layout
		if (Std.is(parent, Layout)) cast(parent, Layout).updateLayout();
	}

	public function showContents(show:Bool) {
		// Display contents
		if (show && layout.parent == null) {
			addChild(layout);
			arrow.rotation = 0;
			h = shapeH + layout.h;
		}
		// Hide contents
		else if (layout.parent != null) {
			removeChild(layout);
			arrow.rotation = 270;
			h = shapeH;
		}
	}
}
