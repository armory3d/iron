package lue.resource;

import kha.graphics4.PipelineState;
import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureUnit;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import kha.graphics4.StencilAction;
import kha.graphics4.CompareMode;
import kha.graphics4.CullMode;
import kha.graphics4.BlendingOperation;
import kha.graphics4.BlendingFactor;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.MipMapFilter;
import lue.resource.SceneFormat;

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
			// Render pipeline might not use all shaders contexts, skip context if shader is not found
			var fragName = StringTools.replace(c.fragment_shader, ".", "_");
			if (Reflect.field(kha.Shaders, fragName) == null) {
				continue;
			}
			
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
	
	// Usable by decal
	public static function createDecalStructure():VertexStructure {
		var structure = new VertexStructure();
        structure.add("pos", VertexData.Float3);
        return structure;
	}
	public static function getDecalStructureLength():Int {
		return 3;
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
		else if (resource.compare_mode == "less_equal") {
        	pipeState.depthMode = CompareMode.LessEqual;
        }
		
		// Stencil
		if (resource.stencil_mode != null) {
			if (resource.stencil_mode == "always")
				pipeState.stencilMode = CompareMode.Always;
			else if (resource.stencil_mode == "equal")
				pipeState.stencilMode = CompareMode.Equal;
			else if (resource.stencil_mode == "not_equal")
				pipeState.stencilMode = CompareMode.NotEqual;
		}
		if (resource.stencil_pass != null) {
			if (resource.stencil_pass == "replace")
				pipeState.stencilBothPass = StencilAction.Replace;
			else if (resource.stencil_pass == "keep")
				pipeState.stencilBothPass = StencilAction.Keep;
		}
		if (resource.stencil_fail != null && resource.stencil_fail == "keep") {
			pipeState.stencilDepthFail = StencilAction.Keep;
			pipeState.stencilFail = StencilAction.Keep;
		}
		if (resource.stencil_reference_value != null) {
			pipeState.stencilReferenceValue = resource.stencil_reference_value;
		}	
		// pipeState.stencilReadMask = resource.stencil_read_mask;
		// pipeState.stencilWriteMask = resource.stencil_write_mask;

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
		if (resource.blend_source != null) pipeState.blendSource = getBlendingFactor(resource.blend_source);
		if (resource.blend_destination != null) pipeState.blendDestination = getBlendingFactor(resource.blend_destination);
		if (resource.blend_operation != null) pipeState.blendOperation = getBlendingOperation(resource.blend_operation);
		if (resource.alpha_blend_source != null) pipeState.alphaBlendSource = getBlendingFactor(resource.alpha_blend_source);
		if (resource.alpha_blend_destination != null) pipeState.alphaBlendDestination = getBlendingFactor(resource.alpha_blend_destination);
		if (resource.alpha_blend_operation != null) pipeState.alphaBlendOperation = getBlendingOperation(resource.alpha_blend_operation);

		// Color write mask
		if (resource.color_write_red != null) pipeState.colorWriteMaskRed = resource.color_write_red;
		if (resource.color_write_green != null) pipeState.colorWriteMaskGreen = resource.color_write_green;
		if (resource.color_write_blue != null) pipeState.colorWriteMaskBlue = resource.color_write_blue;
		if (resource.color_write_alpha != null) pipeState.colorWriteMaskAlpha = resource.color_write_alpha;

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
		if (s == "add")
			return BlendingOperation.Add;
		else if (s == "substract")
			return BlendingOperation.Subtract;
		else if (s == "reverse_substract")
			return BlendingOperation.ReverseSubtract;
		else if (s == "min")
			return BlendingOperation.Min;
		else if (s == "max")
			return BlendingOperation.Max;
		else
			return BlendingOperation.Add;
	}
	
	function getBlendingFactor(s:String):BlendingFactor {
		if (s == "blend_one")
			return BlendingFactor.BlendOne;
		else if (s == "blend_zero")
			return BlendingFactor.BlendZero;
		else if (s == "source_alpha")
			return BlendingFactor.SourceAlpha;
		else if (s == "destination_alpha")
			return BlendingFactor.DestinationAlpha;
		else if (s == "inverse_source_alpha")
			return BlendingFactor.InverseSourceAlpha;
		else if (s == "inverse_destination_alpha")
			return BlendingFactor.InverseDestinationAlpha;
		else
			return BlendingFactor.Undefined;
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

	function getMipmapFilter(s:String):MipMapFilter {
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
	}
	
	public function setTextureParameters(g:kha.graphics4.Graphics, unitIndex:Int, tex:TBindTexture) {
		// This function is called for samplers set using material context		
		var unit = textureUnits[unitIndex];
		g.setTextureParameters(unit,
			tex.u_addressing == null ? TextureAddressing.Repeat : getTextureAddresing(tex.u_addressing),
			tex.v_addressing == null ? TextureAddressing.Repeat : getTextureAddresing(tex.v_addressing),
			tex.min_filter == null ? TextureFilter.LinearFilter : getTextureFilter(tex.min_filter),
			tex.mag_filter == null ? TextureFilter.LinearFilter : getTextureFilter(tex.mag_filter),
			tex.mipmap_filter == null ? MipMapFilter.NoMipFilter : getMipmapFilter(tex.mipmap_filter));
	}
}
