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

	static var defaultStructure:VertexStructure = null;

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

		var fragmentShader = new FragmentShader(Loader.the.getShader(resource.contexts[0].fragment_shader));
		var vertexShader = new VertexShader(Loader.the.getShader(resource.contexts[0].vertex_shader));
	
		program = new Program();
		program.setFragmentShader(fragmentShader);
		program.setVertexShader(vertexShader);
		link();

		for (c in resource.contexts[0].constants) {
			addConstant(c.id);
		}

		for (c in resource.contexts[0].material_constants) {
			addMaterialConstant(c.id);
		}

		for (tu in resource.contexts[0].texture_units) {
			addTexture(tu.id);
		}
	}

	public static function parse(name:String, id:String):ShaderResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TShaderResource = Resource.getShaderResourceById(format.shader_resources, id);
		return new ShaderResource(resource);
	}

	public function link() {
		program.link(getDefaultStructure());
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

	static function createDefaultStructure():VertexStructure {
		var structure = new VertexStructure();
        structure.add("pos", VertexData.Float3);
        structure.add("tex", VertexData.Float2);
        structure.add("nor", VertexData.Float3);
        structure.add("col", VertexData.Float4);
        return structure;
	}

	public static function getDefaultStructure():VertexStructure {
		if (defaultStructure == null) defaultStructure = createDefaultStructure();
		return defaultStructure;
	}

	public static function getDefaultStructureLength():Int {
		return 12;
	}
}
