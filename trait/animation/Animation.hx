package wings.trait.animation;

class Animation {

	public var name:String;
	public var frames:Array<Int>;
	public var frameTime:Float;

	public function new(name:String, frames:Array<Int>, frameTime:Float = 1) {
		this.name = name;
		this.frames = frames;
		this.frameTime = frameTime;
	}
}
