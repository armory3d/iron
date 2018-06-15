package iron.data;

import kha.FastFloat;
import kha.arrays.Float32Array;
import kha.arrays.Uint32Array;

typedef TSceneFormat = {
	@:optional var name:String;
	@:optional var mesh_datas:Array<TMeshData>;
	@:optional var lamp_datas:Array<TLampData>;
	@:optional var camera_datas:Array<TCameraData>;
	@:optional var camera_ref:String; // Active camera
	@:optional var material_datas:Array<TMaterialData>;
	@:optional var particle_datas:Array<TParticleData>;
	@:optional var shader_datas:Array<TShaderData>;
	@:optional var speaker_datas:Array<TSpeakerData>;
	@:optional var world_datas:Array<TWorldData>;
	@:optional var world_ref:String;
	// @:optional var grease_pencil_datas:Array<TGreasePencilData>;
	// @:optional var grease_pencil_ref:String;
	@:optional var tilesheet_datas:Array<TTilesheetData>;
	@:optional var objects:Array<TObj>;
	@:optional var groups:Array<TGroup>;
	@:optional var gravity:Float32Array;
	@:optional var traits:Array<TTrait>; // Scene root traits
	@:optional var embedded_datas:Array<String>; // Preload for this scene, images only for now
	@:optional var frame_time:Null<FastFloat>;
}

typedef TMeshData = {
	var name:String;
	var vertex_arrays:Array<TVertexArray>;
	var index_arrays:Array<TIndexArray>;
	@:optional var dynamic_usage:Null<Bool>;
	@:optional var skin:TSkin;
	@:optional var instance_offsets:Float32Array;
	@:optional var sdf_ref:String;
}

typedef TSkin = {
	var transform:TTransform;
	var bone_ref_array:Array<String>;
	var bone_len_array:Float32Array;
	var transformsI:Array<Float32Array>; // per-bone, size = 16, with skin.transform, pre-inverted
	var bone_count_array:Uint32Array;
	var bone_index_array:Uint32Array;
	var bone_weight_array:Float32Array;
	var constraints:Array<TConstraint>;
}

typedef TVertexArray = {
	var attrib:String;
	var values:Float32Array;
	@:optional var size:Null<Int>; // 3
}

typedef TIndexArray = {
	var values:Uint32Array; // size = 3
	var material:Int;
}

typedef TLampData = {
	var name:String;
	var type:String; // Sun, point, spot
	var color:Float32Array;
	var strength:FastFloat;
	@:optional var cast_shadow:Null<Bool>;
	@:optional var near_plane:Null<FastFloat>;
	@:optional var far_plane:Null<FastFloat>;
	@:optional var fov:Null<FastFloat>;
	@:optional var shadows_bias:Null<FastFloat>;
	@:optional var shadowmap_size:Null<Int>;
	@:optional var shadowmap_cube:Null<Bool>; // Omni shadows for point
	@:optional var spot_size:Null<FastFloat>;
	@:optional var spot_blend:Null<FastFloat>;
	@:optional var lamp_size:Null<FastFloat>; // Shadow soft size
	@:optional var color_texture:String; // Image reference
	@:optional var size:Null<FastFloat>; // Area lamp
	@:optional var size_y:Null<FastFloat>;
}

typedef TCameraData = {
	var name:String;
	var near_plane:FastFloat;
	var far_plane:FastFloat;
	var fov:FastFloat;
	@:optional var clear_color:Float32Array;
	@:optional var aspect:Null<FastFloat>;
	@:optional var frustum_culling:Null<Bool>;
	@:optional var render_to_texture:Null<Bool>;
	@:optional var texture_resolution_x:Null<Int>;
	@:optional var texture_resolution_y:Null<Int>;
	@:optional var ortho_scale:Null<FastFloat>; // Indicates ortho camera
}

typedef TMaterialData = {
	var name:String;
	var shader:String;
	var contexts:Array<TMaterialContext>;
	@:optional var skip_context:String;
	@:optional var override_context:TShaderOverride;
}

typedef TShaderOverride = {
	@:optional var cull_mode:String;
}

typedef TMaterialContext = {
	var name:String;
	@:optional var bind_constants:Array<TBindConstant>;
	@:optional var bind_textures:Array<TBindTexture>;
}

typedef TBindConstant = {
	var name:String;
	@:optional var vec4:Float32Array;
	@:optional var vec3:Float32Array;
	@:optional var vec2:Float32Array;
	@:optional var float:Null<FastFloat>;
	@:optional var bool:Null<Bool>;
	@:optional var int:Null<Int>;
}

typedef TBindTexture = {
	var name:String;
	var file:String;
	@:optional var format:String; // RGBA32, RGBA64, R8
	@:optional var generate_mipmaps:Null<Bool>;
	@:optional var mipmaps:Array<String>; // Reference image names
	@:optional var u_addressing:String;
	@:optional var v_addressing:String;
	@:optional var min_filter:String;
	@:optional var mag_filter:String;
	@:optional var mipmap_filter:String;
	@:optional var source:String; // file, movie 
}

