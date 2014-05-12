package wings.wxd;

import wings.wxd.event.Event;

class EventListener {

	public var events:Array<Event>;
	public var permanents:Array<Event>;

	public var forcedInput:Bool = false;

	public function new() {
		permanents = [];
		reset();
	}

	public function update() {
		for (i in 0...events.length) if (events[i] != null) events[i].update();
	}

	public function addEvent(event:Event, permanent:Bool = false) {
		events.push(event);
		event.parent = this;
		event.added();

		if (permanent) permanents.push(event);
	}

	public function removeEvent(event:Event, permanent:Bool = false) {
		events.remove(event);
		
		if (permanent) permanents.remove(event);
	}

	public function reset() {
		events = new Array();

		for (i in 0...permanents.length) {
			addEvent(permanents[i]);
		}
	}
}
