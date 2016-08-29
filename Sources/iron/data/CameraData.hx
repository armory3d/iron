package iron.data;

import iron.data.SceneFormat;

class CameraData extends Data {

	public var name:String;
	public var raw:TCameraData;
	public var pipeline:PipelineData;

	public var mirror:kha.Image = null;

	public function new(raw:TCameraData) {
		super();
		this.raw = raw;
		this.name = raw.name;

		var pipelineName:Array<String> = raw.pipeline.split("/");
		pipeline = Data.getPipeline(pipelineName[0], pipelineName[1]);

		// Render this camera to texture
		if (raw.is_mirror) {
			mirror = kha.Image.createRenderTarget(
				raw.mirror_resolution_x, raw.mirror_resolution_y,
				kha.graphics4.TextureFormat.RGBA32,
				kha.graphics4.DepthStencilFormat.NoDepthAndStencil);
		}
	}

	public static function parse(name:String, id:String):CameraData {
		var format:TSceneFormat = Data.getSceneRaw(name);
		var raw:TCameraData = Data.getCameraRawByName(format.camera_datas, id);
		if (raw == null) {
			trace('Camera data "$id" not found!');
			return null;
		}
		return new CameraData(raw);
	}
}
