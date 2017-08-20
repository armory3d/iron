package iron.data;

import iron.data.SceneFormat;

class CameraData extends Data {

	public var name:String;
	public var raw:TCameraData;
	public var pathdata:RenderPathData;
	public var mirror:kha.Image = null;

	public function new(raw:TCameraData, done:CameraData->Void, file = "") {
		super();
		this.raw = raw;
		this.name = raw.name;

		var ref = raw.render_path.split("/");
		var object_file = "";
		var data_ref = "";
		if (ref.length == 2) { // File reference
			object_file = ref[0];
			data_ref = ref[1];
		}
		else { // Local data
			object_file = file;
			data_ref = raw.render_path;
		}

		Data.getRenderPath(object_file, data_ref, function(b:RenderPathData) {
			pathdata = b;

			if (raw.render_to_texture) {
				mirror = kha.Image.createRenderTarget(
					raw.texture_resolution_x, raw.texture_resolution_y,
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
			new CameraData(raw, done, name);
		});
	}
}
