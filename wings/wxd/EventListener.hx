package wings.wxd;

import wings.wxd.events.Event;

class EventListener {

	public var events:Array<Event>;

	public var forcedInput:Bool = false;

	public function new() {
		reset();
	}

	public function update() {
		for (i in 0...events.length) if (events[i] != null) events[i].update();
	}

	public function addEvent(event:Event) {
		events.push(event);
		event.parent = this;
		event.added();
	}

	public function removeEvent(event:Event) {
		events.remove(event);
	}

	public function reset() {
		events = new Array();
	}
}
