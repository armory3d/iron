package lue.resource;

import kha.graphics4.Program;
import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureUnit;
import kha.graphics4.FragmentShader;
import kha.graphics4.VertexShader;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import kha.Loader;
import lue.resource.importer.SceneFormat;

class ShaderResource extends Resource {

	public static var defaultStructure:VertexStructure;
	public static var defaultStructureLength:Int;

	public var resource:TShaderResource;

	public var program:Program;
	public var constants:Array<ConstantLocation> = [];
	public var textures:Array<TextureUnit> = [];

	public function new(resource:TShaderResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}
		this.resource = resource;

		var fragmentShader = new FragmentShader(Loader.the.getShader(resource.fragment_shader));
		var vertexShader = new VertexShader(Loader.the.getShader(resource.vertex_shader));
	
		program = new Program();
		program.setFragmentShader(fragmentShader);
		program.setVertexShader(vertexShader);
		link();

		for (c in resource.constants) {
			addConstant(c.id);
		}

		for (tu in resource.texture_units) {
			addTexture(tu.id);
		}
	}

	public static function parse(name:String, id:String):ShaderResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TShaderResource = Resource.getShaderResourceById(format.shader_resources, id);
		return new ShaderResource(resource);
	}

	public function link() {
		program.link(defaultStructure);
	}

	public function addConstant(s:String) {
		constants.push(program.getConstantLocation(s));
	}

	public function addTexture(s:String):TextureUnit {
		var tu:TextureUnit = program.getTextureUnit(s);
		textures.push(tu);
		return tu;
	}

	public static function createDefaults() {
		defaultStructure = new VertexStructure();
		defaultStructure.add("pos", VertexData.Float3);
		defaultStructure.add("tex", VertexData.Float2);
		defaultStructure.add("nor", VertexData.Float3);
		defaultStructure.add("col", VertexData.Float4);
		defaultStructureLength = 12;

		// Mesh
		var res:TShaderResource = {
            id: "model",
            vertex_shader: "model.vert",
            fragment_shader: "model.frag",
            constants: [
                {
                    id: "M"
                },
                {
                    id: "V"
                },
                {
                    id: "P"
                },
                {
                    id: "dbMVP"
                },
                {
                    id: "light"
                },
                {
                    id: "eye"
                },
                {
                    id: "diffuseColor"
                },
                {
                    id: "texturing"
                },
                {
                    id: "lighting"
                },
                {
                    id: "receiveShadow"
                },
                {
                    id: "roughness"
                }
            ],
            texture_units: [
                {
                    id: "stex"
                },
                {
                    id: "shadowMap"
                }
            ]
        };

        Resource.cacheShader(res.id, new ShaderResource(res));
	}
}
