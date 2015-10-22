package lue.resource.importer;

typedef TSceneFormat = {
	@:optional var geometry_resources:Array<TGeometryResource>;
	@:optional var light_resources:Array<TLightResource>;
	@:optional var camera_resources:Array<TCameraResource>;
	@:optional var material_resources:Array<TMaterialResource>;
	@:optional var shader_resources:Array<TShaderResource>;
}

typedef TGeometryResource = {
	var id:String;
	var mesh:TMesh;
}

typedef TMesh = {
	var primitive:String;
	var vertex_arrays:Array<TVertexArray>;
	var index_arrays:Array<TIndexArray>;
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
	var diffuse:Bool;
	@:optional var diffuse_color:Array<Float>;
	var glossy:Bool;
	@:optional var glossy_color:Array<Float>;
	var roughness:Float;
	var texture:String;
	var lighting:Bool;
	var cast_shadow:Bool;
	var receive_shadow:Bool;
	var shader_id:String;
	@:optional var shader_resource:String;
}

typedef TShaderResource = {
	var id:String;
	var vertex_shader:String;
	var fragment_shader:String;
	var constants:Array<TShaderConstant>;
	var texture_units:Array<TTextureUnit>;
}

typedef TShaderConstant = {
	var id:String;
}

typedef TTextureUnit = {
	var id:String;
}
