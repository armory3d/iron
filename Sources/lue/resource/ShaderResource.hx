package lue.resource;

import kha.graphics4.PipelineState;
import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureUnit;
import kha.graphics4.FragmentShader;
import kha.graphics4.VertexShader;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import kha.graphics4.CompareMode;
import kha.graphics4.CullMode;
import lue.resource.importer.SceneFormat;

class ShaderResource extends Resource {

	public var resource:TShaderResource;

	var structure:VertexStructure;
	var structureLength:Int;

	public var contexts:Array<ShaderContext> = [];

	public function new(resource:TShaderResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}
		this.resource = resource;

		parseVertexStructure();

		for (c in resource.contexts) {
			contexts.push(new ShaderContext(c, structure));
		}
	}

	function sizeToVD(size:Int):VertexData {
		if (size == 1) return VertexData.Float1;
		else if (size == 2) return VertexData.Float2;
		else if (size == 3) return VertexData.Float3;
		else if (size == 4) return VertexData.Float4;
		return null;
	}
	function parseVertexStructure() {
		structure = new VertexStructure();
		for (data in resource.vertex_structure) {
			structure.add(data.name, sizeToVD(data.size));
			structureLength += data.size;
		}
	}

	public static function parse(name:String, id:String):ShaderResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TShaderResource = Resource.getShaderResourceById(format.shader_resources, id);
		return new ShaderResource(resource);
	}

	// Usable by ModelResource
	public static function getVertexStructure(pos = false, tex = false, nor = false, col = false, tan = false, bitan = false):VertexStructure {
		var structure = new VertexStructure();
		if (pos) structure.add("pos", VertexData.Float3);
		if (tex) structure.add("tex", VertexData.Float2);
		if (nor) structure.add("nor", VertexData.Float3);
		if (col) structure.add("col", VertexData.Float4);
		if (tan) structure.add("tan", VertexData.Float3);
		if (bitan) structure.add("bitan", VertexData.Float3);
		return structure;
	}
	public static function getVertexStructureLength(pos = false, tex = false, nor = false, col = false, tan = false, bitan = false):Int {
		var length = 0;
		if (pos) length += 3;
		if (tex) length += 2;
		if (nor) length += 3;
		if (col) length += 4;
		if (tan) length += 3;
		if (bitan) length += 3;
		return length;
	}

	// Usable by fullscreen quad
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

	public var pipeState:PipelineState;
	public var constants:Array<ConstantLocation> = [];
	public var textureUnits:Array<TextureUnit> = [];

	public function new(resource:TShaderContext, structure:VertexStructure) {
		this.resource = resource;
	
		pipeState = new PipelineState();
		pipeState.inputLayout = [structure];
		
		pipeState.depthWrite = resource.depth_write;
		
		if (resource.compare_mode == "always") { // TODO: parse from CompareMode enum
        	pipeState.depthMode = CompareMode.Always;
        }
        else if (resource.compare_mode == "less") {
        	pipeState.depthMode = CompareMode.Less;
        }

        if (resource.cull_mode == "none") {
        	pipeState.cullMode = CullMode.None;
        }
        else if (resource.cull_mode == "counter_clockwise") {
        	pipeState.cullMode = CullMode.CounterClockwise;
        }
        else {
        	pipeState.cullMode = CullMode.Clockwise;	
        }

		pipeState.fragmentShader = Reflect.field(kha.Shaders, StringTools.replace(resource.fragment_shader, ".", "_"));
		pipeState.vertexShader = Reflect.field(kha.Shaders, StringTools.replace(resource.vertex_shader, ".", "_"));
		pipeState.compile();

		for (c in resource.constants) {
			addConstant(c.id);
		}

		for (tu in resource.texture_units) {
			addTexture(tu.id);
		}
	}

	function addConstant(s:String) {
		constants.push(pipeState.getConstantLocation(s));
	}

	function addTexture(s:String) {
		textureUnits.push(pipeState.getTextureUnit(s));
	}
}
