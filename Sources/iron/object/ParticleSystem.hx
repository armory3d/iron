package iron.object;

import kha.graphics4.Usage;
import iron.data.Data;
import iron.data.ParticleData;
import iron.data.SceneFormat;
import iron.system.Time;
import iron.math.Vec4;
import iron.math.Mat4;

class ParticleSystem {
	public var data:ParticleData;
	var particles:Array<Particle>;
	var ready:Bool;
	var frameRate = 24;
	var lifetime = 0.0;
	var time = 0.0;
	var spawnRate = 0.0;
	var seed = 0.0;

	var r:TParticleData;
	var gx:Float;
	var gy:Float;
	var gz:Float;

	var emitFrom:TFloat32Array = null;

	public function new(sceneName:String, pref:TParticleReference) {
		seed = pref.seed;
		particles = [];
		ready = false;
		Data.getParticle(sceneName, pref.particle, function(b:ParticleData) {
			data = b;
			r = data.raw;
			gx = iron.Scene.active.raw.gravity[0];
			gy = iron.Scene.active.raw.gravity[1];
			gz = iron.Scene.active.raw.gravity[2];
			lifetime = r.lifetime / frameRate;
			spawnRate = ((r.frame_end - r.frame_start) / r.count) / frameRate;
			for (i in 0...r.count) particles.push(new Particle(i));
			ready = true;
		});
	}

	// GPU particles
	var m = iron.math.Mat4.identity();
	public function getData():iron.math.Mat4 {
		return m;
	}

	// CPU particles
	public function update(object:MeshObject, owner:MeshObject) {
		if (!ready) return;

		// Make mesh data instanced
		if (!object.data.geom.instanced) setupGeom(object, owner);

		// Animate
		time += Time.delta;
		for (p in particles) computePos(p, object);

		// Upload
		sort();
		var instancedData = object.data.geom.instancedVB.lock();
		for (i in 0...particles.length) {
			var p = particles[i];
			var px = p.x;
			var py = p.y;
			var pz = p.z;
			if (r.emit_from == 0) { // Vert, face
				px += emitFrom[i * 3 + 0];
				py += emitFrom[i * 3 + 1];
				pz += emitFrom[i * 3 + 2];
			}
			instancedData.set(i * 3 + 0, px);
			instancedData.set(i * 3 + 1, py);
			instancedData.set(i * 3 + 2, pz);
		}
		object.data.geom.instancedVB.unlock();
	}

	function computePos(p:Particle, object:MeshObject) {
		var l = particles.length;
		var lap = Std.int(time / lifetime);
		var lapTime = time - lifetime * lap;
		var count = Std.int(lapTime / spawnRate);
		var i = Std.int(Math.min(p.i, count)); // Limit to current particle count
		i += lap * l * l; // Shuffle repeated laps

		var plife = time - lap * lifetime;
		plife -= plife * seeded(i) * r.lifetime_random;

		if (r.physics_type == 1) computeNewton(p, i, plife);

		if (r.emit_from == 1) { // Volume
			p.x += (seeded(i + 0 * l) * 2.0 - 1.0) * (object.transform.size.x / 2.0);
			p.y += (seeded(i + 1 * l) * 2.0 - 1.0) * (object.transform.size.y / 2.0);
			p.z += (seeded(i + 2 * l) * 2.0 - 1.0) * (object.transform.size.z / 2.0);
		}
	}

	function computeNewton(p:Particle, i:Int, plife:Float) {

		var vx = r.object_align_factor[0];
		var vy = r.object_align_factor[1];
		var vz = r.object_align_factor[2];

		var l = particles.length;
		vx += (seeded(p.i + 0 * l) * Std.int(r.factor_random * 1000)) / 1000 - r.factor_random / 2;
		vy += (seeded(p.i + 1 * l) * Std.int(r.factor_random * 1000)) / 1000 - r.factor_random / 2;
		vz += (seeded(p.i + 2 * l) * Std.int(r.factor_random * 1000)) / 1000 - r.factor_random / 2;

		vx += gx / 10;
		vy += gy / 10;
		vz += gz / 10;

		p.x = plife * vx;
		p.y = plife * vy;
		p.z = plife * vz;
	}

	function setupGeom(object:MeshObject, owner:MeshObject) {
		var instancedData = new TFloat32Array(particles.length * 3);
		var i = 0;
		for (p in particles) {
			instancedData.set(i, 0.0); i++;
			instancedData.set(i, 0.0); i++;
			instancedData.set(i, 0.0); i++;
		}
		object.data.geom.setupInstanced(instancedData, Usage.DynamicUsage);
		
		if (r.emit_from == 0) { // Vert, Face
			emitFrom = new TFloat32Array(particles.length * 3);
			i = 0;
			var pa = owner.data.geom.positions;
			for (p in particles) {
				var r = Std.int(seeded(i) * (pa.length / 3));
				emitFrom.set(i, pa[r * 3 + 0]); i++;
				emitFrom.set(i, pa[r * 3 + 1]); i++;
				emitFrom.set(i, pa[r * 3 + 2]); i++;
			}
		}
	}

	function sort() {
		var camera = iron.Scene.active.camera;
		var l = camera.transform.loc;

		for (p in particles) { // TODO: check particle systems located at non-origin location
			p.cameraDistance = Vec4.distance3df(p.x, p.y, p.z, l.x, l.y, l.z);
		}

		particles.sort(function(p1:Particle, p2:Particle):Int {
		    if (p1.cameraDistance > p2.cameraDistance) return -1;
		    if (p1.cameraDistance < p2.cameraDistance) return 1;
		    return 0;
		});
	}

	function seeded(i:Int):Float {
		var s = i + 1.0;
        s *= 9301.0 % s;
		s = (s * 9301.0 + 49297.0) % 233280.0;
		return s / 233280.0;
	}

	public function remove() {
		
	}
}

class Particle {
	public var i:Int;
	public var x = 0.0;
	public var y = 0.0;
	public var z = 0.0;
	public var cameraDistance:Float;
	public function new(i:Int) { this.i = i; }
}
