package fox.node;

class TimeNode extends FloatNode {

	public static inline var _startTime = 0; // Float
	public static inline var _stopTime = 1; // Float
	public static inline var _enabled = 2; // Bool
	public static inline var _loop = 3; // Bool
	public static inline var _reflect = 4; // Bool

	var modifier:Float = 1;

	public function new() {
		super();
	}

	public override function start() {
		super.start();

		f = inputs[_startTime].f;
	}

	public override function update() {
		super.update();
		
		if (inputs[_enabled].b) {
			f += fox.sys.Time.delta * modifier;

			// Time out
			if (inputs[_stopTime].f > 0) {
				if (modifier > 0 && f >= inputs[_stopTime].f ||
					modifier < 0 && f <= inputs[_startTime].f) {
					
					// Loop
					if (inputs[_loop].b) {

						// Reflect
						if (inputs[_reflect].b) {
							if (modifier > 0) {
								f = inputs[_stopTime].f;
							}
							else {
								f = inputs[_startTime].f;
							}

							modifier *= -1;
						}
						// Reset
						else {
							f = inputs[_startTime].f;
						}
					}
					// Stop
					else {
						f = inputs[_stopTime].f;
						inputs[_enabled].b = false;
					}
				}
			}
		}
	}

	public static function create(startTime:Float, stopTime:Float, enabled:Bool, loop:Bool, reflect:Bool) {
		var n = new TimeNode();
		n.inputs.push(FloatNode.create(startTime));
		n.inputs.push(FloatNode.create(stopTime));
		n.inputs.push(BoolNode.create(enabled));
		n.inputs.push(BoolNode.create(loop));
		n.inputs.push(BoolNode.create(reflect));
		return n;
	}
}
