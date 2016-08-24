package iron.data;

import iron.data.SceneFormat;
import iron.data.ShaderData;
import iron.object.MeshObject;

class MaterialData extends Data {

	public var raw:TMaterialData;
	public var shader:ShaderData;

	public var contexts:Array<MaterialContext> = [];

	public function new(raw:TMaterialData) {
		super();

		this.raw = raw;

		var shaderName:Array<String> = raw.shader.split("/");
		shader = Data.getShader(shaderName[0], shaderName[1], raw.override_context);

		for (c in raw.contexts) {
			contexts.push(new MaterialContext(c));
		}
	}

	public static function parse(file:String, name:String):MaterialData {
		var format:TSceneFormat = Data.getSceneRaw(file);
		var raw:TMaterialData = Data.getMaterialRawByName(format.material_datas, name);
		if (raw == null) {
			trace('Material data "$name" not found!');
			return null;
		}
		return new MaterialData(raw);
	}

	public function getContext(name:String):MaterialContext {
		for (c in contexts) {
			if (c.raw.name == name) return c;
		}
		return null;
	}
}

class MaterialContext {
	public var raw:TMaterialContext;

	public var textures:Array<kha.Image> = null;

	public function new(raw:TMaterialContext) {
		this.raw = raw;

		if (raw.bind_textures != null &&
			raw.bind_textures.length > 0) {
			textures = [];
			for (i in 0...raw.bind_textures.length) {
				// TODO: make sure to store in the same order as shader texture units array
				var tex = raw.bind_textures[i];
				
				var image:kha.Image = Reflect.field(kha.Assets.images, tex.file);
				
				// Set mipmaps
				if (tex.mipmaps != null) {
					var mipmaps:Array<kha.Image> = [];
					for (name in tex.mipmaps) {
						mipmaps.push(Reflect.field(kha.Assets.images, name));
					}
					image.setMipmaps(mipmaps);
				}
				else if (tex.generate_mipmaps == true && image != null) {
					image.generateMipmaps(1000);
				}
				// Prevent creating mipmaps again
				tex.mipmaps = null;
				tex.generate_mipmaps = false;
				
				textures.push(image);
			}
		}
	}
	
	public function setTextureParameters(g:kha.graphics4.Graphics, textureIndex:Int, context:ShaderContext, unitIndex:Int) {
		// This function is called by MeshObject for samplers set using material context
		var tex = raw.bind_textures[textureIndex];
		if (tex.params_set == null) {
			context.setTextureParameters(g, unitIndex, tex);
			tex.params_set = true;
		}
	}
}
