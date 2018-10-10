package iron.data;

import kha.FastFloat;
import kha.arrays.Float32Array;
import kha.arrays.Uint32Array;

#if js
typedef TSceneFormat = {
#else
@:structInit class TSceneFormat {
#end
	@:optional public var name:String;
	@:optional public var mesh_datas:Array<TMeshData>;
	@:optional public var light_datas:Array<TLightData>;
	@:optional public var probe_datas:Array<TProbeData>;
	@:optional public var camera_datas:Array<TCameraData>;
	@:optional public var camera_ref:String; // Active camera
	@:optional public var material_datas:Array<TMaterialData>;
	@:optional public var particle_datas:Array<TParticleData>;
	@:optional public var shader_datas:Array<TShaderData>;
	@:optional public var speaker_datas:Array<TSpeakerData>;
	@:optional public var world_datas:Array<TWorldData>;
	@:optional public var world_ref:String;
	// @:optional public var grease_pencil_datas:Array<TGreasePencilData>;
	// @:optional public var grease_pencil_ref:String;
	@:optional public var tilesheet_datas:Array<TTilesheetData>;
	@:optional public var objects:Array<TObj>;
	@:optional public var groups:Array<TGroup>;
	@:optional public var gravity:Float32Array;
	@:optional public var traits:Array<TTrait>; // Scene root traits
	@:optional public var embedded_datas:Array<String>; // Preload for this scene, images only for now
	@:optional public var frame_time:Null<FastFloat>;
	@:optional public var irradiance:Float32Array; // Blob with spherical harmonics, bands 0,1,2
}

#if js
typedef TMeshData = {
#else
@:structInit class TMeshData {
#end
	public var name:String;
	public var vertex_arrays:Array<TVertexArray>;
	public var index_arrays:Array<TIndexArray>;
	@:optional public var dynamic_usage:Null<Bool>;
	@:optional public var skin:TSkin;
	@:optional public var instanced_data:Float32Array;
	@:optional public var instanced_type:Null<Int>; // off, loc, loc+rot, loc+scale, loc+rot+scale
	@:optional public var sdf_ref:String;
}

#if js
typedef TSkin = {
#else
@:structInit class TSkin {
#end
	public var transform:TTransform;
	public var bone_ref_array:Array<String>;
	public var bone_len_array:Float32Array;
	public var transformsI:Array<Float32Array>; // per-bone, size = 16, with skin.transform, pre-inverted
	public var bone_count_array:Uint32Array;
	public var bone_index_array:Uint32Array;
	public var bone_weight_array:Float32Array;
	public var constraints:Array<TConstraint>;
}

#if js
typedef TVertexArray = {
#else
@:structInit class TVertexArray {
#end
	public var attrib:String;
	public var values:Float32Array;
	@:optional public var size:Null<Int>; // 3
}

#if js
typedef TIndexArray = {
#else
@:structInit class TIndexArray {
#end
	public var values:Uint32Array; // size = 3
	public var material:Int;
}

#if js
typedef TLightData = {
#else
@:structInit class TLightData {
#end
	public var name:String;
	public var type:String; // Sun, point, spot
	public var color:Float32Array;
	public var strength:FastFloat;
	@:optional public var cast_shadow:Null<Bool>;
	@:optional public var near_plane:Null<FastFloat>;
	@:optional public var far_plane:Null<FastFloat>;
	@:optional public var fov:Null<FastFloat>;
	@:optional public var shadows_bias:Null<FastFloat>;
	@:optional public var shadowmap_size:Null<Int>;
	@:optional public var shadowmap_cube:Null<Bool>; // Omni shadows for point
	@:optional public var spot_size:Null<FastFloat>;
	@:optional public var spot_blend:Null<FastFloat>;
	@:optional public var light_size:Null<FastFloat>; // Shadow soft size
	@:optional public var color_texture:String; // Image reference
	@:optional public var size:Null<FastFloat>; // Area light
	@:optional public var size_y:Null<FastFloat>;
}

#if js
typedef TCameraData = {
#else
@:structInit class TCameraData {
#end
	public var name:String;
	public var near_plane:FastFloat;
	public var far_plane:FastFloat;
	public var fov:FastFloat;
	@:optional public var clear_color:Float32Array;
	@:optional public var aspect:Null<FastFloat>;
	@:optional public var frustum_culling:Null<Bool>;
	@:optional public var ortho_scale:Null<FastFloat>; // Indicates ortho camera
}

#if js
typedef TMaterialData = {
#else
@:structInit class TMaterialData {
#end
	public var name:String;
	public var shader:String;
	public var contexts:Array<TMaterialContext>;
	@:optional public var skip_context:String;
	@:optional public var override_context:TShaderOverride;
}

#if js
typedef TShaderOverride = {
#else
@:structInit class TShaderOverride {
#end
	@:optional public var cull_mode:String;
}

#if js
typedef TMaterialContext = {
#else
@:structInit class TMaterialContext {
#end
	public var name:String;
	@:optional public var bind_constants:Array<TBindConstant>;
	@:optional public var bind_textures:Array<TBindTexture>;
}

#if js
typedef TBindConstant = {
#else
@:structInit class TBindConstant {
#end
	public var name:String;
	@:optional public var vec4:Float32Array;
	@:optional public var vec3:Float32Array;
	@:optional public var vec2:Float32Array;
	@:optional public var float:Null<FastFloat>;
	@:optional public var bool:Null<Bool>;
	@:optional public var int:Null<Int>;
}

#if js
typedef TBindTexture = {
#else
@:structInit class TBindTexture {
#end
	public var name:String;
	public var file:String;
	@:optional public var format:String; // RGBA32, RGBA64, R8
	@:optional public var generate_mipmaps:Null<Bool>;
	@:optional public var mipmaps:Array<String>; // Reference image names
	@:optional public var u_addressing:String;
	@:optional public var v_addressing:String;
	@:optional public var min_filter:String;
	@:optional public var mag_filter:String;
	@:optional public var mipmap_filter:String;
	@:optional public var source:String; // file, movie 
}

#if js
typedef TShaderData = {
#else
@:structInit class TShaderData {
#end
	public var name:String;
	public var contexts:Array<TShaderContext>;
}

#if js
typedef TShaderContext = {
#else
@:structInit class TShaderContext {
#end
	public var name:String;
	public var depth_write:Bool;
	public var compare_mode:String;
	public var cull_mode:String;
	public var vertex_structure:Array<TVertexData>;
	public var vertex_shader:String;
	public var fragment_shader:String;
	@:optional public var geometry_shader:String;
	@:optional public var tesscontrol_shader:String;
	@:optional public var tesseval_shader:String;
	@:optional public var constants:Array<TShaderConstant>;
	@:optional public var texture_units:Array<TTextureUnit>;
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
	@:optional public var stencil_read_mask:Null<Int>;
	@:optional public var stencil_write_mask:Null<Int>;
	@:optional public var color_write_red:Null<Bool>;
	@:optional public var color_write_green:Null<Bool>;
	@:optional public var color_write_blue:Null<Bool>;
	@:optional public var color_write_alpha:Null<Bool>;
	@:optional public var color_writes_red:Array<Bool>; // Per target masks
	@:optional public var color_writes_green:Array<Bool>;
	@:optional public var color_writes_blue:Array<Bool>;
	@:optional public var color_writes_alpha:Array<Bool>;
	@:optional public var conservative_raster:Null<Bool>;
	@:optional public var shader_from_source:Null<Bool>; // Build shader at runtime using fromSource()
}

#if js
typedef TVertexData = {
#else
@:structInit class TVertexData {
#end
	public var name:String;
	public var size:Int;
}

#if js
typedef TShaderConstant = {
#else
@:structInit class TShaderConstant {
#end
	public var name:String;
	public var type:String;
	@:optional public var link:String;
	@:optional public var vec4:Float32Array;
	@:optional public var vec3:Float32Array;
	@:optional public var vec2:Float32Array;
	@:optional public var float:Null<FastFloat>;
	@:optional public var bool:Null<Bool>;
	@:optional public var int:Null<Int>;
}

#if js
typedef TTextureUnit = {
#else
@:structInit class TTextureUnit {
#end
	public var name:String;
	@:optional public var is_image:Null<Bool>; // image2D
	@:optional public var link:String;
}

#if js
typedef TSpeakerData = {
#else
@:structInit class TSpeakerData {
#end
	public var name:String;
	public var sound:String;
	public var muted:Bool;
	public var loop:Bool;
	public var stream:Bool;
	public var volume:FastFloat;
	public var pitch:FastFloat;
	public var attenuation:FastFloat;
	public var play_on_start:Bool;
}

#if js
typedef TWorldData = {
#else
@:structInit class TWorldData {
#end
	public var name:String;
	public var background_color:Int;
	public var probe:TProbeData;
	@:optional public var sun_direction:Float32Array; // Sky data
	@:optional public var turbidity:Null<FastFloat>;
	@:optional public var ground_albedo:Null<FastFloat>;
	@:optional public var envmap:String;
}

#if js
typedef TProbeData = {
#else
@:structInit class TProbeData {
#end
	public var name:String;
	public var type:String; // grid, planar, cubemap
	public var strength:FastFloat;
	@:optional public var irradiance:String; // Reference to TIrradiance blob
	@:optional public var radiance:String;
	@:optional public var radiance_mipmaps:Null<Int>;
}

// #if js
// typedef TGreasePencilData = {
// #else
// @:structInit class TGreasePencilData {
// #end
// 	public var name:String;
// 	public var layers:Array<TGreasePencilLayer>;
// 	public var shader:String;
// }

// #if js
// typedef TGreasePencilLayer = {
// #else
// @:structInit class TGreasePencilLayer {
// #end
// 	public var name:String;
// 	public var opacity:FastFloat;
// 	public var frames:Array<TGreasePencilFrame>;
// }

// #if js
// typedef TGreasePencilFrame = {
// #else
// @:structInit class TGreasePencilFrame {
// #end
// 	public var frame_number:Int;
// 	public var vertex_array:TVertexArray;
// 	public var col_array:TVertexArray;
// 	public var colfill_array:TVertexArray;
// 	public var index_array:TIndexArray;
// 	public var num_stroke_points:Uint32Array;
// }

// #if js
// typedef TGreasePencilPalette = {
// #else
// @:structInit class TGreasePencilPalette {
// #end
// 	public var name:String;
// 	public var colors:Array<TGreasePencilPaletteColor>;
// }

// #if js
// typedef TGreasePencilPaletteColor = {
// #else
// @:structInit class TGreasePencilPaletteColor {
// #end
// 	public var name:String;
// 	public var color:Float32Array;
// 	public var alpha:FastFloat;
// 	public var fill_color:Float32Array;
// 	public var fill_alpha:FastFloat;
// }

#if js
typedef TTilesheetData = {
#else
@:structInit class TTilesheetData {
#end
	public var name:String;
	public var tilesx:Int;
	public var tilesy:Int;
	public var framerate:Int;
	public var actions:Array<TTilesheetAction>;
}

#if js
typedef TTilesheetAction = {
#else
@:structInit class TTilesheetAction {
#end
	public var name:String;
	public var start:Int;
	public var end:Int;
	public var loop:Bool;
}

#if js
typedef TParticleData = {
#else
@:structInit class TParticleData {
#end
	public var name:String;
	public var type:Int; // 0 - Emitter, Hair
	public var loop:Bool;
	public var render_emitter:Bool;
	// Emission
	public var count:Int;
	public var frame_start:FastFloat;
	public var frame_end:FastFloat;
	public var lifetime:FastFloat;
	public var lifetime_random:FastFloat;
	public var emit_from:Int; // 0 - Vert, Face, 1 - Volume
	// Velocity
	// public var normal_factor:FastFloat;
	public var object_align_factor:Float32Array;
	public var factor_random:FastFloat;
	// Physics
	public var physics_type:Int; // 0 - No, 1 - Newton
	public var particle_size:FastFloat; // Object scale
	public var size_random:FastFloat; // Random scale
	public var mass:FastFloat; // Random scale
	// Render
	public var dupli_object:String; // Object reference
	// Field weights
	public var weight_gravity:FastFloat;
}

#if js
typedef TParticleReference = {
#else
@:structInit class TParticleReference {
#end
	public var name:String;
	public var particle:String;
	public var seed:Int;
}

#if js
typedef TObj = {
#else
@:structInit class TObj {
#end
	public var type:String; // object, mesh_object, light_object, camera_object, speaker_object, decal_object
	public var name:String;
	public var data_ref:String;
	public var transform:TTransform;
	@:optional public var material_refs:Array<String>;
	@:optional public var particle_refs:Array<TParticleReference>;
	@:optional public var is_particle:Null<Bool>; // This object is used as a particle object
	@:optional public var children:Array<TObj>;
	@:optional public var group_ref:String; // dupli_type
	@:optional public var groups:Array<String>;
	@:optional public var lods:Array<TLod>;
	@:optional public var lod_material:Null<Bool>;
	@:optional public var traits:Array<TTrait>;
	@:optional public var constraints:Array<TConstraint>;
	@:optional public var dimensions:Float32Array; // Geometry objects
	@:optional public var object_actions:Array<String>;
	@:optional public var bone_actions:Array<String>;
	@:optional public var anim:TAnimation; // Bone/object animation
	@:optional public var parent:TObj;
	@:optional public var parent_bone:String;
	@:optional public var parent_bone_tail:Float32Array; // Translate from head to tail
	@:optional public var parent_bone_tail_pose:Float32Array;
	@:optional public var parent_bone_connected:Null<Bool>;
	@:optional public var visible:Null<Bool>;
	@:optional public var visible_mesh:Null<Bool>;
	@:optional public var visible_shadow:Null<Bool>;
	@:optional public var mobile:Null<Bool>;
	@:optional public var spawn:Null<Bool>; // Auto add object when creating scene
	@:optional public var local_only:Null<Bool>; // Apply parent matrix
	@:optional public var tilesheet_ref:String;
	@:optional public var tilesheet_action_ref:String;
	@:optional public var sampled:Null<Bool>; // Object action
}

#if js
typedef TGroup = {
#else
@:structInit class TGroup {
#end
	public var name:String;
	public var object_refs:Array<String>;
}

#if js
typedef TLod = {
#else
@:structInit class TLod {
#end
	public var object_ref:String; // Empty when limiting draw distance
	public var screen_size:FastFloat; // (0-1) size compared to lod0
}

#if js
typedef TConstraint = {
#else
@:structInit class TConstraint {
#end
	public var name:String;
	public var type:String;
	@:optional public var bone:String; // Bone constraint
	@:optional public var target:String;
	@:optional public var use_x:Null<Bool>;
	@:optional public var use_y:Null<Bool>;
	@:optional public var use_z:Null<Bool>;
	@:optional public var invert_x:Null<Bool>;
	@:optional public var invert_y:Null<Bool>;
	@:optional public var invert_z:Null<Bool>;
	@:optional public var use_offset:Null<Bool>;
	@:optional public var influence:Null<FastFloat>;
}

#if js
typedef TTrait = {
#else
@:structInit class TTrait {
#end
	public var type:String;
	public var class_name:String;
	@:optional public var parameters:Array<String>; // constructor params
	@:optional public var props:Array<String>; // name - value list
}

#if js
typedef TTransform = {
#else
@:structInit class TTransform {
#end
	@:optional public var target:String;
	public var values:Float32Array;
}

#if js
typedef TAnimation = {
#else
@:structInit class TAnimation {
#end
	public var tracks:Array<TTrack>;
	@:optional public var begin:Null<Int>; // Frames, for non-sampled
	@:optional public var end:Null<Int>;
	@:optional public var has_delta:Null<Bool>; // Delta transform
	@:optional public var marker_frames:Uint32Array;
	@:optional public var marker_names:Array<String>;
}

#if js
typedef TAnimationTransform = {
#else
@:structInit class TAnimationTransform {
#end
	public var type:String; // translation, translation_x, ...
	@:optional public var name:String;
	@:optional public var values:Float32Array; // translation
	@:optional public var value:Null<FastFloat>; // translation_x
}

#if js
typedef TTrack = {
#else
@:structInit class TTrack {
#end
	public var target:String;
	public var frames:Uint32Array;
	public var values:Float32Array; // sampled - full matrix transforms, non-sampled - values
	@:optional public var curve:String; // linear, bezier, tcb
	@:optional public var frames_control_plus:Float32Array; // bezier
	@:optional public var frames_control_minus:Float32Array;
	@:optional public var values_control_plus:Float32Array;
	@:optional public var values_control_minus:Float32Array;
	// @:optional public var tension:Float32Array; // tcb
	// @:optional public var continuity:Float32Array;
	// @:optional public var bias:Float32Array;
}

// Raw shader data
/*
typedef TRawShader = {
	public var contexts:Array<TRawContext>;
	public var variants:Array<String>;
}

typedef TRawContext = {
	public var name:String;
	public var params:Array<TRawParam>;
	public var links:Array<TRawLink>;
	public var vertex_shader:String;
	public var fragment_shader:String;
	@:optional public var geometry_shader:String;
	@:optional public var tesscontrol_shader:String;
	@:optional public var tesseval_shader:String;
}

typedef TRawParam = {
	public var name:String;
	public var value:String;
}

typedef TRawLink = {
	public var name:String;
	public var link:String;
	@:optional public var ifdef:Array<String>;
	@:optional public var ifndef:Array<String>;
}
*/
