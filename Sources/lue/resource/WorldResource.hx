package lue.resource;

import kha.Image;
import lue.resource.SceneFormat;

class WorldResource extends Resource {

	public var resource:TWorldResource;
	
	public var radiance:Image;
	public var irradiance:Image;
	public var brdf:Image;
	public var strength:Float;

	public function new(resource:TWorldResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;
		
		if (resource.radiance != "") {
			irradiance = Reflect.field(kha.Assets.images, resource.irradiance);
			radiance = Reflect.field(kha.Assets.images, resource.radiance);
			var radianceMipmaps:Array<kha.Image> = [];
			for (i in 0...resource.radiance_mipmaps) {
				radianceMipmaps.push(Reflect.field(kha.Assets.images,resource.radiance + '_' + i));
			}
			radiance.setMipmaps(radianceMipmaps);
			brdf = Reflect.field(kha.Assets.images, resource.brdf);
		}
		
		strength = resource.strength;
	}

	public static function parse(name:String, id:String):WorldResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TWorldResource = Resource.getWorldResourceById(format.world_resources, id);
		return new WorldResource(resource);
	}
}
