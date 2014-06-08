package wings.trait;

import wings.core.Trait;
import wings.trait.camera.Camera;

class SceneRenderer extends Trait {

	@inject
	public var camera:Camera;

	public function new() {
		super();
	}
}
