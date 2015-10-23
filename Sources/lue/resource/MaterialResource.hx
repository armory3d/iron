package lue.resource;

import lue.resource.importer.SceneFormat;
import lue.node.ModelNode;

class MaterialResource extends Resource {

	public var resource:TMaterialResource;
	public var shader:ShaderResource;

	public var textures:Array<kha.Image> = null;

	public function new(resource:TMaterialResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;

		shader = Resource.getShader(resource.shader_resource, resource.shader_id);

		if (resource.textures.length > 0) {
			textures = [];
			for (i in 0...resource.textures.length) {
				// TODO: make sure to store in the same order as shader texture units array
				textures.push(kha.Loader.the.getImage(resource.textures[i].name));
			}
		}
	}

	public static function parse(name:String, id:String):MaterialResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TMaterialResource = Resource.getMaterialResourceById(format.material_resources, id);
		return new MaterialResource(resource);
	}
}
