package iron.data;

typedef TSceneFormat = {
// @:structInit class TSceneFormat {
	@:optional public var mesh_datas:Array<TMeshData>;
	@:optional public var lamp_datas:Array<TLampData>;
	@:optional public var camera_datas:Array<TCameraData>;
	@:optional public var material_datas:Array<TMaterialData>;
	@:optional public var particle_datas:Array<TParticleData>;
	@:optional public var shader_datas:Array<TShaderData>;
	@:optional public var pipeline_datas:Array<TPipelineData>;
	@:optional public var speaker_datas:Array<TSpeakerData>;
	@:optional public var world_datas:Array<TWorldData>;
	@:optional public var world_ref:String;
	@:optional public var objects:Array<TObj>;
	@:optional public var gravity:Array<Float>;
}

typedef TMeshData = {
// @:structInit class TMeshData {
	public var name:String;
	public var mesh:TMesh;
}

typedef TMesh = {
// @:structInit class TMesh {
	public var primitive:String;
	public var vertex_arrays:Array<TVertexArray>;
	public var index_arrays:Array<TIndexArray>;
	@:optional public var static_usage:Null<Bool>;
	@:optional public var skin:TSkin;
	@:optional public var instance_offsets:Array<Float>;
}

typedef TSkin = {
// @:structInit class TSkin {
	public var transform:TTransform;
	public var skeleton:TSkeleton;
	public var bone_count_array:Array<Int>;
	public var bone_index_array:Array<Int>;
	public var bone_weight_array:Array<Float>;
}

typedef TSkeleton = {
// @:structInit class TSkeleton {
	public var bone_ref_array:Array<String>;
	public var transforms:Array<Array<Float>>; // size = 16
}

typedef TVertexArray = {
// @:structInit class TVertexArray {
	public var attrib:String;
	public var size:Int;
	public var values:Array<Float>;
}

typedef TIndexArray = {
// @:structInit class TIndexArray {
	public var size:Int;
	public var values:Array<Int>;
	public var material:Int;
}

typedef TLampData = {
// @:structInit class TLampData {
	public var name:String;
	public var type:String; // Sun, point, spot
	public var color:Array<Float>;
	public var strength:Float;
	public var cast_shadow:Bool;
	public var near_plane:Float;
	public var far_plane:Float;
	public var fov:Float;
	public var shadows_bias:Float;
	@:optional public var spot_size:Null<Float>;
	@:optional public var spot_blend:Null<Float>;
}

typedef TCameraData = {
// @:structInit class TCameraData {
	public var name:String;
	public var clear_color:Array<Float>;
	public var near_plane:Float;
	public var far_plane:Float;
	public var fov:Float;
	public var pipeline:String;
	public var type:String;
	@:optional public var frustum_culling:Bool;
}

typedef TMaterialData = {
// @:structInit class TMaterialData {
	public var name:String;
	public var shader:String;
	public var contexts:Array<TMaterialContext>;
	@:optional public var skip_context:String;
	@:optional public var override_context:TShaderOverride;
}

typedef TShaderOverride = {
	@:optional public var cull_mode:String;
}

typedef TMaterialContext = {
// @:structInit class TMaterialContext {
	public var name:String;
	@:optional public var bind_constants:Array<TBindConstant>;
	@:optional public var bind_textures:Array<TBindTexture>;
}

typedef TBindConstant = {
// @:structInit class TBindConstant {
	public var name:String;
	@:optional public var vec4:Array<Float>;
	@:optional public var vec3:Array<Float>;
	@:optional public var vec2:Array<Float>;
	@:optional public var float:Float;
	@:optional public var bool:Bool;
}

