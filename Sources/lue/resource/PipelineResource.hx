package lue.resource;

import lue.resource.importer.SceneFormat;

class PipelineResource extends Resource {

	public var resource:TPipelineResource;
	public var renderTargets:Map<String, kha.Image> = null;

	public function new(resource:TPipelineResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;

		if (resource.render_targets.length > 0) {
			renderTargets = new Map();

			for (t in resource.render_targets) {
				var image = kha.Image.createRenderTarget(
								t.width,
								t.height,
								//#if js
								kha.graphics4.TextureFormat.RGBA32,
								//#else
								//kha.graphics4.TextureFormat.RGBA128,
								//#end
								true);
				renderTargets.set(t.id, image);
			}
		}
	}

	public static function parse(name:String, id:String):PipelineResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TPipelineResource = Resource.getPipelineResourceById(format.pipeline_resources, id);
		return new PipelineResource(resource);
	}
}
