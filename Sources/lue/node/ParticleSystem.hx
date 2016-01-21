package lue.node;

import kha.graphics4.Usage;
import lue.resource.Resource;
import lue.resource.ParticleResource;
import lue.resource.importer.SceneFormat;
import lue.sys.Time;
import lue.math.Vec4;

class ParticleSystem {

	var id:String;
	var resource:ParticleResource;
	var seed:Int;

	var node:ModelNode;

	var particles:Array<Particle>;

	public function new(node:ModelNode, sceneName:String, pref:TParticleReference) {
		this.node = node;
		id = pref.id;
		resource = Resource.getParticle(sceneName, pref.particle);
		seed = pref.seed;

		particles = [];
		var r = resource.resource;
		for (i in 0...r.count) {
			var p = new Particle();
			particles.push(p);
			p.offset = new Vec4(0.0, 0.0, 0.0);
			p.velocity = new Vec4(0.0, 0.0, 0.0);
			setVelocity(p.velocity);
			p.lifetime = Std.random(Std.int(r.lifetime * 1000)) / 1000;
		}

		// Make model geometry instanced
		var instancedData:Array<Float> = []; // TODO: use Float32Array directly
		for (p in particles) {
			instancedData.push(p.offset.x);
			instancedData.push(p.offset.y);
			instancedData.push(p.offset.z);
		}
		node.resource.setupInstancedGeometry(instancedData, Usage.DynamicUsage);
	}

	public function update() {
		for (p in particles) { // TODO: Sort Float32Array directly
			p.lifetime += Time.delta;

			if (p.lifetime > resource.resource.lifetime) {
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
		var vb = node.resource.geometry.instancedVertexBuffers[1];
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
		var r = resource.resource;
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
		var camera = Node.cameras[0]; // TODO: pass camera manually

		for (p in particles) { // TODO: check particle systems located at non-origin position
			p.cameraDistance = lue.math.Math.distance3d(p.offset, camera.transform.pos);
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
