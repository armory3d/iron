package lue.resource;

import lue.resource.importer.SceneFormat;

class CameraResource extends Resource {

	public var resource:TCameraResource;

	public function new(resource:TCameraResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;
	}

	public static function parse(name:String, id:String):CameraResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TCameraResource = Resource.getCameraResourceById(format.camera_resources, id);
		return new CameraResource(resource);
	}
}
