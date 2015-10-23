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
