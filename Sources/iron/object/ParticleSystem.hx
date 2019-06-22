package iron.object;

#if arm_particles

import kha.graphics4.Usage;
import kha.arrays.Float32Array;
import iron.data.Data;
import iron.data.ParticleData;
import iron.data.SceneFormat;
import iron.system.Time;
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
	var seed = 0;

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
	var m = Mat4.identity();

	public function new(sceneName:String, pref:TParticleReference) {
		seed = pref.seed;
		particles = [];
		ready = false;
		Data.getParticle(sceneName, pref.particle, function(b:ParticleData) {
			data = b;
			r = data.raw;
			gx = Scene.active.raw.gravity[0] * r.weight_gravity;
			gy = Scene.active.raw.gravity[1] * r.weight_gravity;
			gz = Scene.active.raw.gravity[2] * r.weight_gravity;
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

	public function update(object:MeshObject, owner:MeshObject) {
		if (!ready || object == null || speed == 0.0) return;

		// Copy owner transform but discard scale
		object.transform.loc = owner.transform.loc;
		object.transform.rot = owner.transform.rot;
		object.transform.buildMatrix();
		owner.transform.buildMatrix();
		object.transform.dim.setFrom(owner.transform.dim);

		dimx = object.transform.dim.x;
		dimy = object.transform.dim.y;

		if (object.tilesheet != null) {
			tilesx = object.tilesheet.raw.tilesx;
			tilesy = object.tilesheet.raw.tilesy;
			tilesFramerate = object.tilesheet.raw.framerate;
		}

		// Animate
		time += Time.realDelta * speed;
		lap = Std.int(time / animtime);
		lapTime = time - lap * animtime;
		count = Std.int(lapTime / spawnRate);

		updateGpu(object, owner);
	}

	public function getData():Mat4 {
		var hair = r.type == 1;
		m._00 = r.loop ? animtime : -animtime;
		m._01 = hair ? 1 / particles.length : spawnRate;
		m._02 = hair ? 1 : lifetime;
		m._03 = particles.length;
		m._10 = hair ? 0 : alignx;
		m._11 = hair ? 0 : aligny;
		m._12 = hair ? 0 : alignz;
		m._13 = hair ? 0 : r.factor_random;
		m._20 = hair ? 0 : gx * r.mass;
		m._21 = hair ? 0 : gy * r.mass;
		m._22 = hair ? 0 : gz * r.mass;
		m._23 = hair ? 0 : r.lifetime_random;
		m._30 = tilesx;
		m._31 = tilesy;
		m._32 = 1 / tilesFramerate;
		m._33 = hair ? 1 : lapTime;
		return m;
	}

	function updateGpu(object:MeshObject, owner:MeshObject) {
		if (!object.data.geom.instanced) setupGeomGpu(object, owner);
		// GPU particles transform is attached to owner object
	}

	function setupGeomGpu(object:MeshObject, owner:MeshObject) {
		var instancedData = new Float32Array(particles.length * 3);
		var i = 0;
		if (r.emit_from == 0) { // Vert, Face
			var pa = owner.data.geom.positions;
			var sc = owner.data.scalePos;
			for (p in particles) {
				var j = Std.int(fhash(i) * (pa.length / 4));
				instancedData.set(i, pa[j * 4    ] / 32767 * sc); i++;
				instancedData.set(i, pa[j * 4 + 1] / 32767 * sc); i++;
				instancedData.set(i, pa[j * 4 + 2] / 32767 * sc); i++;
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

	function fhash(n:Int):Float {
		var s = n + 1.0;
		s *= 9301.0 % s;
		s = (s * 9301.0 + 49297.0) % 233280.0;
		return s / 233280.0;
	}

	public function remove() {}
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
