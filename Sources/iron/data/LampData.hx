package iron.data;

import iron.math.Mat4;
import iron.data.SceneFormat;

class LampData extends Data {

	public var name:String;
	public var raw:TLampData;

	public var P:Mat4 = null; // Shadow map matrices

	public function new(raw:TLampData, done:LampData->Void) {
		super();

		this.raw = raw;
		this.name = raw.name;
		
		var type = raw.type;
		var fov = raw.fov;
		
		if (type == "sun") {
			// Estimate planes from fov
			var orthoScale = 2.0;
			P = Mat4.orthogonal(-fov * 25, fov * 25, -fov * 25, fov * 25, -raw.far_plane, raw.far_plane, orthoScale);
		}
		else if (type == "point") {
			P = Mat4.perspective(fov, 1, raw.near_plane, raw.far_plane);
		}
		else if (type == "spot") {
			P = Mat4.perspective(fov, 1, raw.near_plane, raw.far_plane);
		}

		done(this);
	}

	public static function typeToInt(s:String):Int {
		s == "sun" ? return 0 : s == "point" ? return 1 : return 2;
	}

	public static function parse(name:String, id:String, done:LampData->Void) {
		Data.getSceneRaw(name, function(format:TSceneFormat) {
			var raw:TLampData = Data.getLampRawByName(format.lamp_datas, id);
			if (raw == null) {
				trace('Lamp data "$id" not found!');
				done(null);
			}
			new LampData(raw, done);
		});
	}
}
