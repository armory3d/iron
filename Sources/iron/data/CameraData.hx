package iron.data;

import iron.data.SceneFormat;

class CameraData extends Data {

	public var name:String;
	public var raw:TCameraData;
	public var pathdata:RenderPathData;
	public var mirror:kha.Image = null;

	public function new(raw:TCameraData, done:CameraData->Void) {
		super();
		this.raw = raw;
		this.name = raw.name;

		var pathName:Array<String> = raw.render_path.split("/");
		Data.getRenderPath(pathName[0], pathName[1], function(b:RenderPathData) {
			pathdata = b;

			// Render this camera to texture
			if (raw.is_mirror) {
				mirror = kha.Image.createRenderTarget(
					raw.mirror_resolution_x, raw.mirror_resolution_y,
					kha.graphics4.TextureFormat.RGBA32,
					kha.graphics4.DepthStencilFormat.NoDepthAndStencil);
			}

			done(this);
		});
	}

	public static function parse(name:String, id:String, done:CameraData->Void) {
		Data.getSceneRaw(name, function(format:TSceneFormat) {
			var raw:TCameraData = Data.getCameraRawByName(format.camera_datas, id);
			if (raw == null) {
				trace('Camera data "$id" not found!');
				done(null);
			}
			new CameraData(raw, done);
		});
	}
}
