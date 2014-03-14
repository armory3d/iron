package wings.w2d.particles;

class Particle {
    // Where the emitter was when the particle was spawned
    public var emitX:Float = 0;
    public var emitY:Float = 0;

    public var x:Float = 0;
    public var velX:Float = 0;

    public var y:Float = 0;
    public var velY:Float = 0;

    public var radialRadius:Float = 0;
    public var velRadialRadius:Float = 0;

    public var radialRotation:Float = 0;
    public var velRadialRotation:Float = 0;

    public var radialAccel:Float = 0;
    public var tangentialAccel:Float = 0;

    public var scale:Float = 0;
    public var velScale:Float = 0;

    public var rotation:Float = 0;
    public var velRotation:Float = 0;

    public var alpha:Float = 0;
    public var velAlpha:Float = 0;

    public var life:Float = 0;

    public function new () {}
}
