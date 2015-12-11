package lue.node;

import lue.resource.Resource;
import lue.resource.ParticleResource;
import lue.resource.importer.SceneFormat;

class ParticleSystem {

	var id:String;
	var resource:ParticleResource;
	var seed:Int;

	var offsets = [0.0, 0.0, 0.0];

	public function new(node:ModelNode, sceneName:String, pref:TParticleReference) {
		id = pref.id;
		resource = Resource.getParticle(sceneName, pref.particle);
		seed = pref.seed;

		// Make model geometry instanced
		node.resource.setupInstancedGeometry(offsets);
	}

	public function update() {

	}
}
