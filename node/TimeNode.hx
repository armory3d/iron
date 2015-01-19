package fox.node;

class TimeNode extends FloatNode {

	public function new(f:Float) {
		super();
	}

	public override function update() {
		f += fox.sys.Time.delta;
	}
}
