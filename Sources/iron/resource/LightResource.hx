package iron.resource;

import iron.math.Mat4;
import iron.resource.SceneFormat;

class LightResource extends Resource {

	public var resource:TLightResource;

	// Shadow map matrices
	public var P:Mat4 = null;
		
	public var lightType = 0;

	public function new(resource:TLightResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;
		
		var type = resource.type;
		
		if (type == "sun") {
			lightType = 0;
			P = Mat4.orthogonal(-10, 10, -10, 10, -100, 100, 2);
			// P = Mat4.orthogonal(-75 / 3.5, 75 / 3.5, -75 / 3.5, 75 / 3.5, -120 / 3.5, 120 / 3.5, 2);
		}
		else if (type == "point") {
			lightType = 1;
			P = Mat4.perspective(45, 1, 0.1, 100);
		}
		else if (type == "spot") {
			lightType = 2;
			P = Mat4.perspective(45, 1, 0.1, 100);
		}
	}

	public static function parse(name:String, id:String):LightResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TLightResource = Resource.getLightResourceById(format.light_resources, id);
		return new LightResource(resource);
	}
}
