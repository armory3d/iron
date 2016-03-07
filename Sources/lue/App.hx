package lue;

class App {

	public static var w:Int;
    public static var h:Int;

    var game:Class<Dynamic>;

    static var traitInits:Array<Void->Void> = [];
    static var traitUpdates:Array<Void->Void> = [];
    static var traitRenders:Array<kha.graphics4.Graphics->Void> = [];
    static var traitRenders2D:Array<kha.graphics2.Graphics->Void> = [];

	public function new(game:Class<Dynamic>) {
        this.game = game;

        w = kha.System.windowWidth(); // TODO: do not cache
        h = kha.System.windowHeight();

        kha.Assets.loadEverything(loadingFinished);
	}

    function loadingFinished() {

        new Eg();
        new Ut();
        new lue.sys.Storage();
        new lue.sys.Time();
        new lue.sys.Input();

        Type.createInstance(game, []);

        kha.System.notifyOnRender(render);
        kha.Scheduler.addTimeTask(update, 0, 1 / 60);
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

    function update() {
        lue.sys.Time.update();
        lue.sys.Tween.update();
        
        if (traitInits.length > 0) {
            for (f in traitInits) { if (traitInits.length == 0) break; f(); f = null; }
            traitInits.splice(0, traitInits.length);     
        }

        for (f in traitUpdates) { if (traitUpdates.length == 0) break; f(); }

        lue.sys.Input.end();
    }

    function render(frame:kha.Framebuffer) {
        if (traitInits.length > 0) { // TODO: make sure update is called before render
            for (f in traitInits) { if (traitInits.length == 0) break; f(); f = null; }
            traitInits.splice(0, traitInits.length);     
        }

        for (f in traitRenders) { if (traitRenders.length == 0) break; f(frame.g4); }


        frame.g2.begin(false);

        // Shadow map test
        // var rt = lue.resource.Resource.getPipeline("forward_pipeline", "forward_pipeline").renderTargets.get("shadowMap");
        // frame.g2.drawScaledImage(rt.image, 0, 0, 256, 256);
        
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
