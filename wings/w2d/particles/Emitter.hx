package wings.w2d.particles;

// Flambe Emitter ported to Wings
// https://github.com/aduros/flambe/tree/master/src/flambe/display

import kha.Color;
import kha.Rotation;
import kha.Painter;
import kha.Image;
import wings.wxd.Time;
import wings.w2d.Object2D;
import wings.w2d.particles.EmitterMold;

class Emitter extends Object2D {

	var texture:Image;

    // Time passed since the last emission
    var emitElapsed:Float = 0;

    var totalElapsed:Float = 0;

	// The particle pool
	var particles:Array<Particle>;

	/** The current number of particles being shown. */
    public var numParticles(default, null):Int = 0;

    public var maxParticles(get, set):Int;

    public var type:EmitterType;

    /** How long the emitter should remain enabled, or <= 0 to never expire. */
    public var duration:Float;

    /** Whether new particles are being actively emitted. */
    public var enabled:Bool = true;

    //public var emitX (default, null) :Float;
    public var emitXVariance(default, null):Float;

    //public var emitY (default, null) :Float;
    public var emitYVariance(default, null):Float;

    public var alphaStart(default, null):Float;
    public var alphaStartVariance(default, null):Float;

    public var alphaEnd(default, null):Float;
    public var alphaEndVariance(default, null):Float;

    public var angle(default, null):Float;
    public var angleVariance(default, null):Float;

    public var gravityX(default, null):Float;
    public var gravityY(default, null):Float;

    public var maxRadius(default, null):Float;
    public var maxRadiusVariance(default, null):Float;

    public var minRadius(default, null):Float;

    public var lifespanVariance(default, null):Float;
    public var lifespan(default, null):Float;

    public var rotatePerSecond(default, null):Float;
    public var rotatePerSecondVariance(default, null):Float;

    public var rotationStart(default, null):Float;
    public var rotationStartVariance(default, null):Float;

    public var rotationEnd(default, null):Float;
    public var rotationEndVariance(default, null):Float;

    public var sizeStart(default, null):Float;
    public var sizeStartVariance(default, null):Float;

    public var sizeEnd(default, null):Float;
    public var sizeEndVariance(default, null):Float;

    public var speed(default, null):Float;
    public var speedVariance(default, null):Float;

    public var radialAccel(default, null):Float;
    public var radialAccelVariance(default, null):Float;

    public var tangentialAccel(default, null):Float;
    public var tangentialAccelVariance(default, null):Float;

	public function new(mold:EmitterMold, x:Float = 0, y:Float = 0) {
		super();

		this.x = x;
		this.y = y;

		texture = mold.texture;
        //blendMode = mold.blendMode;
        type = mold.type;

        alphaEnd = mold.alphaEnd;
        alphaEndVariance = mold.alphaEndVariance;
        alphaStart = mold.alphaStart;
        alphaStartVariance = mold.alphaStartVariance;
        angle = mold.angle;
        angleVariance = mold.angleVariance;
        duration = mold.duration;
        emitXVariance = mold.emitXVariance;
        emitYVariance = mold.emitYVariance;
        gravityX = mold.gravityX;
        gravityY = mold.gravityY;
        maxRadius = mold.maxRadius;
        maxRadiusVariance = mold.maxRadiusVariance;
        minRadius = mold.minRadius;
        lifespan = mold.lifespan;
        lifespanVariance = mold.lifespanVariance;
        radialAccel = mold.radialAccel;
        radialAccelVariance = mold.radialAccelVariance;
        rotatePerSecond = mold.rotatePerSecond;
        rotatePerSecondVariance = mold.rotatePerSecondVariance;
        rotationEnd = mold.rotationEnd;
        rotationEndVariance = mold.rotationEndVariance;
        rotationStart = mold.rotationStart;
        rotationStartVariance = mold.rotationStartVariance;
        sizeEnd = mold.sizeEnd;
        sizeEndVariance = mold.sizeEndVariance;
        sizeStart = mold.sizeStart;
        sizeStartVariance = mold.sizeStartVariance;
        speed = mold.speed;
        speedVariance = mold.speedVariance;
        tangentialAccel = mold.tangentialAccel;
        tangentialAccelVariance = mold.tangentialAccelVariance;

        //emitX = 0;
        //emitY = 0;

        particles = new Array();
        var ii = 0, ll = mold.maxParticles;
        while (ii < ll) {
        	particles.push(new Particle());
            ++ii;
        }
	}

	public function restart() {
        enabled = true;
        totalElapsed = 0;
    }

