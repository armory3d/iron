package wings.w2d.ui;

import wings.w2d.shapes.RectShape;
import wings.wxd.events.TapEvent;
import wings.wxd.events.UpdateEvent;
import wings.w2d.Text2D;
import wings.wxd.Input;

class SlideUI extends ButtonUI {

	var value:Float;
	var valueFrom:Float;
	var valueTo:Float;
	var onTap:Void->Void;

	var sliderBg:RectShape;
	var slider:RectShape;
	var stateText:Text2D;

	var updateEvent:UpdateEvent;

	public function new(title:String, onTap:Void->Void, value:Float = 0, valueFrom:Float = 0, valueTo:Float = 1) {
		super(title, _onTap, 0xff2fa1d6);

		// From value from-to to 0-1;
		this.value = (value - valueFrom) / (valueTo - valueFrom);
		this.valueFrom = valueFrom;
		this.valueTo = valueTo;
		this.onTap = onTap;

		// Slider bg
		sliderBg = new RectShape(100, 5, 100, 25, 0xff303030);
		sliderBg.addEvent(new TapEvent(onSliderTap, TapEvent.TYPE_START));
		addChild(sliderBg);

		// Slider
		slider = new RectShape(sliderBg.x, sliderBg.y, sliderBg.w * this.value, sliderBg.h, 0xff2fa1d6);
		addChild(slider);

		// State
		stateText = new Text2D(stateToString(), Theme.FONT, 240, 10, 0xffe5e5e5);
		addChild(stateText);

		updateEvent = new UpdateEvent(onSlide);
	}

	function onSliderTap() {
		Input.preventRelease = true;
		addEvent(updateEvent);
	}

	function onSlide() {
		if (Input.touch) {
			// Set slider size
			var x = Input.x - slider._x;

			// Cap size
			if (x < 0) x = 0;
			else if (x > sliderBg.w) x = sliderBg.w;

			slider.w = x;
			slider.shapeW = slider.w;

			value = slider.w / sliderBg.w;
			stateText.text = stateToString();
		}
		else {
			// Stop sliding
			removeEvent(updateEvent);
		}
	}

	function stateToString():String {

		return Std.int(getUnclampedValue() * 10) / 10 + "";
	}

	function _onTap() {
		
		var result = getUnclampedValue();
		
		onTap();
	}

	function getUnclampedValue():Float {

		// From 0-1 to value from-to
		return (valueFrom + valueTo) * value - valueFrom;
	}
}
