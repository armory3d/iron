package wings.wxd;

import wings.wxd.events.Event;

class EventListener {

	public var events:Array<Event>;

	public function new() {
		reset();
	}

	public function update() {
		for (i in 0...events.length) if (events[i] != null) events[i].update();
	}

	public function addEvent(event:Event) {
		events.push(event);
		event.parent = this;
	}

	public function removeEvent(event:Event) {
		for (i in 0...events.length) {
			if (event == events[i]) events.splice(i, 1);
		}
	}

	public function reset() {
		events = new Array();
	}
}
