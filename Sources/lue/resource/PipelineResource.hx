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
			t.width == 0 ? kha.System.windowWidth() : t.width,
			t.height == 0 ? kha.System.windowHeight() : t.height,
			t.format != null ? getTextureFormat(t.format) : TextureFormat.RGBA32,
			t.depth_buffer != null ? getDepthStencilFormat(t.depth_buffer) : kha.DepthStencilFormat.NoDepthAndStencil);
	}

	inline function getTextureFormat(s:String):TextureFormat {
		if (s == "RGBA32") return TextureFormat.RGBA32;
		else if (s == "RGBA128") return TextureFormat.RGBA128;
		else if (s == "DEPTH16") return TextureFormat.DEPTH16;
		else return TextureFormat.RGBA32;
	}
	
	inline function getDepthStencilFormat(b:Bool):kha.DepthStencilFormat {
		return b ? kha.DepthStencilFormat.DepthOnly : kha.DepthStencilFormat.NoDepthAndStencil;
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
