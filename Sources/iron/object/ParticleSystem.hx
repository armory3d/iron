package iron.object;

import kha.graphics4.Usage;
import iron.data.Data;
import iron.data.ParticleData;
import iron.data.SceneFormat;
import iron.system.Time;
import iron.math.Vec4;

class ParticleSystem {
	public var data:ParticleData;
	var particles:Array<Particle>;
	var ready:Bool;
	var frameRate = 60;
	var lifetime = 0.0;

	public function new(sceneName:String, pref:TParticleReference) {
		seed = pref.seed;
		particles = [];

		ready = false;
		Data.getParticle(sceneName, pref.particle, function(b:ParticleData) {
			data = b;
			var r = data.raw;
			lifetime = r.lifetime / frameRate;
			for (i in 0...r.count) {
				var p = new Particle();
				particles.push(p);
				p.lifetime = 0.0;
				p.offset = new Vec4(0.0, 0.0, 0.0);
				p.velocity = new Vec4(0.0, 0.0, 0.0);
				setVelocity(p.velocity);
			}
			ready = true;
		});
	}

	public function update(object:MeshObject) {
		if (!ready) return;

		// Make mesh data instanced
		if (!object.data.geom.instanced) {

			var instancedData = new TFloat32Array(particles.length * 3);
			var i = 0;
			for (p in particles) {
				instancedData.set(i, p.offset.x);
				i++;
				instancedData.set(i, p.offset.y);
				i++;
				instancedData.set(i, p.offset.z);
				i++;
			}
			object.data.geom.setupInstanced(instancedData, Usage.DynamicUsage);
		}

		for (p in particles) {
			p.lifetime += Time.delta;

			if (p.lifetime > lifetime) {
				p.lifetime = 0;
				setVelocity(p.velocity);
			}

			//p.velocity.x -= scene.active.raw.gravity[0] / 10
			//p.velocity.y -= scene.active.raw.gravity[1] / 10
			//p.velocity.z -= scene.active.raw.gravity[2] / 10

			p.offset.x = p.lifetime * p.velocity.x;
			p.offset.y = p.lifetime * p.velocity.y;
			p.offset.z = p.lifetime * p.velocity.z;
		}
		sort();
		var instancedData = object.data.geom.instancedVB.lock();
		for (i in 0...particles.length) {
			var p = particles[i];
			instancedData.set(i * 3 + 0, p.offset.x);
			instancedData.set(i * 3 + 1, p.offset.y);
			instancedData.set(i * 3 + 2, p.offset.z);
		}
		object.data.geom.instancedVB.unlock();
	}

	function setVelocity(v:Vec4) {
		var r = data.raw;
		v.set(r.object_align_factor[0],
			  r.object_align_factor[1],
			  r.object_align_factor[2]
		);
		if (r.factor_random != 0) {
			v.x += Std.random(Std.int(r.factor_random * 1000)) / 1000 - r.factor_random / 2;
			v.y += Std.random(Std.int(r.factor_random * 1000)) / 1000 - r.factor_random / 2;
			v.z += Std.random(Std.int(r.factor_random * 1000)) / 1000 - r.factor_random / 2;
		}
	}

	function sort() {
		var camera = iron.Scene.active.camera;

		for (p in particles) { // TODO: check particle systems located at non-origin location
			p.cameraDistance = Vec4.distance3d(p.offset, camera.transform.loc);
		}

		particles.sort(function(p1:Particle, p2:Particle):Int {
		    if (p1.cameraDistance > p2.cameraDistance) return -1;
		    if (p1.cameraDistance < p2.cameraDistance) return 1;
		    return 0;
		});
	}

	static var seed = 1; // cpp / js not consistent
	static function seededRandom():Float {
		seed = (seed * 9301 + 49297) % 233280;
		return seed / 233280.0;
	}

	public function remove() {
		
	}
}

class Particle {
	public var offset:Vec4;
	public var velocity:Vec4;
	public var lifetime:Float;
	public var cameraDistance:Float;
	public function new() {}
}