typedef TShaderData = {
	var name:String;
	var contexts:Array<TShaderContext>;
}

typedef TShaderContext = {
	var name:String;
	var depth_write:Bool;
	var compare_mode:String;
	var cull_mode:String;
	var vertex_structure:Array<TVertexData>;
	var vertex_shader:String;
	var fragment_shader:String;
	@:optional var geometry_shader:String;
	@:optional var tesscontrol_shader:String;
	@:optional var tesseval_shader:String;
	@:optional var constants:Array<TShaderConstant>;
	@:optional var texture_units:Array<TTextureUnit>;
	@:optional var blend_source:String;
	@:optional var blend_destination:String;
	@:optional var blend_operation:String;
	@:optional var alpha_blend_source:String;
	@:optional var alpha_blend_destination:String;
	@:optional var alpha_blend_operation:String;
	@:optional var stencil_mode:String;
	@:optional var stencil_pass:String;
	@:optional var stencil_fail:String;
	@:optional var stencil_reference_value:Null<Int>;
	@:optional var stencil_read_mask:Null<Int>;
	@:optional var stencil_write_mask:Null<Int>;
	@:optional var color_write_red:Null<Bool>;
	@:optional var color_write_green:Null<Bool>;
	@:optional var color_write_blue:Null<Bool>;
	@:optional var color_write_alpha:Null<Bool>;
	@:optional var conservative_raster:Null<Bool>;
	@:optional var shader_from_source:Null<Bool>; // Build shader at runtime using fromSource()
}

typedef TVertexData = {
	var name:String;
	var size:Int;
}

typedef TShaderConstant = {
	var name:String;
	var type:String;
	@:optional var link:String;
	@:optional var vec4:Float32Array;
	@:optional var vec3:Float32Array;
	@:optional var vec2:Float32Array;
	@:optional var float:Null<FastFloat>;
	@:optional var bool:Null<Bool>;
	@:optional var int:Null<Int>;
}

typedef TTextureUnit = {
	var name:String;
	@:optional var is_image:Null<Bool>; // image2D
	@:optional var link:String;
}

typedef TSpeakerData = {
	var name:String;
	var sound:String;
	var muted:Bool;
	var loop:Bool;
	var stream:Bool;
	var volume:FastFloat;
	var pitch:FastFloat;
	var attenuation:FastFloat;
	var play_on_start:Bool;
}

typedef TWorldData = {
	var name:String;
	var background_color:Int;
	var probes:Array<TProbe>;
	@:optional var sun_direction:Float32Array; // Sky data
	@:optional var turbidity:Null<FastFloat>;
	@:optional var ground_albedo:Null<FastFloat>;
	@:optional var envmap:String;
}

typedef TProbe = {
	var irradiance:String; // Reference to TIrradiance blob
	var strength:FastFloat;
	var blending:FastFloat;
	var volume:Float32Array;
	var volume_center:Float32Array;
	@:optional var radiance:String;
	@:optional var radiance_mipmaps:Null<Int>;
}

// typedef TGreasePencilData = {
// 	var name:String;
// 	var layers:Array<TGreasePencilLayer>;
// 	var shader:String;
// }

// typedef TGreasePencilLayer = {
// 	var name:String;
// 	var opacity:FastFloat;
// 	var frames:Array<TGreasePencilFrame>;
// }

// typedef TGreasePencilFrame = {
// 	var frame_number:Int;
// 	var vertex_array:TVertexArray;
// 	var col_array:TVertexArray; // TODO: Use array instead
// 	var colfill_array:TVertexArray;
// 	var index_array:TIndexArray;
// 	var num_stroke_points:Uint32Array;
// }

// typedef TGreasePencilPalette = {
// 	var name:String;
// 	var colors:Array<TGreasePencilPaletteColor>;
// }

// typedef TGreasePencilPaletteColor = {
// 	var name:String;
// 	var color:Float32Array;
// 	var alpha:FastFloat;
// 	var fill_color:Float32Array;
// 	var fill_alpha:FastFloat;
// }

typedef TTilesheetData = {
	var name:String;
	var tilesx:Int;
	var tilesy:Int;
	var framerate:Int;
	var actions:Array<TTilesheetAction>;
}

typedef TTilesheetAction = {
	var name:String;
	var start:Int;
	var end:Int;
	var loop:Bool;
}

typedef TIrradiance = { // Blob with spherical harmonics, bands 0,1,2
	var irradiance:Float32Array;
}

