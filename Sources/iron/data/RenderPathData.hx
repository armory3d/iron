package iron.data;

import kha.Image;
import kha.graphics4.TextureFormat;
import kha.graphics4.DepthStencilFormat;
import iron.data.SceneFormat;

class RenderPathData extends Data {

	public var name:String;
	public var raw:TRenderPathData;
	public var renderTargets:Map<String, RenderTarget> = null;
	public var depthToRenderTarget:Map<String, RenderTarget> = null;

	public function new(raw:TRenderPathData) {
		super();

		this.raw = raw;
		this.name = raw.name;

		if (raw.render_targets.length > 0) {
			renderTargets = new Map();
			
			if (raw.depth_buffers != null && raw.depth_buffers.length > 0) {
				depthToRenderTarget = new Map();
			}

			for (t in raw.render_targets) {
				var rt = makeRenderTarget(t);
				if (t.ping_pong != null && t.ping_pong) rt.pong = makeRenderTarget(t);
				renderTargets.set(t.name, rt);
			}
		}
	}
	
	function makeRenderTarget(t:TRenderPathTarget) {
		var rt = new RenderTarget();
		
		// With depth buffer
		if (t.depth_buffer != null) {
			rt.hasDepth = true;
			var depthTarget = depthToRenderTarget.get(t.depth_buffer);
			
			// Create new one
			if (depthTarget == null) {
				for (db in raw.depth_buffers) {
					if (db.name == t.depth_buffer) {
						depthToRenderTarget.set(db.name, rt);
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

	function createImage(t:TRenderPathTarget, depthStencil:DepthStencilFormat):Image {
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
		else if (s == "A32") return TextureFormat.A32; // Single channels are non-renderable on webgl
		else if (s == "A16") return TextureFormat.A16;
		else if (s == "A8") return TextureFormat.L8;
		else return TextureFormat.RGBA32;
	}
	
	inline function getDepthStencilFormat(depth:Bool, stencil:Bool):DepthStencilFormat {
		if (depth && stencil) return DepthStencilFormat.Depth24Stencil8;
		else if (depth) return DepthStencilFormat.DepthOnly;
		else return DepthStencilFormat.NoDepthAndStencil; 
	}

	public static function parse(file:String, name:String):RenderPathData {
		var format:TSceneFormat = Data.getSceneRaw(file);
		var raw:TRenderPathData = Data.getRenderPathRawByName(format.renderpath_datas, name);
		if (raw == null) {
			trace('Render path data "$name" not found!');
			return null;
		}
		return new RenderPathData(raw);
	}
}

class RenderTarget {
	public var image:Image;
	public var hasDepth:Bool;
	public var pongState = false;
	public var pong:RenderTarget = null;
	public function new() {}
}
