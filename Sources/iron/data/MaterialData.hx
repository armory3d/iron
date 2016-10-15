package iron.data;

import haxe.ds.Vector;
import iron.data.SceneFormat;
import iron.data.ShaderData;
import iron.object.MeshObject;

class MaterialData extends Data {

	public var name:String;
	public var raw:TMaterialData;
	public var shader:ShaderData;

	public var contexts:Vector<MaterialContext> = null;

	public function new(raw:TMaterialData, done:MaterialData->Void) {
		super();

		this.raw = raw;
		this.name = raw.name;

		var shaderName:Array<String> = raw.shader.split("/");
		Data.getShader(shaderName[0], shaderName[1], raw.override_context, function(b:ShaderData) {
			shader = b;

			// Contexts have to be in the same order as in raw data for now
			contexts = new Vector(raw.contexts.length);
			var contextsLoaded = 0;

			for (i in 0...raw.contexts.length) {
				var c = raw.contexts[i];
				new MaterialContext(c, function(self:MaterialContext) {
					contexts[i] = self;
					contextsLoaded++;
					if (contextsLoaded == raw.contexts.length) done(this);
				});
			}
		});
	}

	public static function parse(file:String, name:String, done:MaterialData->Void) {
		Data.getSceneRaw(file, function(format:TSceneFormat) {
			var raw:TMaterialData = Data.getMaterialRawByName(format.material_datas, name);
			if (raw == null) {
				trace('Material data "$name" not found!');
				done(null);
			}
			new MaterialData(raw, done);
		});
	}

	public function getContext(name:String):MaterialContext {
		for (c in contexts) {
			// 'mesh' will fetch both 'mesh' and 'meshheight' contexts
			if (c.raw.name.substr(0, name.length) == name) return c;
		}
		return null;
	}
}

class MaterialContext {
	public var raw:TMaterialContext;
	public var textures:Vector<kha.Image> = null;
	static var num = 0;
	public var id = 0;

	public function new(raw:TMaterialContext, done:MaterialContext->Void) {
		this.raw = raw;
		id = num++;

		if (raw.bind_textures != null && raw.bind_textures.length > 0) {
			
			textures = new Vector(raw.bind_textures.length);
			var texturesLoaded = 0;

			for (i in 0...raw.bind_textures.length) {
				var tex = raw.bind_textures[i];
				// TODO: make sure to store in the same order as shader texture units array

				iron.data.Data.getImage(tex.file, function(image:kha.Image) {
					textures[i] = image;
					texturesLoaded++;

					// Set mipmaps
					if (tex.mipmaps != null) {
						var mipmaps:Array<kha.Image> = [];
						while (mipmaps.length < tex.mipmaps.length) mipmaps.push(null);
						var mipmapsLoaded = 0;

						for (j in 0...tex.mipmaps.length) {
							var name = tex.mipmaps[j];

							iron.data.Data.getImage(name, function(mipimg:kha.Image) {
								mipmaps[j] = mipimg;
								mipmapsLoaded++;

								if (mipmapsLoaded == tex.mipmaps.length) {
									image.setMipmaps(mipmaps);
									tex.mipmaps = null;
									tex.generate_mipmaps = false;

									if (texturesLoaded == raw.bind_textures.length) done(this);
								}
							});
						}
					}
					else if (tex.generate_mipmaps == true && image != null) {
						image.generateMipmaps(1000);
						tex.mipmaps = null;
						tex.generate_mipmaps = false;

						if (texturesLoaded == raw.bind_textures.length) done(this);
					}
					else if (texturesLoaded == raw.bind_textures.length) done(this);
				
				}, false, tex.format != null ? tex.format : 'RGBA32');
			}
		}
		else done(this);
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
