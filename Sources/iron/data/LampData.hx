package iron.data;

import iron.math.Mat4;
import iron.data.SceneFormat;

class LampData extends Data {

	public var raw:TLampData;

	public var P:Mat4 = null; // Shadow map matrices
	public var lampType = 0;

	public function new(raw:TLampData) {
		super();

		this.raw = raw;
		
		var type = raw.type;
		var fov = raw.fov;
		
		if (type == "sun") {
			lampType = 0;
			// Estimate planes from fov
			var orthoScale = 2.0;
			P = Mat4.orthogonal(-fov * 25, fov * 25, -fov * 25, fov * 25, -raw.far_plane, raw.far_plane, orthoScale);
		}
		else if (type == "point") {
			lampType = 1;
			P = Mat4.perspective(fov, 1, raw.near_plane, raw.far_plane);
		}
		else if (type == "spot") {
			lampType = 2;
			P = Mat4.perspective(fov, 1, raw.near_plane, raw.far_plane);
		}
	}

	public static function parse(name:String, id:String):LampData {
		var format:TSceneFormat = Data.getSceneRaw(name);
		var raw:TLampData = Data.getLampRawByName(format.lamp_datas, id);
		if (raw == null) {
			trace('Lamp data "$id" not found!');
			return null;
		}
		return new LampData(raw);
	}
}
