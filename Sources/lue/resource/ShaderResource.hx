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

	public var resource:TShaderResource;

	static var defaultStructure:VertexStructure = null;

	public var contexts:Array<ShaderContext> = [];

	public function new(resource:TShaderResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}
		this.resource = resource;

		for (c in resource.contexts) {
			contexts.push(new ShaderContext(c));
		}
	}

	public static function parse(name:String, id:String):ShaderResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TShaderResource = Resource.getShaderResourceById(format.shader_resources, id);
		return new ShaderResource(resource);
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

	public static function createScreenAlignedQuadStructure():VertexStructure {
		var structure = new VertexStructure();
        structure.add("pos", VertexData.Float2);
        return structure;
	}

	public static function getScreenAlignedQuadStructureLength():Int {
		return 2;
	}

	public function getContext(id:String):ShaderContext {
		for (c in contexts) {
			if (c.resource.id == id) return c;
		}
		return null;
	}
}

class ShaderContext {
	public var resource:TShaderContext;

	public var program:Program;
	public var constants:Array<ConstantLocation> = [];
	public var textureUnits:Array<TextureUnit> = [];

	public function new(resource:TShaderContext) {
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

	function link() {
		program.link(ShaderResource.getDefaultStructure());
	}

	function addConstant(s:String) {
		constants.push(program.getConstantLocation(s));
	}

	function addTexture(s:String) {
		textureUnits.push(program.getTextureUnit(s));
	}
}
