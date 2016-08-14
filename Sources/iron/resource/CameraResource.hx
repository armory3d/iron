package iron.resource;

import iron.resource.SceneFormat;

class CameraResource extends Resource {

	public var resource:TCameraResource;
	public var pipeline:PipelineResource;

	public function new(resource:TCameraResource) {
		super();
		this.resource = resource;

		var pipelineName:Array<String> = resource.pipeline.split("/");
		pipeline = Resource.getPipeline(pipelineName[0], pipelineName[1]);
	}

	public static function parse(name:String, id:String):CameraResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TCameraResource = Resource.getCameraResourceById(format.camera_resources, id);
		if (resource == null) {
			trace('Camera resource "$id" not found!');
			return null;
		}
		return new CameraResource(resource);
	}
}
