package lue.resource;

import lue.resource.importer.SceneFormat;

class LightResource extends Resource {

	public var resource:TLightResource;

	public function new(name:String, id:String) {
		super();

		var format:TSceneFormat = Resource.getSceneResource(name);
		resource = Resource.getLightResourceById(format.light_resources, id);
		if (resource == null) {
			trace("Resource not found!");
			return;
		}
	}
}
