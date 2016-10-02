package iron.object;

import iron.Scene;
import iron.data.SceneFormat;

class Constraint {
	var raw:TConstraint;
	var target:Transform = null;

	public function new(constr:TConstraint) {
		raw = constr;
	}

	public function apply(transform:Transform) {
		if (target == null) target = Scene.active.getChild(raw.target).transform;
		
		if (raw.type == "COPY_LOCATION") {
			if (raw.use_x) {
				transform.matrix._30 = target.loc.x;
				if (raw.use_offset) transform.matrix._30 += transform.loc.x;
			}
			if (raw.use_y) {
				transform.matrix._31 = target.loc.y;
				if (raw.use_offset) transform.matrix._31 += transform.loc.y;
			}
			if (raw.use_z) {
				transform.matrix._32 = target.loc.z;
				if (raw.use_offset) transform.matrix._32 += transform.loc.z;
			}
		}
	}
}
