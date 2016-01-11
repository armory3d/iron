package lue.resource;

import kha.Image;
import kha.graphics4.TextureFormat;
import lue.resource.importer.SceneFormat;

class PipelineResource extends Resource {

	public var resource:TPipelineResource;
	public var renderTargets:Map<String, RenderTarget> = null;

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
				var rt = new RenderTarget();
				rt.image = createImage(t);
				// MRT
				if (t.color_buffers != null && t.color_buffers > 1) {
					rt.additionalImages = [];
					for (i in 0...t.color_buffers - 1) {
						// TODO: disable depth for additional
						rt.additionalImages.push(createImage(t));
					}
				}
				renderTargets.set(t.id, rt);
			}
		}
	}

	function createImage(t:TPipelineRenderTarget):Image {
		return Image.createRenderTarget(
			t.width == 0 ? kha.System.pixelWidth : t.width,
			t.height == 0 ? kha.System.pixelHeight : t.height,
			t.format != null ? getTextureFormat(t.format) : TextureFormat.RGBA32,
			t.depth_buffer != null ? t.depth_buffer : true);
	}

	inline function getTextureFormat(s:String):TextureFormat {
		return s == "RGBA32" ? TextureFormat.RGBA32 : TextureFormat.RGBA128;
	}

	public static function parse(name:String, id:String):PipelineResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TPipelineResource = Resource.getPipelineResourceById(format.pipeline_resources, id);
		return new PipelineResource(resource);
	}
}

class RenderTarget {
	public var image:Image;
	public var additionalImages:Array<kha.Canvas> = null;
	public function new() {}
}
