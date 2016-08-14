package iron.resource;

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
import iron.resource.SceneFormat;

class ShaderResource extends Resource {

	public var resource:TShaderResource;

	var structure:VertexStructure;
	var structureLength = 0;

	public var contexts:Array<ShaderContext> = [];

	public function new(resource:TShaderResource, overrideContext:TShaderOverride = null) {
		super();

		this.resource = resource;

		parseVertexStructure();

		for (c in resource.contexts) {
			// Render pipeline might not use all shaders contexts, skip context if shader is not found
			var fragName = StringTools.replace(c.fragment_shader, ".", "_");
			if (Reflect.field(kha.Shaders, fragName) == null) {
				continue;
			}
			
			contexts.push(new ShaderContext(c, structure, overrideContext));
		}
	}

	public function delete() {
		for (c in contexts) c.delete();
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

	public static function parse(name:String, id:String, overrideContext:TShaderOverride = null):ShaderResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TShaderResource = Resource.getShaderResourceById(format.shader_resources, id);
		if (resource == null) {
			trace('Shader resource "$id" not found!');
			return null;
		}
		return new ShaderResource(resource, overrideContext);
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

	public function new(resource:TShaderContext, structure:VertexStructure, overrideContext:TShaderOverride = null) {
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
		pipeState.depthMode = getCompareMode(resource.compare_mode);
		
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
		pipeState.cullMode = getCullMode(resource.cull_mode);
		
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
		
		// Override specified values
		if (overrideContext != null) {
			if (overrideContext.cull_mode != null) {
				pipeState.cullMode = getCullMode(overrideContext.cull_mode);
			}
		}

		pipeState.compile();

		for (c in resource.constants) {
			addConstant(c);
		}

		for (tu in resource.texture_units) {
			addTexture(tu);
		}
	}

	public function delete() {
		pipeState.fragmentShader.delete();
		pipeState.vertexShader.delete();
		pipeState.delete();
	}

	function getCompareMode(s:String):CompareMode {
		switch(s) {
		case "always": return CompareMode.Always;
		case "never": return CompareMode.Never;
		case "less": return CompareMode.Less;
		case "less_equal": return CompareMode.LessEqual;
		case "greater": return CompareMode.Greater;
		case "greater_equal": return CompareMode.GreaterEqual;
		case "equal": return CompareMode.Equal;
		case "not_equal": return CompareMode.NotEqual;
		default: return CompareMode.Less;
		}
	}

	function getCullMode(s:String):CullMode {
		switch(s) {
		case "none": return CullMode.None;
		case "clockwise": return CullMode.Clockwise;
		default: return CullMode.CounterClockwise;
		}			
	}

	function getBlendingOperation(s:String):BlendingOperation {
		switch(s) {
		case "add": return BlendingOperation.Add;
		case "substract": return BlendingOperation.Subtract;
		case "reverse_substract": return BlendingOperation.ReverseSubtract;
		case "min": return BlendingOperation.Min;
		case "max": return BlendingOperation.Max;
		default: return BlendingOperation.Add;
		}
	}
	
	function getBlendingFactor(s:String):BlendingFactor {
		switch(s) {
		case "blend_one": return BlendingFactor.BlendOne;
		case "blend_zero": return BlendingFactor.BlendZero;
		case "source_alpha": return BlendingFactor.SourceAlpha;
		case "destination_alpha": return BlendingFactor.DestinationAlpha;
		case "inverse_source_alpha": return BlendingFactor.InverseSourceAlpha;
		case "inverse_destination_alpha": return BlendingFactor.InverseDestinationAlpha;
		case "source_color": return BlendingFactor.SourceColor;
		case "destination_color": return BlendingFactor.DestinationColor;
		case "inverse_source_color": return BlendingFactor.InverseSourceColor;
		case "inverse_destination_color": return BlendingFactor.InverseDestinationColor;
		default: return BlendingFactor.Undefined;
		}
	}

	function getTextureAddresing(s:String):TextureAddressing {
		switch(s) {
		case "repeat": return TextureAddressing.Repeat;
		case "mirror": return TextureAddressing.Mirror;
		default: return TextureAddressing.Clamp;
		}
	}

	function getTextureFilter(s:String):TextureFilter {
		switch(s) {
		case "point": return TextureFilter.PointFilter;
		case "linear": return TextureFilter.LinearFilter;
		default: return TextureFilter.AnisotropicFilter;
		}	
	}

	function getMipmapFilter(s:String):MipMapFilter {
		switch(s) {
		case "no": return MipMapFilter.NoMipFilter;
		case "point": return MipMapFilter.PointMipFilter;
		default: return MipMapFilter.LinearMipFilter;
		}
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
