package lue.resource;

import lue.resource.importer.SceneFormat;

class CameraResource extends Resource {

	public var resource:TCameraResource;
	var pipeline:PipelineResource;

	public var shadowMap:kha.Image;

	public function new(resource:TCameraResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;

		var pipelineName:Array<String> = resource.pipeline.split("/");
		pipeline = PipelineResource.parse(pipelineName[0], pipelineName[1]);

		if (resource.shadowmap_size > 0) {
			//shadowMap = kha.Image.createRenderTarget(resource.shadowmap_size, resource.shadowmap_size, kha.graphics4.TextureFormat.RGBA128);
			shadowMap = kha.Image.createRenderTarget(resource.shadowmap_size, resource.shadowmap_size);
		}
	}

	public static function parse(name:String, id:String):CameraResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TCameraResource = Resource.getCameraResourceById(format.camera_resources, id);
		return new CameraResource(resource);
	}
}
