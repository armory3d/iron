package fox.node;

class Node {

	public var inputs:Array<Dynamic> = [];

	public function new() {
		
	}

	public function update() {
		for (inp in inputs) inp.update();
	}

	public function start() {
		for (inp in inputs) inp.start();
	}
}
