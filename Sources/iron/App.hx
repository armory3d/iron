package iron;

class App {

	#if arm_appwh
	public static inline function w():Int { return arm.App.w(); }
	public static inline function h():Int { return arm.App.h(); }
	#else
	public static inline function w():Int { return kha.System.windowWidth(); }
	public static inline function h():Int { return kha.System.windowHeight(); }
	#end

	static var onResets:Array<Void->Void> = null;
	static var onEndFrames:Array<Void->Void> = null;
	static var traitInits:Array<Void->Void> = [];
	static var traitUpdates:Array<{ priority : Int, f : Void->Void }> = [];
	static var traitLateUpdates:Array<{ priority : Int, f : Void->Void }> = [];
	static var traitRenders:Array<kha.graphics4.Graphics->Void> = [];
	static var traitRenders2D:Array<kha.graphics2.Graphics->Void> = [];
	public static var framebuffer:kha.Framebuffer;
	public static var pauseUpdates = false;

	#if arm_debug
	static var startTime:Float;
	public static var updateTime:Float;
	public static var renderPathTime:Float;
	#end
	#if kha_webgl
	static var lastw = -1;
	static var lasth = -1;
	#end
	#if arm_rendertimer
	static var renderTimer = 0.0;
	public static var renderTarget = 1 / 60; // Requested frame time
	#end

	public static function init(_appReady:Void->Void) {
		new App(_appReady);
	}
	
	function new(_appReady:Void->Void) {
		_appReady();

		kha.System.notifyOnFrames(render);
		kha.Scheduler.addTimeTask(update, 0, iron.system.Time.delta);
	}

	public static function reset() {
		traitInits = [];
		traitUpdates = [];
		traitLateUpdates = [];
		traitRenders = [];
		traitRenders2D = [];
		if (onResets != null) for (f in onResets) f();
	}

	static function update() {
		if (Scene.active == null || !Scene.active.ready) return;
		if (pauseUpdates) return;
		
		#if arm_debug
		startTime = kha.Scheduler.realTime();
		#end

		iron.system.Time.update();
		Scene.active.updateFrame();

		var i = 0;
		var l = traitUpdates.length;
		while (i < l) {
			if (traitInits.length > 0) {
				for (f in traitInits) { traitInits.length > 0 ? f() : break; }
				traitInits.splice(0, traitInits.length);     
			}
			traitUpdates[i].f();
			// Account for removed traits
			l <= traitUpdates.length ? i++ : l = traitUpdates.length;
		}

		i = 0;
		l = traitLateUpdates.length;
		while (i < l) {
			traitLateUpdates[i].f();
			l <= traitLateUpdates.length ? i++ : l = traitLateUpdates.length;
		}

		if (onEndFrames != null) for (f in onEndFrames) f();

		#if arm_debug
		iron.object.Animation.endFrame();
		updateTime = kha.Scheduler.realTime() - startTime;
		#end

		#if kha_webgl
		// Rebuild projection on canvas size change
		if (lastw == -1) { lastw = App.w(); lasth = App.h(); }
		if (lastw != App.w() || lasth != App.h()) {
			if (iron.Scene.active != null && iron.Scene.active.camera != null) {
				iron.Scene.active.camera.buildProjection();
			}
		}
		lastw = App.w();
		lasth = App.h();
		#end
	}

	static function render(frames:Array<kha.Framebuffer>) {
		var frame = frames[0];
		framebuffer = frame;

		#if arm_rendertimer
		renderTimer -= iron.system.Time.realDelta;
		if (renderTimer > renderTarget) return;
		renderTimer += renderTarget;
		#end

		if (Scene.active == null || !Scene.active.ready) {
			render2D(frame);
			return;
		}

		#if arm_debug
		startTime = kha.Scheduler.realTime();
		#end

		if (traitInits.length > 0) {
			for (f in traitInits) { traitInits.length > 0 ? f() : break; }
			traitInits.splice(0, traitInits.length);     
		}

		Scene.active.renderFrame(frame.g4);

		for (f in traitRenders) { traitRenders.length > 0 ? f(frame.g4) : break; }

		render2D(frame);

		#if arm_debug
		renderPathTime = kha.Scheduler.realTime() - startTime;
		#end
	}

	static function render2D(frame:kha.Framebuffer) {
		if (traitRenders2D.length > 0) {
			frame.g2.begin(false);
			for (f in traitRenders2D) { traitRenders2D.length > 0 ? f(frame.g2) : break; }
			frame.g2.end();
		}
	}

	// Hooks
	public static function notifyOnInit(f:Void->Void) {
		traitInits.push(f);
	}

	public static function removeInit(f:Void->Void) {
		traitInits.remove(f);
	}

	public static function notifyOnUpdate(f:Void->Void, updatePriority = 100) {
		traitUpdates.push({priority:updatePriority, f:f});
		traitUpdates.sort(function(a, b):Int {
		  if (a.priority < b.priority) return -1;
		  else if (a.priority > b.priority) return 1;
		  return 0;
		});		
	}

	public static function removeUpdate(f:Void->Void, updatePriority = 100) {
		traitUpdates.remove({priority:updatePriority, f:f});
	}
	
	public static function notifyOnLateUpdate(f:Void->Void, updatePriority = 100) {
		traitLateUpdates.push({priority:updatePriority, f:f});
		traitLateUpdates.sort(function(a, b):Int {
		  if (a.priority < b.priority) return -1;
		  else if (a.priority > b.priority) return 1;
		  return 0;
		});
	}

	public static function removeLateUpdate(f:Void->Void, updatePriority = 100) {
		traitLateUpdates.remove({priority:updatePriority, f:f});
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

	public static function notifyOnReset(f:Void->Void) {
		if (onResets == null) onResets = [];
		onResets.push(f);
	}

	public static function removeReset(f:Void->Void) {
		onResets.remove(f);
	}

	public static function notifyOnEndFrame(f:Void->Void) {
		if (onEndFrames == null) onEndFrames = [];
		onEndFrames.push(f);
	}

	public static function removeEndFrame(f:Void->Void) {
		onEndFrames.remove(f);
	}
}
