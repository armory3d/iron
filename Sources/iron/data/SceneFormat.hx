package iron.data;

#if cpp
typedef TFloat32Array = haxe.ds.Vector<kha.FastFloat>;
typedef TUint32Array = haxe.ds.Vector<Int>;
#else
typedef TFloat32Array = kha.arrays.Float32Array;
typedef TUint32Array = kha.arrays.Uint32Array;
#end

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
	@:optional var gravity:TFloat32Array;
	@:optional var traits:Array<TTrait>; // Scene root traits
	@:optional var embedded_datas:Array<String>; // Preload for this scene, images only for now
	@:optional var frame_time:Null<Float>;
	@:optional var capture_info:TRenderCaptureInfo;
}

typedef TMeshData = {
	var name:String;
	var vertex_arrays:Array<TVertexArray>;
	var index_arrays:Array<TIndexArray>;
	@:optional var dynamic_usage:Null<Bool>;
	@:optional var skin:TSkin;
	@:optional var instance_offsets:TFloat32Array;
	@:optional var sdf_ref:String;
}

typedef TSkin = {
	var transform:TTransform;
	var skeleton:TSkeleton;
	var bone_count_array:TUint32Array;
	var bone_index_array:TUint32Array;
	var bone_weight_array:TFloat32Array;
}

typedef TSkeleton = {
	var bone_ref_array:Array<String>;
	var transformsI:Array<TFloat32Array>; // size = 16, with skin.transform, pre-inverted
}

typedef TVertexArray = {
	var attrib:String;
	var values:TFloat32Array;
	@:optional var size:Null<Int>; // 3
}

typedef TIndexArray = {
	var values:TUint32Array;
	var material:Int;
	@:optional var size:Null<Int>; // 3
}

typedef TLampData = {
	var name:String;
	var type:String; // Sun, point, spot
	var color:TFloat32Array;
	var strength:Float;
	@:optional var cast_shadow:Null<Bool>;
	@:optional var near_plane:Null<Float>;
	@:optional var far_plane:Null<Float>;
	@:optional var fov:Null<Float>;
	@:optional var shadows_bias:Null<Float>;
	@:optional var shadowmap_size:Null<Int>;
	@:optional var shadowmap_cube:Null<Bool>; // Omni shadows for point
	@:optional var spot_size:Null<Float>;
	@:optional var spot_blend:Null<Float>;
	@:optional var lamp_size:Null<Float>; // Shadow soft size
	@:optional var color_texture:String; // Image reference
	@:optional var size:Null<Float>; // Area lamp
	@:optional var size_y:Null<Float>;
}

typedef TCameraData = {
	var name:String;
	var clear_color:TFloat32Array;
	var near_plane:Float;
	var far_plane:Float;
	var fov:Float;
	@:optional var aspect:Null<Float>;
	@:optional var frustum_culling:Null<Bool>;
	@:optional var render_to_texture:Null<Bool>;
	@:optional var texture_resolution_x:Null<Int>;
	@:optional var texture_resolution_y:Null<Int>;
	@:optional var ortho_scale:Null<Float>; // Indicates ortho camera
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
	@:optional var vec4:TFloat32Array;
	@:optional var vec3:TFloat32Array;
	@:optional var vec2:TFloat32Array;
	@:optional var float:Null<Float>;
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
	@:optional var vec4:TFloat32Array;
	@:optional var vec3:TFloat32Array;
	@:optional var vec2:TFloat32Array;
	@:optional var float:Null<Float>;
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
	var volume:Float;
	var pitch:Float;
	var attenuation:Float;
	var play_on_start:Bool;
}

typedef TWorldData = {
	var name:String;
	var background_color:Int;
	var probes:Array<TProbe>;
	@:optional var sun_direction:TFloat32Array; // Sky data
	@:optional var turbidity:Null<Float>;
	@:optional var ground_albedo:Null<Float>;
	@:optional var envmap:String;
}

