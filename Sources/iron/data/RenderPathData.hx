package iron.data;

import kha.Image;
import kha.graphics4.CubeMap;
import kha.graphics4.TextureFormat;
import kha.graphics4.DepthStencilFormat;
import iron.data.SceneFormat;

class RenderPathData extends Data {

	public var name:String;
	public var raw:TRenderPathData;
	public var renderTargets:Map<String, RenderTarget> = new Map();
	public var depthToRenderTarget:Map<String, RenderTarget> = new Map();

	public function new(raw:TRenderPathData, done:RenderPathData->Void) {
		super();

		this.raw = raw;
		this.name = raw.name;

		if (raw.render_targets != null && raw.render_targets.length > 0) {
			for (t in raw.render_targets) createRenderTarget(t);
		}

		#if kha_webgl
		// Bind empty when requested target is not found
		var tempty:TRenderPathTarget = {
			name: "arm_empty",
			width: 1,
			height: 1,
			format: "DEPTH16"
		};
		createRenderTarget(tempty);
		var temptyCube:TRenderPathTarget = {
			name: "arm_empty_cube",
			width: 1,
			height: 1,
			format: "DEPTH16",
			is_cubemap: true
		};
		createRenderTarget(temptyCube);
		#end

		done(this);
	}

	public function unload() {
		for (rt in renderTargets) rt.unload();
	}

	public static function parse(file:String, name:String, done:RenderPathData->Void) {
		Data.getSceneRaw(file, function(format:TSceneFormat) {
			var raw:TRenderPathData = Data.getRenderPathRawByName(format.renderpath_datas, name);
			if (raw == null) {
				trace('Render path data "$name" not found!');
				done(null);
			}
			new RenderPathData(raw, done);
		});
	}

	public function resize() {
		for (rt in renderTargets) {
			if (rt.raw.width == 0) {
				rt.image.unload();
				rt.image = createImage(rt.raw, rt.depthStencil);
				if (rt.depthStencilFrom != "") {
					rt.image.setDepthStencilFrom(depthToRenderTarget.get(rt.depthStencilFrom).image);
				}
			}
		}
	}
	
	public function createRenderTarget(t:TRenderPathTarget):RenderTarget {
		var rt = _createRenderTarget(t);
		if (t.ping_pong != null && t.ping_pong) rt.pong = _createRenderTarget(t);
		renderTargets.set(t.name, rt);
		return rt;
	}

	function _createRenderTarget(t:TRenderPathTarget):RenderTarget {
		var rt = new RenderTarget(t);
		// With depth buffer
		if (t.depth_buffer != null) {
			rt.hasDepth = true;
			var depthTarget = depthToRenderTarget.get(t.depth_buffer);
			
			// Create new one
			if (depthTarget == null) {
				for (db in raw.depth_buffers) {
					if (db.name == t.depth_buffer) {
						depthToRenderTarget.set(db.name, rt);
						rt.depthStencil = getDepthStencilFormat(db.format);
						rt.image = createImage(t, rt.depthStencil);
						break;
					}
				}
			}
			// Reuse
			else {
				rt.depthStencil = DepthStencilFormat.NoDepthAndStencil;
				rt.depthStencilFrom = t.depth_buffer;
				rt.image = createImage(t, rt.depthStencil);
				rt.image.setDepthStencilFrom(depthTarget.image);
			}
		}
		// No depth buffer
		else {
			rt.hasDepth = false;
			if (t.depth != null && t.depth > 1) rt.is3D = true;
			if (t.is_cubemap) {
				rt.isCubeMap = true;
				rt.depthStencil = DepthStencilFormat.NoDepthAndStencil;
				rt.cubeMap = createCubeMap(t, rt.depthStencil);
			}
			else {
				rt.depthStencil = DepthStencilFormat.NoDepthAndStencil;
				rt.image = createImage(t, rt.depthStencil);
			}
		}
		
		return rt;
	}

	function createImage(t:TRenderPathTarget, depthStencil:DepthStencilFormat):Image {
		var width = t.width == 0 ? iron.App.w() : t.width;
		var height = t.height == 0 ? iron.App.h() : t.height;
		var depth = t.depth != null ? t.depth : 0;
		if (t.displayp != null) { // 1080p/..
			if (width > height) {
				height = Std.int(height * (t.displayp / width));
				width = t.displayp;
			}
			else {
				width = Std.int(width * (t.displayp / height));
				height = t.displayp;
			}
		}
		if (t.scale != null) {
			width = Std.int(width * t.scale);
			height = Std.int(height * t.scale);
			depth = Std.int(depth * t.scale);
		}
		if (t.depth != null && t.depth > 1) { // 3D texture
			// Image only
			return Image.create3D(width, height, depth,
				t.format != null ? getTextureFormat(t.format) : TextureFormat.RGBA32);
		}
		else { // 2D texture
			if (t.is_image != null && t.is_image) { // Image
				return Image.create(width, height,
					t.format != null ? getTextureFormat(t.format) : TextureFormat.RGBA32);
			}
			else { // Render target
				return Image.createRenderTarget(width, height,
					t.format != null ? getTextureFormat(t.format) : TextureFormat.RGBA32,
					depthStencil);
			}
		}
	}

	function createCubeMap(t:TRenderPathTarget, depthStencil:DepthStencilFormat):CubeMap {
		return CubeMap.createRenderTarget(t.width,
			t.format != null ? getTextureFormat(t.format) : TextureFormat.RGBA32,
			depthStencil);
	}

	inline function getTextureFormat(s:String):TextureFormat {
		switch (s) {
		case "RGBA32": return TextureFormat.RGBA32;
		case "RGBA64": return TextureFormat.RGBA64;
		case "RGBA128": return TextureFormat.RGBA128;
		case "DEPTH16": return TextureFormat.DEPTH16;
		case "A32": return TextureFormat.A32; // Single channels are non-renderable on webgl
		case "A16": return TextureFormat.A16;
		case "A8": return TextureFormat.L8;
		case "R32": return TextureFormat.A32;
		case "R16": return TextureFormat.A16;
		case "R8": return TextureFormat.L8;
		default: return TextureFormat.RGBA32;
		}
	}
	
	inline function getDepthStencilFormat(s:String):DepthStencilFormat {
		// if (depth && stencil) return DepthStencilFormat.Depth24Stencil8;
		// else if (depth) return DepthStencilFormat.DepthOnly;
		// else return DepthStencilFormat.NoDepthAndStencil; 
		if (s == null || s == "") return DepthStencilFormat.DepthOnly;
		switch (s) {
		case "DEPTH24": return DepthStencilFormat.DepthOnly; // Depth32Stencil8
		case "DEPTH16": return DepthStencilFormat.Depth16;
		default: return DepthStencilFormat.DepthOnly;
		}
	}
}

class RenderTarget {
	public var raw:TRenderPathTarget;
	public var depthStencil:DepthStencilFormat;
	public var depthStencilFrom = "";
	public var image:Image = null; // RT or image
	public var cubeMap:CubeMap = null;
	public var hasDepth = false;
	public var pongState = false;
	public var pong:RenderTarget = null;
	public var is3D = false; // sampler2D / sampler3D
	public var isCubeMap = false;
	public function new(raw:TRenderPathTarget) { this.raw = raw; }
	public function unload() {
		if (image != null) image.unload();
		if (cubeMap != null) cubeMap.unload();
		if (pong != null) pong.unload();
	}
}
