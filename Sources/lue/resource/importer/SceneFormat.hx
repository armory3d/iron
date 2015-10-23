package lue.resource.importer;

typedef TSceneFormat = {
	@:optional var geometry_resources:Array<TGeometryResource>;
	@:optional var light_resources:Array<TLightResource>;
	@:optional var camera_resources:Array<TCameraResource>;
	@:optional var material_resources:Array<TMaterialResource>;
	@:optional var shader_resources:Array<TShaderResource>;

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
	@:optional var skin:TSkin;
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
}

typedef TMaterialResource = {
	var id:String;
	var shader_id:String;
	@:optional var shader_resource:String;
	var cast_shadow:Bool;
	var params:Array<TMaterialParam>;
	var textures:Array<TMaterialTexture>;
}

typedef TMaterialParam = {
	var id:String;
	@:optional var vec4:Array<Float>;
	@:optional var vec3:Array<Float>;
	@:optional var float:Float;
	@:optional var bool:Bool;
}

typedef TMaterialTexture = {
	var id:String;
	var name:String;
}

typedef TShaderResource = {
	var id:String;
	var vertex_shader:String;
	var fragment_shader:String;
	var constants:Array<TShaderConstant>;
	var material_constants:Array<TShaderMaterialConstant>;
	var texture_units:Array<TTextureUnit>;
}

typedef TShaderConstant = {
	var id:String;
	var type:String;
	var value:String;
}

typedef TShaderMaterialConstant = {
	var id:String;
	var type:String;
}

typedef TTextureUnit = {
	var id:String;
	@:optional var value:String;
}

// Skinned
typedef TNode = {
	var type:String;
	var id:String;
	var name:String;
	var object_ref:String;
	var material_refs:Array<String>;
	var transform:TTransform;
	@:optional var animation:TAnimation;
	var nodes:Array<TNode>;
	@:optional var parent:TNode;
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
