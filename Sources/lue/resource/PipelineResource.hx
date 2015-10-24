package lue.resource;

import lue.resource.importer.SceneFormat;

class PipelineResource extends Resource {

	public var resource:TPipelineResource;

	public function new(resource:TPipelineResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;
	}

	public static function parse(name:String, id:String):PipelineResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TPipelineResource = Resource.getPipelineResourceById(format.pipeline_resources, id);
		return new PipelineResource(resource);
	}
}