	public override function update() {
		super.update();

		// Update existing particles
		var dt = Time.delta / 1000;
        var gravityType = (type == Gravity);
        var ii = 0;
        while (ii < numParticles) {
            var particle = particles[ii];
            if (particle.life > dt) {
                if (gravityType) {
                    particle.x += particle.velX * dt;
                    particle.y += particle.velY * dt;

                    var accelX = gravityX;
                    var accelY = -gravityY;

                    if (particle.radialAccel != 0 || particle.tangentialAccel != 0) {
                        var dx = particle.x - particle.emitX;
                        var dy = particle.y - particle.emitY;
                        var distance = Math.sqrt(dx*dx + dy*dy);

                        // Apply radial force
                        var radialX = dx / distance;
                        var radialY = dy / distance;
                        accelX += radialX * particle.radialAccel;
                        accelY += radialY * particle.radialAccel;

                        // Apply tangential force
                        var tangentialX = -radialY;
                        var tangentialY = radialX;
                        accelX += tangentialX * particle.tangentialAccel;
                        accelY += tangentialY * particle.tangentialAccel;
                    }

                    particle.velX += accelX * dt;
                    particle.velY += accelY * dt;

                }
                else {
                    particle.radialRotation += particle.velRadialRotation * dt;
                    particle.radialRadius += particle.velRadialRadius * dt;

                    var radius = particle.radialRadius;
                    particle.x = _x /*emitX*/ - Math.cos(particle.radialRotation) * radius;
                    particle.y = _y /*emitY*/ - Math.sin(particle.radialRotation) * radius;

                    if (radius < minRadius) {
                        particle.life = 0; // Kill it
                    }
                }

                particle.scale += particle.velScale * dt;
                particle.rotation += particle.velRotation * dt;
                particle.alpha += particle.velAlpha * dt;

                particle.life -= dt;
                ++ii;

            }
            else {
                // Kill it, and swap it with the last living particle, so that alive particles are
                // packed to the front of the pool
                --numParticles;
                if (ii != numParticles) {
                    particles[ii] = particles[numParticles];
                    particles[numParticles] = particle;
                }
            }
        }

        // Check whether we should continue to the emit step
        if (!enabled) {
            return;
        }
        if (duration > 0) {
            totalElapsed += dt;
            if (totalElapsed >= duration) {
                enabled = false;
                return;
            }
        }

        // Emit new particles
        var emitDelay = lifespan / particles.length;
        emitElapsed += dt;
        while (emitElapsed >= emitDelay) {
            if (numParticles < particles.length) {
                var particle = particles[numParticles];
                if (initParticle(particle)) {
                    ++numParticles;
                }
            }
            emitElapsed -= emitDelay;
        }
	}

	function initParticle(particle:Particle):Bool {

        particle.life = random(lifespan, lifespanVariance);
        if (particle.life <= 0) {
            return false; // Dead on arrival
        }

        // Don't include the variance here
        particle.emitX = _x;//emitX;
        particle.emitY = _y;//emitY;

        var angle = wings.math.Math.degToRad(random(angle, angleVariance));
        var speed = random(speed, speedVariance);
        particle.velX = speed * Math.cos(angle);
        particle.velY = speed * Math.sin(angle);

        particle.radialAccel = random(radialAccel, radialAccelVariance);
        particle.tangentialAccel = random(tangentialAccel, tangentialAccelVariance);

        particle.radialRadius = random(maxRadius, maxRadiusVariance);
        particle.velRadialRadius = -particle.radialRadius / particle.life;
        particle.radialRotation = angle;
        particle.velRadialRotation = wings.math.Math.degToRad(random(rotatePerSecond, rotatePerSecondVariance));

        if (type == Gravity) {
            particle.x = random(_x /*emitX*/, emitXVariance);
            particle.y = random(_y /*emitY*/, emitYVariance);

        } else { // type == Radial
            var radius = particle.radialRadius;
            particle.x = _x /*emitX*/ - Math.cos(particle.radialRotation) * radius;
            particle.y = _y /*emitY*/ - Math.sin(particle.radialRotation) * radius;
        }

        // Assumes that the texture is always square
        var width = texture.width;
        var scaleStart = random(sizeStart, sizeStartVariance) / width;
        var scaleEnd = random(sizeEnd, sizeEndVariance) / width;
        particle.scale = scaleStart;
        particle.velScale = (scaleEnd - scaleStart) / particle.life;

        var rotationStart = random(rotationStart, rotationStartVariance);
        var rotationEnd = random(rotationEnd, rotationEndVariance);
        particle.rotation = rotationStart;
        particle.velRotation = (rotationEnd-rotationStart) / particle.life;

        var alphaStart = random(alphaStart, alphaStartVariance);
        var alphaEnd = random(alphaEnd, alphaEndVariance);
        particle.alpha = alphaStart;
        particle.velAlpha = (alphaEnd-alphaStart) / particle.life;

        return true;
    }

    inline function get_maxParticles():Int {
        return particles.length;
    }

    function set_maxParticles(maxParticles:Int):Int {

        // Grow the pool
        var oldLength = particles.length;
        resize(particles, maxParticles);
        while (oldLength < maxParticles) {
            particles[oldLength] = new Particle();
            ++oldLength;
        }

        if (numParticles > maxParticles) {
            numParticles = maxParticles;
        }

        return maxParticles;
    }

    /** Resizes an array in-place. */
    function resize(arr:Array<Particle>, length:Int) {
		#if (flash || js)
	        // This trick only works in Flash and JS
	        (untyped arr).length = length;
		#else
	        #error "Arrays.resize unimplemented on this target"
		#end
	}

	static function random(base:Float, variance:Float) {

        if (variance != 0) {
            base += variance * (2 * Math.random() - 1);
        }

        return base;
    }

	public override function render(painter:Painter) {
		super.render(painter);

		// Assumes that the texture is always square
        //var offset = -texture.width / 2;

        var ii = 0, ll = numParticles;
        while (ii < ll) {
            var particle = particles[ii];

            var offset = -(texture.width * particle.scale) / 2;
            var destX = offset + particle.x;
            var destY = offset + particle.y;
            
            painter.opacity = particle.alpha;
            painter.drawImage2(texture, 0, 0, texture.width, texture.height,
            				   destX, destY,
            				   texture.width * particle.scale,
            				   texture.height * particle.scale,
            				   new Rotation(new kha.math.Vector2(destX, destY),
            				   				particle.rotation));

            ++ii;
        }
	}
}
