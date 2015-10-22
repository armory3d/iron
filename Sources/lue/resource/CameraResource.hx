package lue.resource;

import lue.resource.importer.SceneFormat;

class CameraResource extends Resource {

	public var resource:TCameraResource;

	public function new(name:String, id:String) {
		super();

		var format:TSceneFormat = Resource.getSceneResource(name);
		resource = Resource.getCameraResourceById(format.camera_resources, id);
		if (resource == null) {
			trace("Resource not found!");
			return;
		}
	}
}
