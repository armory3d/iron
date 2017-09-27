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
	var animtime = 0.0;
	var time = 0.0;
	var spawnRate = 0.0;
	var seed = 0.0;

	var r:TParticleData;
	var gx:Float;
	var gy:Float;
	var gz:Float;
	var alignx:Float;
	var aligny:Float;
	var alignz:Float;

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
			alignx = r.object_align_factor[0] / 2;
			aligny = r.object_align_factor[1] / 2;
			alignz = r.object_align_factor[2] / 2;
			lifetime = r.lifetime / frameRate;
			animtime = (r.frame_end - r.frame_start) / frameRate;
			spawnRate = ((r.frame_end - r.frame_start) / r.count) / frameRate;
			for (i in 0...r.count) particles.push(new Particle(i));
			ready = true;
		});
	}

	// GPU particles
	var m = iron.math.Mat4.identity();
	public function getData():iron.math.Mat4 {
		m._00 = count;
		m._01 = spawnRate;
		m._02 = lifetime;
		m._03 = particles.length;
		m._10 = alignx;
		m._11 = aligny;
		m._12 = alignz;
		m._13 = r.factor_random;
		m._20 = gx;
		m._21 = gy;
		m._22 = gz;
		m._23 = r.lifetime_random;
		return m;
	}

	// CPU particles
	public function update(object:MeshObject, owner:MeshObject) {
		if (!ready) return;

		#if arm_cpu_particles
		updateCpu(object, owner);
		#else
		updateGpu(object, owner);
		#end
	}

	var count = 0;
	function updateGpu(object:MeshObject, owner:MeshObject) {
		if (!object.data.geom.instanced) setupGeomGpu(object, owner);

		// Animate
		time += Time.delta;
		var l = particles.length;
		var lap = Std.int(time / animtime);
		var lapTime = time - lap * animtime;
		count = Std.int(lapTime / spawnRate);
	}

	function setupGeomGpu(object:MeshObject, owner:MeshObject) {
		var instancedData = new TFloat32Array(particles.length * 4);
		var i = 0;
		var pa = owner.data.geom.positions;
		for (p in particles) {
			var j = Std.int(fhash(i) * (pa.length / 3));
			instancedData.set(i, pa[j * 3 + 0]); i++;
			instancedData.set(i, pa[j * 3 + 1]); i++;
			instancedData.set(i, pa[j * 3 + 2]); i++;
			instancedData.set(i, p.i); i++;
		}
		object.data.geom.setupInstanced(instancedData, Usage.DynamicUsage, true);
	}

	function updateCpu(object:MeshObject, owner:MeshObject) {
		// Make mesh data instanced
		if (!object.data.geom.instanced) setupGeomCpu(object, owner);

		// object.transform.scale.x = r.particle_size;
		// object.transform.scale.y = r.particle_size;
		// object.transform.scale.z = r.particle_size;
		// object.transform.dirty = true;

		// Animate
		time += Time.delta;
		var l = particles.length;
		var lap = Std.int(time / animtime);
		var lapTime = time - lap * animtime;
		count = Std.int(lapTime / spawnRate);

		for (p in particles) computePos(p, object, l, lap, count);

		// Upload
		// sort(); // TODO: breaks particle order
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

	function computePos(p:Particle, object:MeshObject, l:Int, lap:Int, count:Int) {

		var i = p.i;// + lap * l * l; // Shuffle repeated laps
		var ptime = (count - p.i) * spawnRate;
		ptime -= ptime * fhash(i) * r.lifetime_random;

		if (p.i > count || ptime < 0 || ptime > lifetime) { p.x = p.y = p.z = -99999; return; } // Limit to current particle count

		if (r.physics_type == 1) computeNewton(p, i, ptime);

		if (r.emit_from == 1) { // Volume
			p.x += (fhash(i + 0 * l) * 2.0 - 1.0) * (object.transform.size.x / 2.0);
			p.y += (fhash(i + 1 * l) * 2.0 - 1.0) * (object.transform.size.y / 2.0);
			p.z += (fhash(i + 2 * l) * 2.0 - 1.0) * (object.transform.size.z / 2.0);
		}
	}

	function computeNewton(p:Particle, i:Int, ptime:Float) {

		p.x = alignx;
		p.y = aligny;
		p.z = alignz;

		var l = particles.length;
		p.x += fhash(p.i + 0 * l) * r.factor_random - r.factor_random / 2;
		p.y += fhash(p.i + 1 * l) * r.factor_random - r.factor_random / 2;
		p.z += fhash(p.i + 2 * l) * r.factor_random - r.factor_random / 2;

		// Gravity
		p.x += (gx * ptime) / 5;
		p.y += (gy * ptime) / 5;
		p.z += (gz * ptime) / 5;

		p.x *= ptime;
		p.y *= ptime;
		p.z *= ptime;
	}

	function setupGeomCpu(object:MeshObject, owner:MeshObject) {
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
				var j = Std.int(fhash(i) * (pa.length / 3));
				emitFrom.set(i, pa[j * 3 + 0]); i++;
				emitFrom.set(i, pa[j * 3 + 1]); i++;
				emitFrom.set(i, pa[j * 3 + 2]); i++;
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

	function fhash(n:Int):Float {
		// var f = Math.sin(n) * 43758.5453;
		// return f - Std.int(f);
		var s = n + 1.0;
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