typedef TBindTexture = {
// @:structInit class TBindTexture {
	public var name:String;
	public var file:String;
	@:optional public var generate_mipmaps:Bool;
	@:optional public var mipmaps:Array<String>; // Reference image names
	@:optional public var u_addressing:String;
	@:optional public var v_addressing:String;
	@:optional public var min_filter:String;
	@:optional public var mag_filter:String;
	@:optional public var mipmap_filter:String;
	@:optional public var params_set:Null<Bool>; // Prevents setting texture params
	@:optional public var source:String; // file, movie 
}

typedef TShaderData = {
// @:structInit class TShaderData {
	public var name:String;
	public var vertex_structure:Array<TVertexData>;
	public var contexts:Array<TShaderContext>;
}

typedef TVertexData = {
// @:structInit class TVertexData {
	public var name:String;
	public var size:Int;
}

typedef TShaderContext = {
// @:structInit class TShaderContext {
	public var name:String;
	public var depth_write:Bool;
	public var compare_mode:String;
	public var cull_mode:String;
	@:optional public var blend_source:String;
	@:optional public var blend_destination:String;
	@:optional public var blend_operation:String;
	@:optional public var alpha_blend_source:String;
	@:optional public var alpha_blend_destination:String;
	@:optional public var alpha_blend_operation:String;
	@:optional public var stencil_mode:String;
	@:optional public var stencil_pass:String;
	@:optional public var stencil_fail:String;
	@:optional public var stencil_reference_value:Null<Int>;
	@:optional public var stencil_read_mask:Int;
	@:optional public var stencil_write_mask:Int;
	@:optional public var color_write_red:Null<Bool>;
	@:optional public var color_write_green:Null<Bool>;
	@:optional public var color_write_blue:Null<Bool>;
	@:optional public var color_write_alpha:Null<Bool>;
	public var vertex_shader:String;
	public var fragment_shader:String;
	public var constants:Array<TShaderConstant>;
	public var texture_units:Array<TTextureUnit>;
}

typedef TShaderConstant = {
// @:structInit class TShaderConstant {
	public var name:String;
	public var type:String;
	@:optional public var link:String;
	@:optional public var vec4:Array<Float>;
	@:optional public var vec3:Array<Float>;
	@:optional public var float:Float;
	@:optional public var bool:Bool;
}

typedef TTextureUnit = {
// @:structInit class TTextureUnit {
	public var name:String;
	@:optional public var link:String;
}

typedef TPipelineData = {
// @:structInit class TPipelineData {
	public var name:String;
	public var render_targets:Array<TPipelineRenderTarget>;
	public var stages:Array<TPipelineStage>;
	public var mesh_context:String; // Main mesh context
	public var shadows_context:String; // Lamp depth context
	@:optional public var depth_buffers:Array<TPipelineDepthBuffer>;
}

typedef TPipelineRenderTarget = {
// @:structInit class TPipelineRenderTarget {
	public var name:String;
	public var width:Int;
	public var height:Int;
	@:optional public var format:String;
	@:optional public var depth_buffer:String;
	@:optional public var ping_pong:Null<Bool>;
	@:optional public var scale:Null<Float>;
}

typedef TPipelineDepthBuffer = {
// @:structInit class TPipelineDepthBuffer {
	public var name:String;
	@:optional public var stencil_buffer:Bool;
}

typedef TPipelineStage = {
// @:structInit class TPipelineStage {
	public var command:String;
	@:optional public var params:Array<String>;
	@:optional public var returns_true:Array<TPipelineStage>; // Nested commands
	@:optional public var returns_false:Array<TPipelineStage>;
}

typedef TSpeakerData = {
// @:structInit class TSpeakerData {
	public var name:String;
	public var sound:String;
}

typedef TWorldData = {
// @:structInit class TWorldData {
	public var name:String;
	// public var material_ref:String;
	// public var bind_constants:Array<TBindConstant>;
	// public var bind_textures:Array<TBindTexture>;
	public var brdf:String;
	public var probes:Array<TProbe>;
}

