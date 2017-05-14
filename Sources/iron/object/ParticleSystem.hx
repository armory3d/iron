package iron.object;

import kha.graphics4.Usage;
import iron.data.Data;
import iron.data.ParticleData;
import iron.data.SceneFormat;
import iron.system.Time;
import iron.math.Vec4;

class ParticleSystem {

	var name:String;
	var data:ParticleData;
	var seed:Int;

	var object:MeshObject;

	var particles:Array<Particle>;

	var ready:Bool;

	public function new(object:MeshObject, sceneName:String, pref:TParticleReference) {
		this.object = object;
		name = pref.name;
		seed = pref.seed;
		particles = [];

		ready = false;
		Data.getParticle(sceneName, pref.particle, function(b:ParticleData) {
			data = b;

			var r = data.raw;
			for (i in 0...r.count) {
				var p = new Particle();
				particles.push(p);
				p.offset = new Vec4(0.0, 0.0, 0.0);
				p.velocity = new Vec4(0.0, 0.0, 0.0);
				setVelocity(p.velocity);
				p.lifetime = Std.random(Std.int(r.lifetime * 1000)) / 1000;
			}

			// Make mesh data instanced
			var instancedData:Array<Float> = []; // TODO: use Float32Array directly
			for (p in particles) {
				instancedData.push(p.offset.x);
				instancedData.push(p.offset.y);
				instancedData.push(p.offset.z);
			}
			object.data.geom.setupInstanced(instancedData, Usage.DynamicUsage);

			ready = true;
		});
	}

	public function update() {
		if (!ready) return;

		for (p in particles) { // TODO: Sort Float32Array directly
			p.lifetime += Time.delta;

			if (p.lifetime > data.raw.lifetime) {
				p.lifetime = 0;
				setVelocity(p.velocity);
			}

			// TODO: specify gravity
			//p.velocity.z -= 9.81 / 10 * Time.delta;

			p.offset.x = p.lifetime * p.velocity.x;
			p.offset.y = p.lifetime * p.velocity.y;
			p.offset.z = p.lifetime * p.velocity.z;
		}
		sort();
		var vb = object.data.geom.instancedVertexBuffers[1];
		var instancedData = vb.lock();
		for (i in 0...particles.length) {
			var p = particles[i];
			instancedData.set(i * 3 + 0, p.offset.x);
			instancedData.set(i * 3 + 1, p.offset.y);
			instancedData.set(i * 3 + 2, p.offset.z);
		}
		vb.unlock();
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
}

class Particle {
	public var offset:Vec4;
	public var velocity:Vec4;
	public var lifetime:Float;
	public var cameraDistance:Float;
	public function new() {}
}
