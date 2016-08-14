package iron.resource;

import iron.resource.SceneFormat;

class ParticleResource extends Resource {

	public var resource:TParticleResource;

	public function new(resource:TParticleResource) {
		super();

		this.resource = resource;
	}

	public static function parse(name:String, id:String):ParticleResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TParticleResource = Resource.getParticleResourceById(format.particle_resources, id);
		if (resource == null) {
			trace('Particle resource "$id" not found!');
			return null;
		}
		return new ParticleResource(resource);
	}
}
