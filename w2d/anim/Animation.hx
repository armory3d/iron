package wings.w2d.anim;

class Animation {

	public var name:String;
	public var frames:Array<Int>;
	public var frameTime:Int;

	public function new(name:String, frames:Array<Int>, frameTime:Int = 100) {
		this.name = name;
		this.frames = frames;
		this.frameTime = frameTime;
	}
}
