package iron.resource;

import iron.math.Mat4;
import iron.resource.SceneFormat;

class LightResource extends Resource {

	public var resource:TLightResource;

	public var P:Mat4 = null; // Shadow map matrices
	public var lightType = 0;

	public function new(resource:TLightResource) {
		super();

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
		if (resource == null) {
			trace('Light resource "$id" not found!');
			return null;
		}
		return new LightResource(resource);
	}
}
