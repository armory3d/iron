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
	public var materialConstants:Array<ConstantLocation> = [];
	public var textureUnits:Array<TextureUnit> = [];

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

		for (c in resource.material_constants) {
			addMaterialConstant(c.id);
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

	function addConstant(s:String) {
		constants.push(program.getConstantLocation(s));
	}

	function addMaterialConstant(s:String) {
		materialConstants.push(program.getConstantLocation(s));
	}

	function addTexture(s:String) {
		textureUnits.push(program.getTextureUnit(s));
	}

	public static function createDefaults() {
		defaultStructure = new VertexStructure();
		defaultStructure.add("pos", VertexData.Float3);
		defaultStructure.add("tex", VertexData.Float2);
		defaultStructure.add("nor", VertexData.Float3);
		defaultStructure.add("col", VertexData.Float4);
		defaultStructureLength = 12;

		// Default shaders
		var res:TShaderResource = {
            id: "model",
            vertex_shader: "model.vert",
            fragment_shader: "model.frag",
            constants: [
                {
                    id: "M",
                    type: "mat4",
                    value: "_modelMatrix"
                },
                {
                    id: "V",
                    type: "mat4",
                    value: "_viewMatrix"
                },
                {
                    id: "P",
                    type: "mat4",
                    value: "_projectionMatrix"
                },
                {
                    id: "light",
                    type: "vec3",
                    value: "_lighPosition"
                },
                {
                    id: "eye",
                    type: "vec3",
                    value: "_cameraPosition"
                }
            ],
            material_constants: [
                {
                    id: "diffuseColor",
                    type: "vec4",
                },
                {
                    id: "roughness",
                    type: "float"
                },
                {
                    id: "lighting",
                    type: "bool"
                },
                {
                    id: "receiveShadow",
                    type: "bool"
                },
                {
                    id: "texturing",
                    type: "bool"
                }
            ],
            texture_units: [
                {
                    id: "stex"
                },
                {
                    id: "shadowMap",
                    value: "_shadowMap"
                }
            ]
        };

        Resource.cacheShader(res.id, new ShaderResource(res));
	}
}
