package lue.resource;

typedef TSceneFormat = {
	@:optional var geometry_resources:Array<TGeometryResource>;
	@:optional var light_resources:Array<TLightResource>;
	@:optional var camera_resources:Array<TCameraResource>;
	@:optional var material_resources:Array<TMaterialResource>;
	@:optional var particle_resources:Array<TParticleResource>;
	@:optional var shader_resources:Array<TShaderResource>;
	@:optional var pipeline_resources:Array<TPipelineResource>;
	@:optional var speaker_resources:Array<TSpeakerResource>;
	@:optional var nodes:Array<TNode>;
}

typedef TGeometryResource = {
	var id:String;
	var mesh:TMesh;
}

typedef TMesh = {
	var primitive:String;
	var vertex_arrays:Array<TVertexArray>;
	var index_arrays:Array<TIndexArray>;
	@:optional var static_usage:Bool;
	@:optional var skin:TSkin;
	@:optional var instance_offsets:Array<Float>;
}

typedef TSkin = {
	var transform:TTransform;
	var skeleton:TSkeleton;
	var bone_count_array:Array<Int>;
	var bone_index_array:Array<Int>;
	var bone_weight_array:Array<Float>;
}

typedef TSkeleton = {
	var bone_ref_array:Array<String>;
	var transforms:Array<Array<Float>>; // size = 16
}

typedef TVertexArray = {
	var attrib:String;
	var size:Int;
	var values:Array<Float>;
}

typedef TIndexArray = {
	var size:Int;
	var values:Array<Int>;
	var material:Int;
}

typedef TLightResource = {
	var id:String;
	var color:Array<Float>;
}

typedef TCameraResource = {
	var id:String;
	var clear_color:Array<Float>;
	var near_plane:Float;
	var far_plane:Float;
	@:optional var frustum_culling:Bool;
	@:optional var draw_calls_sort:String;
	var pipeline:String;
	var type:String;
}

typedef TMaterialResource = {
	var id:String;
	var shader:String;
	@:optional var cast_shadow:Bool;
	var contexts:Array<TMaterialContext>;
}

typedef TMaterialContext = {
	var id:String;
	var bind_constants:Array<TBindConstant>;
	var bind_textures:Array<TBindTexture>;
}

typedef TBindConstant = {
	var id:String;
	@:optional var vec4:Array<Float>;
	@:optional var vec3:Array<Float>;
	@:optional var vec2:Array<Float>;
	@:optional var float:Float;
	@:optional var bool:Bool;
}

typedef TBindTexture = {
	var id:String;
	var name:String;
	@:optional var generate_mipmaps:Bool;
	@:optional var mipmaps:Array<String>; // Reference image names
	@:optional var u_addressing:String;
	@:optional var v_addressing:String;
	@:optional var min_filter:String;
	@:optional var mag_filter:String;
	@:optional var mipmap_filter:String;
	@:optional var params_set:Bool; // Prevents setting texture params
	@:optional var source:String; // file, movie 
}

typedef TShaderResource = {
	var id:String;
	var vertex_structure:Array<TVertexData>;
	var contexts:Array<TShaderContext>;
}

typedef TVertexData = {
	var name:String;
	var size:Int;
}

typedef TShaderContext = {
	var id:String;
	var depth_write:Bool;
	var compare_mode:String;
	var cull_mode:String;
	@:optional var blend_source:String;
	@:optional var blend_destination:String;
	@:optional var blend_operation:String;
	@:optional var alpha_blend_source:String;
	@:optional var alpha_blend_destination:String;
	@:optional var alpha_blend_operation:String;
	@:optional var stencil_mode:String;
	@:optional var stencil_pass:String;
	@:optional var stencil_fail:String;
	@:optional var stencil_reference_value:Int;
	@:optional var stencil_read_mask:Int;
	@:optional var stencil_write_mask:Int;
	var vertex_shader:String;
	var fragment_shader:String;
	var constants:Array<TShaderConstant>;
	var texture_units:Array<TTextureUnit>;
}

typedef TShaderConstant = {
	var id:String;
	var type:String;
	@:optional var link:String;
	@:optional var vec4:Array<Float>;
	@:optional var vec3:Array<Float>;
	@:optional var float:Float;
	@:optional var bool:Bool;
}

typedef TTextureUnit = {
	var id:String;
	@:optional var link:String;
}

typedef TPipelineResource = {
	var id:String;
	var render_targets:Array<TPipelineRenderTarget>;
	var stages:Array<TPipelineStage>;
}

typedef TPipelineRenderTarget = {
	var id:String;
	var width:Int;
	var height:Int;
	@:optional var format:String;
	@:optional var depth_buffer:Bool;
	@:optional var stencil_buffer:Bool;
	@:optional var color_buffers:Int;
	@:optional var ping_pong:Bool;
}

typedef TPipelineStage = {
	var command:String;
	@:optional var params:Array<String>;
	@:optional var returns_true:Array<TPipelineStage>; // Nested commands
	@:optional var returns_false:Array<TPipelineStage>;
}

typedef TSpeakerResource = {
	var id:String;
	var sound:String;
}

typedef TParticleResource = {
	var id:String;
	var count:Int;
	var lifetime:Float;
	var normal_factor:Float;
	var object_align_factor:Array<Float>;
	var factor_random:Float;
}

typedef TNode = {
	var type:String;
	var id:String;
	var object_ref:String;
	var material_refs:Array<String>;
	var particle_refs:Array<TParticleReference>;
	var transform:TTransform;
	var nodes:Array<TNode>;
	var traits:Array<TTrait>;
	@:optional var dimensions:Array<Float>; // Geometry nodes
	@:optional var animation:TAnimation;
	@:optional var bones_ref:String;
	@:optional var parent:TNode;
	@:optional var visible:Bool;
}

typedef TParticleReference = {
	var id:String;
	var particle:String;
	var seed:Int;
}

typedef TTrait = {
	var type:String;
	var class_name:String;
	@:optional var parameters:Array<Dynamic>;
}

typedef TTransform = {
	@:optional var target:String;
	var values:Array<Float>;
}

typedef TAnimation = {
	//var tracks:Array<TTrack>;
	var track:TTrack;
}

typedef TTrack = {
	var target:String;
	var time:TTime;
	var value:TValue;
}

typedef TTime = {
	var values:Array<Float>;
}

typedef TValue = {
	var values:Array<Array<Float>>;
}

// Raw shader resource
/*
typedef TRawShader = {
	var contexts:Array<TRawContext>;
}

typedef TRawContext = {
	var id:String;
	var params:Array<TRawParam>;
	var links:Array<TRawLink>;
	var vertex_shader:String;
	var fragment_shader:String;
}

typedef TRawParam = {
	var id:String;
	var value:String;
}

typedef TRawLink = {
	var id:String;
	var link:String;
	@:optional var ifdef:Array<String>;
}
*/
