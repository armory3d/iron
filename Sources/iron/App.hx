package iron;

class App {

	public static inline function w():Int { return kha.System.windowWidth(); }
    public static inline function h():Int { return kha.System.windowHeight(); };

    static var traitInits:Array<Void->Void> = [];
    static var traitUpdates:Array<Void->Void> = [];
    static var traitLateUpdates:Array<Void->Void> = [];
    static var traitRenders:Array<kha.graphics4.Graphics->Void> = [];
    static var traitRenders2D:Array<kha.graphics2.Graphics->Void> = [];

#if arm_profile
    static var startTime:Float;
    public static var updateTime:Float;
    public static var renderTime:Float;
#end

    public static function init(_appReady:Void->Void) {
        new App(_appReady);
    }
    
	function new(_appReady:Void->Void) {
        new iron.system.Storage();
        new iron.system.Input();

        _appReady();

        kha.System.notifyOnRender(render);
        kha.Scheduler.addTimeTask(update, 0, iron.system.Time.delta);
        // kha.Scheduler.addTimeTask(update, 0, 1 / 60);
	}

    public static function reset() {
        traitInits = [];
        traitUpdates = [];
        traitLateUpdates = [];
        traitRenders = [];
        traitRenders2D = [];

        iron.system.Input.reset();
        iron.system.Tween.reset();
    }

    static function update() {
#if arm_profile
        startTime = kha.Scheduler.realTime();
#end

        iron.system.Tween.update();

        if (Scene.active != null) Scene.active.updateFrame();
        
        if (traitInits.length > 0) {
            for (f in traitInits) { if (traitInits.length == 0) break; f(); f = null; }
            traitInits.splice(0, traitInits.length);     
        }

        for (f in traitUpdates) { if (traitUpdates.length == 0) break; f(); }
        for (f in traitLateUpdates) { if (traitLateUpdates.length == 0) break; f(); }

        iron.system.Input.end();

#if arm_profile
        updateTime = kha.Scheduler.realTime() - startTime;
#end
    }

    static function render(frame:kha.Framebuffer) {

#if arm_profile
        startTime = kha.Scheduler.realTime();
#end

        if (traitInits.length > 0) { // TODO: make sure update is called before render
            for (f in traitInits) { if (traitInits.length == 0) break; f(); f = null; }
            traitInits.splice(0, traitInits.length);     
        }

        if (Scene.active != null) Scene.active.renderFrame(frame.g4);

        for (f in traitRenders) { if (traitRenders.length == 0) break; f(frame.g4); }

        frame.g2.begin(false);
		for (f in traitRenders2D) { if (traitRenders2D.length == 0) break; f(frame.g2); }
        frame.g2.end();

#if arm_profile
        renderTime = kha.Scheduler.realTime() - startTime;
#end
    }

    // Hooks
    public static function notifyOnInit(f:Void->Void) {
        traitInits.push(f);
    }

    public static function removeInit(f:Void->Void) {
        traitInits.remove(f);
    }

    public static function notifyOnUpdate(f:Void->Void) {
        traitUpdates.push(f);
    }

    public static function removeUpdate(f:Void->Void) {
        traitUpdates.remove(f);
    }
	
	public static function notifyOnLateUpdate(f:Void->Void) {
        traitLateUpdates.push(f);
    }

    public static function removeLateUpdate(f:Void->Void) {
        traitLateUpdates.remove(f);
    }

    public static function notifyOnRender(f:kha.graphics4.Graphics->Void) {
        traitRenders.push(f);
    }

    public static function removeRender(f:kha.graphics4.Graphics->Void) {
        traitRenders.remove(f);
    }

    public static function notifyOnRender2D(f:kha.graphics2.Graphics->Void) {
        traitRenders2D.push(f);
    }

    public static function removeRender2D(f:kha.graphics2.Graphics->Void) {
        traitRenders2D.remove(f);
    }
}
