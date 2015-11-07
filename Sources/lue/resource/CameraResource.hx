package lue.resource;

import lue.resource.importer.SceneFormat;

class CameraResource extends Resource {

	public var resource:TCameraResource;
	public var pipeline:PipelineResource;

	public function new(resource:TCameraResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;

		var pipelineName:Array<String> = resource.pipeline.split("/");
		pipeline = Resource.getPipeline(pipelineName[0], pipelineName[1]);
	}

	public static function parse(name:String, id:String):CameraResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TCameraResource = Resource.getCameraResourceById(format.camera_resources, id);
		return new CameraResource(resource);
	}
}
