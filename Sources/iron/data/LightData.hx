package iron.data;

import iron.math.Mat4;
import iron.data.SceneFormat;

class LightData extends Data {

	public var name:String;
	public var raw:TLightData;

	public var colorTexture:kha.Image = null;

	public function new(raw:TLightData, done:LightData->Void) {
		super();

		this.raw = raw;
		this.name = raw.name;

		if (raw.color_texture != null) {
			iron.data.Data.getImage(raw.color_texture, function(image:kha.Image) {
				colorTexture = image;
				done(this);
			});
		}
		else done(this);
	}

	public static inline function typeToInt(s:String):Int {
		switch(s) {
		case "sun": return 0;
		case "point": return 1;
		case "spot": return 2;
		case "area": return 3;
		default: return 0;
		}
	}

	public static function parse(name:String, id:String, done:LightData->Void) {
		Data.getSceneRaw(name, function(format:TSceneFormat) {
			var raw:TLightData = Data.getLightRawByName(format.light_datas, id);
			if (raw == null) {
				trace('Light data "$id" not found!');
				done(null);
			}
			new LightData(raw, done);
		});
	}
}