typedef TParticleData = {
	var name:String;
	var type:Int; // 0 - Emitter, Hair
	var loop:Bool;
	var render_emitter:Bool;
	// Emission
	var count:Int;
	var frame_start:FastFloat;
	var frame_end:FastFloat;
	var lifetime:FastFloat;
	var lifetime_random:FastFloat;
	var emit_from:Int; // 0 - Vert, Face, 1 - Volume
	// Velocity
	// var normal_factor:FastFloat;
	var object_align_factor:Float32Array;
	var factor_random:FastFloat;
	// Physics
	var physics_type:Int; // 0 - No, 1 - Newton
	var particle_size:FastFloat; // Object scale
	var size_random:FastFloat; // Random scale
	var mass:FastFloat; // Random scale
	// Render
	var dupli_object:String; // Object reference
	var gpu_sim:Bool; // Simulate on GPU
	// Field weights
	var weight_gravity:FastFloat;
}

typedef TParticleReference = {
	var name:String;
	var particle:String;
	var seed:Int;
}

typedef TObj = {
	var type:String;
	var name:String;
	var data_ref:String;
	var transform:TTransform;
	@:optional var material_refs:Array<String>;
	@:optional var particle_refs:Array<TParticleReference>;
	@:optional var is_particle:Null<Bool>; // This object is used as a particle object
	@:optional var children:Array<TObj>;
	@:optional var group_ref:String; // dupli_type
	@:optional var groups:Array<String>;
	@:optional var lods:Array<TLod>;
	@:optional var lod_material:Null<Bool>;
	@:optional var traits:Array<TTrait>;
	@:optional var constraints:Array<TConstraint>;
	@:optional var dimensions:Float32Array; // Geometry objects
	@:optional var object_actions:Array<String>;
	@:optional var bone_actions:Array<String>;
	@:optional var anim:TAnimation; // Bone/object animation
	@:optional var parent:TObj;
	@:optional var parent_bone:String;
	@:optional var parent_bone_tail:Float32Array;
	@:optional var parent_bone_tail_y:Float32Array;
	@:optional var visible:Null<Bool>;
	@:optional var visible_mesh:Null<Bool>;
	@:optional var visible_shadow:Null<Bool>;
	@:optional var mobile:Null<Bool>;
	@:optional var spawn:Null<Bool>; // Auto add object when creating scene
	@:optional var local_transform_only:Null<Bool>; // No parent matrix applied
	@:optional var tilesheet_ref:String;
	@:optional var tilesheet_action_ref:String;
	@:optional var sampled:Null<Bool>; // Object action
}

typedef TGroup = {
	var name:String;
	var object_refs:Array<String>;
}

typedef TLod = {
	var object_ref:String; // Empty when limiting draw distance
	var screen_size:FastFloat; // (0-1) size compared to lod0
}

typedef TConstraint = {
	var name:String;
	var type:String;
	@:optional var bone:String; // Bone constraint
	@:optional var target:String;
	@:optional var use_x:Null<Bool>;
	@:optional var use_y:Null<Bool>;
	@:optional var use_z:Null<Bool>;
	@:optional var invert_x:Null<Bool>;
	@:optional var invert_y:Null<Bool>;
	@:optional var invert_z:Null<Bool>;
	@:optional var use_offset:Null<Bool>;
	@:optional var influence:Null<FastFloat>;
}

typedef TTrait = {
	var type:String;
	var class_name:String;
	@:optional var parameters:Array<String>; // constructor params
	@:optional var props:Array<String>; // name - value list
}

typedef TTransform = {
	@:optional var target:String;
	var values:Float32Array;
}

typedef TAnimation = {
	var tracks:Array<TTrack>;
	@:optional var begin:Null<Int>; // Frames, for non-sampled
	@:optional var end:Null<Int>;
	@:optional var has_delta:Null<Bool>; // Delta transform
	@:optional var marker_frames:Uint32Array;
	@:optional var marker_names:Array<String>;
}

typedef TAnimationTransform = {
	var type:String; // translation, translation_x, ...
	@:optional var name:String;
	@:optional var values:Float32Array; // translation
	@:optional var value:Null<FastFloat>; // translation_x
}

typedef TTrack = {
	var target:String;
	var frames:Uint32Array;
	var values:Float32Array; // sampled - full matrix transforms, non-sampled - values
	@:optional var curve:String; // bezier, tcb, ...
	@:optional var frames_control_plus:Float32Array; // bezier
	@:optional var frames_control_minus:Float32Array;
	@:optional var values_control_plus:Float32Array;
	@:optional var values_control_minus:Float32Array;
	// @:optional var tension:Float32Array; // tcb
	// @:optional var continuity:Float32Array;
	// @:optional var bias:Float32Array;
}

// Raw shader data
/*
typedef TRawShader = {
	var contexts:Array<TRawContext>;
}

typedef TRawContext = {
	var name:String;
	var params:Array<TRawParam>;
	var links:Array<TRawLink>;
	var vertex_shader:String;
	var fragment_shader:String;
	@:optional var geometry_shader:String;
	@:optional var tesscontrol_shader:String;
	@:optional var tesseval_shader:String;
}

typedef TRawParam = {
	var name:String;
	var value:String;
}

typedef TRawLink = {
	var name:String;
	var link:String;
	@:optional var ifdef:Array<String>;
	@:optional var ifndef:Array<String>;
}
*/
