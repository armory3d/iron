package lue.node;

class Animation {

	public var animTime:Float = 0;
	public var timeIndex:Int = 0; // TODO: use boneTimeIndices
	public var dirty:Bool = false;

	public var current:Track;
	var tracks:Map<String, Track> = new Map();

	public var speed:Float = 1.0;
	public var loop:Bool;
	public var onTrackComplete:Void->Void = null;

	public var paused = false;

    public function new(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>) {

        for (i in 0...names.length) {
        	addTrack(names[i], starts[i], ends[i]);
        }

        play(startTrack);
    }

    public function play(name:String, loop = true, speed = 1.0, onTrackComplete:Void->Void = null) {
 		current = tracks.get(name);
 		dirty = true;

 		this.speed = speed;
 		this.loop = loop;
 		this.onTrackComplete = onTrackComplete;

 		paused = false;
    }

    public function pause() {
    	paused = true;
    }

    function addTrack(name:String, start:Int, end:Int) {
    	var t = new Track(start, end);
    	tracks.set(name, t);
    }
}

class Track {
	public var start:Int;
	public var end:Int;
	public var frames:Int;

	public function new(start:Int, end:Int) {
		this.start = start;
		this.end = end;
		frames = end - start;
	}
}