typedef TProbe = {
// @:structInit class TProbe {
	public var irradiance:String; // Reference to TIrradiance blob
	public var strength:Float;
	public var blending:Float;
	public var volume:Array<Float>;
	public var volume_center:Array<Float>;
	@:optional public var radiance:String;
	@:optional public var radiance_mipmaps:Int;
	@:optional public var sun_direction:Array<Float>; // Sky data
	@:optional public var turbidity:Float;
	@:optional public var ground_albedo:Float;
}

typedef TIrradiance = { // Blob with spherical harmonics, bands 0,1,2
// @:structInit class TIrradiance {
	public var irradiance:Array<kha.FastFloat>;
}

typedef TParticleData = {
// @:structInit class TParticleData {
	public var name:String;
	public var count:Int;
	public var lifetime:Float;
	public var normal_factor:Float;
	public var object_align_factor:Array<Float>;
	public var factor_random:Float;
}

typedef TObj = {
// @:structInit class TObj {
	public var type:String;
	public var name:String;
	public var data_ref:String;
	public var material_refs:Array<String>;
	public var particle_refs:Array<TParticleReference>;
	public var transform:TTransform;
	public var objects:Array<TObj>;
	public var traits:Array<TTrait>;
	@:optional public var dimensions:Array<Float>; // Geometry objects
	@:optional public var animation:TAnimation;
	@:optional public var animation_transforms:Array<TAnimationTransform>;
	@:optional public var bones_ref:String;
	@:optional public var parent:TObj;
	@:optional public var visible:Null<Bool>;
	@:optional public var spawn:Null<Bool>; // Auto add object when creating scene
	@:optional public var local_transform_only:Null<Bool>; // No parent matrix applied
}

typedef TParticleReference = {
// @:structInit class TParticleReference {
	public var name:String;
	public var particle:String;
	public var seed:Int;
}

typedef TTrait = {
// @:structInit class TTrait {
	public var type:String;
	public var class_name:String;
	@:optional public var parameters:Array<Dynamic>;
}

typedef TTransform = {
// @:structInit class TTransform {
	@:optional public var target:String;
	public var values:Array<Float>;
}

typedef TAnimationTransform = {
// @:structInit class TAnimationTransform {
	public var type:String; // translation, translation_x, ...
	@:optional public var name:String;
	@:optional public var values:Array<Float>; // translation
	@:optional public var value:Float; // translation_x
}

typedef TAnimation = {
// @:structInit class TAnimation {
	public var tracks:Array<TTrack>;
	@:optional public var begin:Float; // For non-sampled
	@:optional public var end:Float;
}

typedef TTrack = {
// @:structInit class TTrack {
	public var target:String;
	public var time:TTime;
	public var value:TValue;
	@:optional public var curve:String; // bezier, tcb, ...
	@:optional public var time_control_plus:TTime; // bezier
	@:optional public var time_control_minus:TTime;
	@:optional public var value_control_plus:TValue;
	@:optional public var value_control_minus:TValue;
	// @:optional public var tension:TValue; // tcb
	// @:optional public var continuity:TValue;
	// @:optional public var bias:TValue;
}

typedef TTime = {
// @:structInit class TTime {
	public var values:Array<Float>;
}

typedef TValue = {
// @:structInit class TValue {
	public var values:Array<Dynamic>; // TODO: Unify
	// public var values:Array<Array<Float>>; // Array of transforms
	// public var values:Array<Float>; // Non-sampled
}

// Raw shader data
/*
typedef TRawShader = {
	public var contexts:Array<TRawContext>;
}

typedef TRawContext = {
	public var name:String;
	public var params:Array<TRawParam>;
	public var links:Array<TRawLink>;
	public var vertex_shader:String;
	public var fragment_shader:String;
}

typedef TRawParam = {
	public var name:String;
	public var value:String;
}

typedef TRawLink = {
	public var name:String;
	public var link:String;
	@:optional public var ifdef:Array<String>;
}
*/
