package iron.object;

import iron.data.ProbeData;
import iron.Scene;

class ProbeObject extends Object {

#if rp_probes

	public var data:ProbeData;

	public function new(data:ProbeData) {
		super();
		this.data = data;
		Scene.active.probes.push(this);
	}

	public override function remove() {
		if (Scene.active != null) Scene.active.probes.remove(this);
		super.remove();
	}

#end
}
