package lue.resource;

import lue.resource.importer.SceneFormat;
import lue.node.ModelNode;

class MaterialResource extends Resource {

	public var resource:TMaterialResource;
	public var shader:ShaderResource;

	var texture:kha.Image = null;

	public function new(resource:TMaterialResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

		this.resource = resource;

		shader = Resource.getShader(resource.shader_resource, resource.shader_id);

		if (resource.texture != "") {
			texture = kha.Loader.the.getImage(resource.texture);
		}
	}

	public static function parse(name:String, id:String):MaterialResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TMaterialResource = Resource.getMaterialResourceById(format.material_resources, id);
		return new MaterialResource(resource);
	}

	public function registerRenderer() {
		// Register material uniforms here
	}

	public function setConstants(g:kha.graphics4.Graphics) {
		g.setFloat4(shader.constants[ModelNode.CONST_VEC4_DIFFUSE_COLOR],
					resource.diffuse_color[0],
					resource.diffuse_color[1],
					resource.diffuse_color[2],
					resource.diffuse_color[3]);
		
		g.setFloat(shader.constants[ModelNode.CONST_F_ROUGHNESS], resource.roughness);

		if (texture != null) {
			g.setBool(shader.constants[ModelNode.CONST_B_TEXTURING], true);
			g.setTexture(shader.textures[ModelNode.CONST_TEX_STEX], texture);
		}
		else {
			g.setBool(shader.constants[ModelNode.CONST_B_TEXTURING], false);
		}
	}
}
