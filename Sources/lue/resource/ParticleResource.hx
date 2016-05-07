package lue.resource;

import lue.resource.SceneFormat;

class ParticleResource extends Resource {

	public var resource:TParticleResource;

	public function new(resource:TParticleResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;
	}

	public static function parse(name:String, id:String):ParticleResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TParticleResource = Resource.getParticleResourceById(format.particle_resources, id);
		return new ParticleResource(resource);
	}
}
