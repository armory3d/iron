package iron.data;

import iron.data.SceneFormat;

class CameraData extends Data {

	public var raw:TCameraData;
	public var pipeline:PipelineData;

	public function new(raw:TCameraData) {
		super();
		this.raw = raw;

		var pipelineName:Array<String> = raw.pipeline.split("/");
		pipeline = Data.getPipeline(pipelineName[0], pipelineName[1]);
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
