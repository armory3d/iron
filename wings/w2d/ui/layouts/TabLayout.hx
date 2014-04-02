package wings.w2d.ui.layouts;

import wings.w2d.shapes.RectShape;
import wings.w2d.ui.layouts.ListLayout;

class TabButton extends Button {

	var tab:Int;
	var onTap:Int->Void;

	public function new(title:String, tab:Int, onTap:Int->Void) {
		super(title, 100, 35, _onTap);
		this.tab = tab;
		this.onTap = onTap;
	}

	function _onTap() {
		onTap(tab);
	}
}

class TabLayout extends ListLayout {

	public var tabs:Array<Object2D>;
	var currentTab:Int;

	// TODO: add tabs dynamically
	public function new(titles:Array<String>, w:Float, h:Float) {
		super(5, ListType.Horizontal);

		// Object for each tab
		tabs = new Array();

		for (i in 0...titles.length) {
			var tb = new TabButton(titles[i], i, onTabTap);
			addUI(tb);
			
			var tabObject = new Object2D();
			tabObject.y = 35;
			tabs.push(tabObject);
		}

		// Tab background
		addChild(new RectShape(0, 35, w, h, 0xff333333));

		// Show tab content
		currentTab = 0;
		addChild(tabs[currentTab]);
	}

	function onTabTap(tab:Int) {
		setTab(tab);
	}

	public function setTab(tab:Int) {
		removeChild(tabs[currentTab]);

		currentTab = tab;
		addChild(tabs[currentTab]);
	}
}
