package lue;

class App extends kha.Game {

	public static var w:Int;
    public static var h:Int;

    var room:String;
    var game:Class<Dynamic>;

    static var traitInits:Array<Void->Void> = [];
    static var traitUpdates:Array<Void->Void> = [];
    static var traitRenders:Array<kha.graphics4.Graphics->Void> = [];
    static var traitRenders2D:Array<kha.graphics2.Graphics->Void> = [];

	public function new(room:String, game:Class<Dynamic>) {
		super("Game");

        this.room = room;
        this.game = game;
	}

    override public function init() {
        kha.Configuration.setScreen(new kha.LoadingScreen());

        w = width;
        h = height;
        
        kha.Loader.the.loadRoom(room, loadingFinished);
    }

    function loadingFinished() {
        new Eg();
        new Ut();
        new lue.sys.Storage();
        new lue.sys.Time();
        new lue.sys.Input();

        kha.Configuration.setScreen(this);
        Type.createInstance(game, []);
    }

    public static function reset() {
        traitInits = [];
        traitUpdates = [];
        traitRenders = [];
        traitRenders2D = [];

        Eg.reset();

        lue.sys.Input.reset();
        lue.sys.Tween.reset();
    }

    override function update() {
        lue.sys.Time.update();
        lue.sys.Tween.update();
        
        if (traitInits.length > 0) {
            for (f in traitInits) { if (traitInits.length == 0) break; f(); f = null; }
            traitInits.splice(0, traitInits.length);     
        }

        for (f in traitUpdates) { if (traitUpdates.length == 0) break; f(); }

        lue.sys.Input.end();
    }

    override function render(frame:kha.Framebuffer) {
        if (traitInits.length > 0) { // TODO: make sure update is called before render
            for (f in traitInits) { if (traitInits.length == 0) break; f(); f = null; }
            traitInits.splice(0, traitInits.length);     
        }

        for (f in traitRenders) { if (traitRenders.length == 0) break; f(frame.g4); }


        frame.g2.begin(false);

        // Shadow map test
        //frame.g2.drawImage(lue.resource.Resource.getPipeline("blender_resource", "blender_pipeline").renderTargets.get("shadowmap"), 0, 0);
        
        for (f in traitRenders2D) { if (traitRenders2D.length == 0) break; f(frame.g2); }

        frame.g2.end();
    }

    // Hooks
    public static function requestInit(f:Void->Void) {
        traitInits.push(f);
    }

    public static function removeInit(f:Void->Void) {
        traitInits.remove(f);
    }

    public static function requestUpdate(f:Void->Void) {
        traitUpdates.push(f);
    }

    public static function removeUpdate(f:Void->Void) {
        traitUpdates.remove(f);
    }

    public static function requestRender(f:kha.graphics4.Graphics->Void) {
        traitRenders.push(f);
    }

    public static function removeRender(f:kha.graphics4.Graphics->Void) {
        traitRenders.remove(f);
    }

    public static function requestRender2D(f:kha.graphics2.Graphics->Void) {
        traitRenders2D.push(f);
    }

    public static function removeRender2D(f:kha.graphics2.Graphics->Void) {
        traitRenders2D.remove(f);
    }
}
