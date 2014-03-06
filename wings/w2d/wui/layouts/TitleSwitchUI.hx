package wings.w2d.ui.layouts;
import flash.display.Sprite;
import wings.w2d.TextItem;
import wings.w2d.ui.Tapable;
import wings.w2d.ui.Theme;
import wings.services.Pos;
import wings.w2d.shapes.RectItem;

class TitleSwitchUI extends TitleUI
{
	var state(default, null):Int;
	var stateText:TextItem;
	var states:Array<String>;

	public function new(text:String, onTap:Void->Void, state:Int, states:Array<String>) 
	{
		super(text, onTap);

		autoMenuHiding = false;
		this.state = state;
		this.states = states;

		textItem.x = Pos.x(0.05);

		// State text
		stateText = new TextItem(states[state], Pos.x(0.95), Pos.x(0.046), Pos.x(Theme.UI_TEXT_SIZE),
								 Theme.TITLE_ARROW_COLOR[Theme.THEME], 1, TextItem.ALIGN_RIGHT);
		addChild(stateText);
	}

	public function setState(st:Int)
	{
		state = st;
		if (state > states.length - 1) state = 0;

		stateText.text = states[state];
	}

	override function onTapped(item:Item)
	{
		super.onTapped(item);

		state++;
		setState(state);
	}
}
