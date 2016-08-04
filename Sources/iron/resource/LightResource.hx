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
		var fov = resource.fov;
		
		if (type == "sun") {
			lightType = 0;
			// Estimate planes from fov
			var orthoScale = 2.0;
			P = Mat4.orthogonal(-fov * 25, fov * 25, -fov * 25, fov * 25, -resource.far_plane, resource.far_plane, orthoScale);
		}
		else if (type == "point") {
			lightType = 1;
			// fov = iron.math.Math.PI / 4
			P = Mat4.perspective(fov, 1, resource.near_plane, resource.far_plane);
		}
		else if (type == "spot") {
			lightType = 2;
			P = Mat4.perspective(fov, 1, resource.near_plane, resource.far_plane);
		}
	}

	public static function parse(name:String, id:String):LightResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TLightResource = Resource.getLightResourceById(format.light_resources, id);
		return new LightResource(resource);
	}
}
