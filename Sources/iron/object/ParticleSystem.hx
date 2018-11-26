package iron.object;

#if arm_particles

import kha.graphics4.Usage;
import iron.data.Data;
import iron.data.ParticleData;
import iron.data.SceneFormat;
import iron.system.Time;
import iron.math.Vec4;
import iron.math.Mat4;

class ParticleSystem {
	public var data:ParticleData;
	public var speed = 1.0;
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
	var dimx:Float;
	var dimy:Float;
	var tilesx:Int;
	var tilesy:Int;
	var tilesFramerate:Int;

	var count = 0;
	var lap = 0;
	var lapTime = 0.0;
	var m = iron.math.Mat4.identity();

	public function new(sceneName:String, pref:TParticleReference) {
		seed = pref.seed;
		particles = [];
		ready = false;
		Data.getParticle(sceneName, pref.particle, function(b:ParticleData) {
			data = b;
			r = data.raw;
			gx = iron.Scene.active.raw.gravity[0] * r.weight_gravity;
			gy = iron.Scene.active.raw.gravity[1] * r.weight_gravity;
			gz = iron.Scene.active.raw.gravity[2] * r.weight_gravity;
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

	public function disableLifetime()
	{
		lifetime = 0;
	}

	public function enableLifetime()
	{
		lifetime = r.lifetime / frameRate;
	}

	public function update(object:MeshObject, owner:MeshObject) {
		if (!ready || object == null || speed == 0.0) return;

		dimx = object.transform.dim.x;
		dimy = object.transform.dim.y;

		if (object.tilesheet != null) {
			tilesx = object.tilesheet.raw.tilesx;
			tilesy = object.tilesheet.raw.tilesy;
			tilesFramerate = object.tilesheet.raw.framerate;
		}

		// Animate
		time += Time.delta * speed;
		lap = Std.int(time / animtime);
		lapTime = time - lap * animtime;
		count = Std.int(lapTime / spawnRate);

		#if arm_particles_gpu
		updateGpu(object, owner);
		#else
		updateCpu(object, owner);
		#end
	}

	#if arm_particles_gpu
	public function getData():iron.math.Mat4 {
		m._00 = r.loop ? animtime : -animtime;
		m._01 = spawnRate;
		m._02 = lifetime;
		m._03 = particles.length;
		m._10 = alignx;
		m._11 = aligny;
		m._12 = alignz;
		m._13 = r.factor_random;
		m._20 = gx * r.mass;
		m._21 = gy * r.mass;
		m._22 = gz * r.mass;
		m._23 = r.lifetime_random;
		m._30 = tilesx;
		m._31 = tilesy;
		m._32 = 1 / tilesFramerate;
		m._33 = lapTime;
		return m;
	}

	function updateGpu(object:MeshObject, owner:MeshObject) {
		if (!object.data.geom.instanced) setupGeomGpu(object, owner);
		// GPU particles transform is attached to owner object
	}

	function setupGeomGpu(object:MeshObject, owner:MeshObject) {
		var instancedData = new kha.arrays.Float32Array(particles.length * 3);
		var i = 0;
		if (r.emit_from == 0) { // Vert, Face
			var pa = owner.data.geom.positions;
			for (p in particles) {
				var j = Std.int(fhash(i) * (pa.length / 3));
				instancedData.set(i, pa[j * 3 + 0]); i++;
				instancedData.set(i, pa[j * 3 + 1]); i++;
				instancedData.set(i, pa[j * 3 + 2]); i++;
			}
		}
		else { // Volume
			for (p in particles) {
				instancedData.set(i, (Math.random() * 2.0 - 1.0) * (object.transform.dim.x / 2.0)); i++;
				instancedData.set(i, (Math.random() * 2.0 - 1.0) * (object.transform.dim.y / 2.0)); i++;
				instancedData.set(i, (Math.random() * 2.0 - 1.0) * (object.transform.dim.z / 2.0)); i++;
			}
		}
		if (r.particle_size != 1.0) object.data.geom.applyScale(r.particle_size, r.particle_size, r.particle_size);
		object.data.geom.setupInstanced(instancedData, 1, Usage.StaticUsage);
	}

	#else // cpu

	var emitFrom:kha.arrays.Float32Array = null; // Volume/face offset

	function updateCpu(object:MeshObject, owner:MeshObject) {
		// Make mesh data instanced
		if (!object.data.geom.instanced) setupGeomCpu(object, owner);
		if (emitFrom == null) return;

		if (r.type == 0) { // Emitter
			for (p in particles) computePos(p, object, particles.length, lap, count);
		}

		// Upload
		// sort(); // TODO: breaks particle order
		var instancedData = object.data.geom.instancedVB.lock();
		for (i in 0...particles.length) {
			var p = particles[i];
			var px = p.x;
			var py = p.y;
			var pz = p.z;
			px += emitFrom[i * 3 + 0];
			py += emitFrom[i * 3 + 1];
			pz += emitFrom[i * 3 + 2];
			instancedData.set(i * 3 + 0, px);
			instancedData.set(i * 3 + 1, py);
			instancedData.set(i * 3 + 2, pz);
		}
		object.data.geom.instancedVB.unlock();
	}

	function computePos(p:Particle, object:MeshObject, l:Int, lap:Int, count:Int) {

		var i = p.i;// + lap * l * l; // Shuffle repeated laps
		var age = lapTime - p.i * spawnRate;
		age -= age * fhash(i) * r.lifetime_random;

		// age /= 2; // Match

		// Loop
		if (r.loop) while (age < 0) age += animtime;

		if (age < 0 || age > lifetime) { p.x = p.y = p.z = -99999; return; } // Limit to current particle count

		if (r.physics_type == 1) computeNewton(p, i, age);
	}

	function computeNewton(p:Particle, i:Int, age:Float) {

		p.x = alignx;
		p.y = aligny;
		p.z = alignz;

		var l = particles.length;
		p.x += fhash(p.i + 0 * l) * r.factor_random - r.factor_random / 2;
		p.y += fhash(p.i + 1 * l) * r.factor_random - r.factor_random / 2;
		p.z += fhash(p.i + 2 * l) * r.factor_random - r.factor_random / 2;

		// Gravity
		p.x += (gx * r.mass * age) / 5;
		p.y += (gy * r.mass * age) / 5;
		p.z += (gz * r.mass * age) / 5;

		p.x *= age;
		p.y *= age;
		p.z *= age;
	}

	function setupGeomCpu(object:MeshObject, owner:MeshObject) {
		var instancedData = new kha.arrays.Float32Array(particles.length * 3);
		var i = 0;
		for (p in particles) {
			instancedData.set(i, 0.0); i++;
			instancedData.set(i, 0.0); i++;
			instancedData.set(i, 0.0); i++;
		}
		if (r.particle_size != 1.0) object.data.geom.applyScale(r.particle_size, r.particle_size, r.particle_size);
		object.data.geom.setupInstanced(instancedData, 1, Usage.DynamicUsage);
		
		emitFrom = new kha.arrays.Float32Array(particles.length * 3);
		i = 0;
		if (r.emit_from == 0) { // Vert, Face
			var pa = owner.data.geom.positions;
			for (p in particles) {
				var j = Std.int(fhash(i) * (pa.length / 3));
				emitFrom.set(i, pa[j * 3 + 0]); i++;
				emitFrom.set(i, pa[j * 3 + 1]); i++;
				emitFrom.set(i, pa[j * 3 + 2]); i++;
			}
		}
		else { // Volume
			for (p in particles) {
				emitFrom.set(i, (Math.random() * 2.0 - 1.0) * (object.transform.dim.x / 2.0)); i++;
				emitFrom.set(i, (Math.random() * 2.0 - 1.0) * (object.transform.dim.y / 2.0)); i++;
				emitFrom.set(i, (Math.random() * 2.0 - 1.0) * (object.transform.dim.z / 2.0)); i++;
			}
		}
	}

	function sort() {
		var camera = iron.Scene.active.camera;
		var l = camera.transform.loc;

		for (p in particles) { // TODO: check particle systems located at non-origin location
			p.cameraDistance = Vec4.distancef(p.x, p.y, p.z, l.x, l.y, l.z);
		}

		particles.sort(function(p1:Particle, p2:Particle):Int {
			if (p1.cameraDistance > p2.cameraDistance) return -1;
			if (p1.cameraDistance < p2.cameraDistance) return 1;
			return 0;
		});
	}

	#end

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

#end
