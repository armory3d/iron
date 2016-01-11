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
import kha.graphics4.BlendingOperation;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.MipMapFilter;
import lue.resource.importer.SceneFormat;

class ShaderResource extends Resource {

	public var resource:TShaderResource;

	var structure:VertexStructure;
	var structureLength:Int = 0;

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

	// Used by ModelResource
	public static function getVertexStructure(pos = false, nor = false, tex = false, col = false, tan = false, bone = false, weight = false):VertexStructure {
		var structure = new VertexStructure();
		if (pos) structure.add("pos", VertexData.Float3);
		if (nor) structure.add("nor", VertexData.Float3);
		if (tex) structure.add("tex", VertexData.Float2);
		if (col) structure.add("col", VertexData.Float4);
		if (tan) structure.add("tan", VertexData.Float3);
		if (bone) structure.add("bone", VertexData.Float4);
		if (weight) structure.add("weight", VertexData.Float4);
		return structure;
	}
	public static function getVertexStructureLength(pos = false, nor = false, tex = false, col = false, tan = false, bone = false, weight = false):Int {
		var length = 0;
		if (pos) length += 3;
		if (nor) length += 3;
		if (tex) length += 2;
		if (col) length += 4;
		if (tan) length += 3;
		if (bone) length += 4;
		if (weight) length += 4;
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

		// Instancing
		if (resource.vertex_shader.indexOf("_Instancing") != -1) {
			var instStruct = new VertexStructure();
        	instStruct.add("off", VertexData.Float3);
        	pipeState.inputLayout = [structure, instStruct];
		}
		// Regular
		else {
			pipeState.inputLayout = [structure];
		}
		
		// Depth
		pipeState.depthWrite = resource.depth_write;
		
		if (resource.compare_mode == "always") { // TODO: parse from CompareMode enum
        	pipeState.depthMode = CompareMode.Always;
        }
        else if (resource.compare_mode == "less") {
        	pipeState.depthMode = CompareMode.Less;
        }

		// Cull
        if (resource.cull_mode == "none") {
        	pipeState.cullMode = CullMode.None;
        }
        else if (resource.cull_mode == "counter_clockwise") {
        	pipeState.cullMode = CullMode.CounterClockwise;
        }
        else {
        	pipeState.cullMode = CullMode.Clockwise;	
        }
		
		// Blending
		pipeState.blendSource = getBlendingOperation(resource.blend_source);
		pipeState.blendDestination = getBlendingOperation(resource.blend_destination);

		pipeState.fragmentShader = Reflect.field(kha.Shaders, StringTools.replace(resource.fragment_shader, ".", "_"));
		pipeState.vertexShader = Reflect.field(kha.Shaders, StringTools.replace(resource.vertex_shader, ".", "_"));
		pipeState.compile();

		for (c in resource.constants) {
			addConstant(c);
		}

		for (tu in resource.texture_units) {
			addTexture(tu);
		}
	}

	function getBlendingOperation(s:String):BlendingOperation {
		if (s == "blend_one")
			return BlendingOperation.BlendOne;
		else if (s == "blend_zero")
			return BlendingOperation.BlendZero;
		else if (s == "source_alpha")
			return BlendingOperation.SourceAlpha;
		else if (s == "inverse_source_alpha")
			return BlendingOperation.InverseSourceAlpha;
		else
			return BlendingOperation.Undefined;
	}

	function getTextureAddresing(s:String):TextureAddressing {
		if (s == "repeat")
			return TextureAddressing.Repeat;
		else if (s == "mirror")
			return TextureAddressing.Mirror;
		else
			return TextureAddressing.Clamp;
	}

	function getTextureFilter(s:String):TextureFilter {
		if (s == "point")
			return TextureFilter.PointFilter;
		else if (s == "linear")
			return TextureFilter.LinearFilter;
		else
			return TextureFilter.AnisotropicFilter;
	}

	function getMipMapFilter(s:String):MipMapFilter {
		if (s == "no")
			return MipMapFilter.NoMipFilter;
		else if (s == "point")
			return MipMapFilter.PointMipFilter;
		else
			return MipMapFilter.LinearMipFilter;
	}

	function addConstant(c:TShaderConstant) {
		constants.push(pipeState.getConstantLocation(c.id));
	}

	function addTexture(tu:TTextureUnit) {
		var unit = pipeState.getTextureUnit(tu.id);
		textureUnits.push(unit);

		// TODO: set when graphics object is available
		/*
		graphics.setTextureParameters(unit,
			tu.u_addressing == null ? TextureAddressing.Repeat : getTextureAddresing(tu.u_addressing),
			tu.v_addressing == null ? TextureAddressing.Repeat : getTextureAddresing(tu.v_addressing),
			tu.min_filter == null ? TextureFilter.PointFilter : getTextureFilter(tu.min_filter),
			tu.mag_filter == null ? TextureFilter.PointFilter : getTextureFilter(tu.mag_filter),
			tu.mipmap == null ? MipMapFilter.NoMipFilter : getMipMapFilter(tu.mipmap));
		*/
	}
}
