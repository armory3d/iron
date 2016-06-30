package lue.resource;

import kha.Image;
import kha.graphics4.TextureFormat;
import kha.graphics4.DepthStencilFormat;
import lue.resource.SceneFormat;

class PipelineResource extends Resource {

	public var resource:TPipelineResource;
	public var renderTargets:Map<String, RenderTarget> = null;
	public var depthToRenderTarget:Map<String, RenderTarget> = null;

	public function new(resource:TPipelineResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;

		if (resource.render_targets.length > 0) {
			renderTargets = new Map();
			
			if (resource.depth_buffers != null && resource.depth_buffers.length > 0) {
				depthToRenderTarget = new Map();
			}

			for (t in resource.render_targets) {
				var rt = makeRenderTarget(t);
				if (t.ping_pong != null && t.ping_pong) rt.pong = makeRenderTarget(t);
				renderTargets.set(t.id, rt);
			}
		}
	}
	
	function makeRenderTarget(t:TPipelineRenderTarget) {
		var rt = new RenderTarget();
		
		// With depth buffer
		if (t.depth_buffer != null) {
			rt.hasDepth = true;
			var depthTarget = depthToRenderTarget.get(t.depth_buffer);
			
			// Create new one
			if (depthTarget == null) {
				for (db in resource.depth_buffers) {
					if (db.id == t.depth_buffer) {
						depthToRenderTarget.set(db.id, rt);
						rt.image = createImage(t, getDepthStencilFormat(true, db.stencil_buffer));
						break;
					}
				}
			}
			// Reuse
			else {
				rt.image = createImage(t, DepthStencilFormat.NoDepthAndStencil);
				rt.image.setDepthStencilFrom(depthTarget.image);
			}
		}
		// No depth buffer
		else {
			rt.hasDepth = false;
			rt.image = createImage(t, DepthStencilFormat.NoDepthAndStencil);
		}
		
		return rt;
	}

	function createImage(t:TPipelineRenderTarget, depthStencil:DepthStencilFormat):Image {
		var width = t.width == 0 ? kha.System.windowWidth() : t.width;
		var height = t.height == 0 ? kha.System.windowHeight() : t.height;
		if (t.scale != null) {
			width = Std.int(width * t.scale);
			height = Std.int(height * t.scale);
		}
		return Image.createRenderTarget(
			width, height,
			t.format != null ? getTextureFormat(t.format) : TextureFormat.RGBA32,
			depthStencil);
	}

	inline function getTextureFormat(s:String):TextureFormat {
		if (s == "RGBA32") return TextureFormat.RGBA32;
		else if (s == "RGBA128") return TextureFormat.RGBA128;
		else if (s == "DEPTH16") return TextureFormat.DEPTH16;
		else if (s == "RGBA64") return TextureFormat.RGBA64;
		else if (s == "A32") return TextureFormat.A32;
		else if (s == "A16") return TextureFormat.A16;
		else if (s == "A8") return TextureFormat.L8;
		else return TextureFormat.RGBA32;
	}
	
	inline function getDepthStencilFormat(depth:Bool, stencil:Bool):DepthStencilFormat {
		if (depth && stencil) return DepthStencilFormat.Depth24Stencil8;
		else if (depth) return DepthStencilFormat.DepthOnly;
		else return DepthStencilFormat.NoDepthAndStencil; 
	}

	public static function parse(name:String, id:String):PipelineResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TPipelineResource = Resource.getPipelineResourceById(format.pipeline_resources, id);
		return new PipelineResource(resource);
	}
}

class RenderTarget {
	public var image:Image;
	public var hasDepth:Bool;
	public var pongState = false;
	public var pong:RenderTarget = null;
	public function new() {}
}