typedef TProbe = {
	var irradiance:String; // Reference to TIrradiance blob
	var strength:Float;
	var blending:Float;
	var volume:TFloat32Array;
	var volume_center:TFloat32Array;
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
// 	var opacity:Float;
// 	var frames:Array<TGreasePencilFrame>;
// }

// typedef TGreasePencilFrame = {
// 	var frame_number:Int;
// 	var vertex_array:TVertexArray;
// 	var col_array:TVertexArray; // TODO: Use array instead
// 	var colfill_array:TVertexArray;
// 	var index_array:TIndexArray;
// 	var num_stroke_points:TUint32Array;
// }

// typedef TGreasePencilPalette = {
// 	var name:String;
// 	var colors:Array<TGreasePencilPaletteColor>;
// }

// typedef TGreasePencilPaletteColor = {
// 	var name:String;
// 	var color:TFloat32Array;
// 	var alpha:Float;
// 	var fill_color:TFloat32Array;
// 	var fill_alpha:Float;
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
	var irradiance:TFloat32Array;
}

typedef TParticleData = {
	var name:String;
	var type:Int; // 0 - Emitter, Hair
	var loop:Bool;
	var render_emitter:Bool;
	// Emission
	var count:Int;
	var frame_start:Float;
	var frame_end:Float;
	var lifetime:Float;
	var lifetime_random:Float;
	var emit_from:Int; // 0 - Vert, Face, 1 - Volume
	// Velocity
	// var normal_factor:Float;
	var object_align_factor:TFloat32Array;
	var factor_random:Float;
	// Physics
	var physics_type:Int; // 0 - No, 1 - Newton
	var particle_size:Float; // Object scale
	var size_random:Float; // Random scale
	var mass:Float; // Random scale
	// Render
	var dupli_object:String; // Object reference
	var gpu_sim:Bool; // Simulate on GPU
	// Field weights
	var weight_gravity:Float;
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
	@:optional var dimensions:TFloat32Array; // Geometry objects
	@:optional var object_actions:Array<String>;
	@:optional var bone_actions:Array<String>;
	@:optional var anim:TAnimation; // Bone/object animation
	@:optional var parent:TObj;
	@:optional var parent_bone:String;
	@:optional var parent_bone_tail:Array<Float>;
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
	var screen_size:Float; // (0-1) size compared to lod0
}

typedef TConstraint = {
	var name:String;
	var type:String;
	@:optional var target:String;
	@:optional var use_x:Null<Bool>;
	@:optional var use_y:Null<Bool>;
	@:optional var use_z:Null<Bool>;
	@:optional var invert_x:Null<Bool>;
	@:optional var invert_y:Null<Bool>;
	@:optional var invert_z:Null<Bool>;
	@:optional var use_offset:Null<Bool>;
	@:optional var influence:Null<Float>;
}

typedef TTrait = {
	var type:String;
	var class_name:String;
	@:optional var parameters:Array<String>; // constructor params
	@:optional var props:Array<String>; // name - value list
}

typedef TTransform = {
	@:optional var target:String;
	var values:TFloat32Array;
}

typedef TAnimation = {
	var tracks:Array<TTrack>;
	@:optional var begin:Null<Int>; // Frames, for non-sampled
	@:optional var end:Null<Int>;
	@:optional var has_delta:Null<Bool>; // Delta transform
	@:optional var marker_frames:Array<Int>;
	@:optional var marker_names:Array<String>;
}

typedef TAnimationTransform = {
	var type:String; // translation, translation_x, ...
	@:optional var name:String;
	@:optional var values:TFloat32Array; // translation
	@:optional var value:Null<Float>; // translation_x
}

typedef TTrack = {
	var target:String;
	var frames:TUint32Array;
	var values:TFloat32Array; // sampled - full matrix transforms, non-sampled - values
	@:optional var curve:String; // bezier, tcb, ...
	@:optional var frames_control_plus:TFloat32Array; // bezier
	@:optional var frames_control_minus:TFloat32Array;
	@:optional var values_control_plus:TFloat32Array;
	@:optional var values_control_minus:TFloat32Array;
	// @:optional var tension:TFloat32Array; // tcb
	// @:optional var continuity:TFloat32Array;
	// @:optional var bias:TFloat32Array;
}

typedef TRenderCaptureInfo = {
	var path:String;
	var frame_start:Int;
	var frame_end:Int;
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
