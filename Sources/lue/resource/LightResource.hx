package lue.resource;

import lue.resource.SceneFormat;

class LightResource extends Resource {

	public var resource:TLightResource;

	public function new(resource:TLightResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;
	}

	public static function parse(name:String, id:String):LightResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TLightResource = Resource.getLightResourceById(format.light_resources, id);
		return new LightResource(resource);
	}
}
