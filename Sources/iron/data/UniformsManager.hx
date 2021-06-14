package iron.data;

import haxe.macro.Expr.Case;
import kha.math.Vector4;
import kha.Image;
import haxe.ds.Map;
import iron.math.Vec4;
import iron.data.MaterialData;
import iron.Scene;
import iron.object.Object;
import iron.object.Uniforms;


class UniformsManager{

    static var floatsRegistered = false;
    static var floatsMap = new Map<Object, Map<MaterialData, Map<String, Null<kha.FastFloat>>>>();

    static var vectorsRegistered = false;
    static var vectorsMap = new Map<Object, Map<MaterialData, Map<String, Vec4>>>();

    static var texturesRegistered = false;
	static var texturesMap = new Map<Object, Map<MaterialData, Map<String, kha.Image>>>();

	// Helper method to register float, vec3 and texture getter functions
	static function register(type: UniformType){

		switch (type){
            case Float:{
                if(! floatsRegistered){
                    floatsRegistered = true;
                    Uniforms.externalFloatLinks.push(floatLink);
                }
            }

            case Vector:{
                if(! vectorsRegistered){
                    vectorsRegistered = true;
                    Uniforms.externalVec3Links.push(vec3Link);
                }
            }

            case Texture:{
                if(! texturesRegistered){
                    texturesRegistered = true;
                    Uniforms.externalTextureLinks.push(textureLink);
                }
            }
        }
	}

	// Register and map shader uniforms if it is an armory shader parameter
	public static function registerShaderUniforms(material: MaterialData) {

		if(! floatsMap.exists(Scene.active.root)) floatsMap.set(Scene.active.root, null);
		if(! vectorsMap.exists(Scene.active.root)) vectorsMap.set(Scene.active.root, null);
		if(! texturesMap.exists(Scene.active.root)) texturesMap.set(Scene.active.root, null);

		for(context in material.shader.raw.contexts){ // For each context in shader
			for (constant in context.constants){ // For each constant in the context
				if(constant.is_arm_parameter){ // Chack if armory parameter

					var object = Scene.active.root; // Map default uniforms to scene root

					switch (constant.type){
						case "float":{
							var link = constant.link;
							var value:Float = constant.float;
							setFloatValue(material, object, link, value);
							register(Float);
						}

						case "vec3":{

							var vec = new Vec4();
							vec.x = constant.vec3.get(0);
							vec.y = constant.vec3.get(1);
							vec.z = constant.vec3.get(2);

							setVec3Value(material, object, constant.link, vec);
							register(Vector);
							
						}
					}
				}
			}
			for (texture in context.texture_units){
				if(texture.is_arm_parameter){ // Chack if armory parameter

					var object = Scene.active.root; // Map default texture to scene root

					iron.data.Data.getImage(texture.default_image_file, function(image: kha.Image) {
						setTextureValue(material, object, texture.link, image);
					
					});
					register(Texture);

				}
					
			}
		}
		
	}

	// Method to set map Object -> Material -> Link -> FLoat 
    public static function setFloatValue(material: MaterialData, object: Object, link: String, value: Null<kha.FastFloat>){
        
		if(object == null || material == null || link == null) return;

        var map = floatsMap;

        var matMap = map.get(object);
        if (matMap == null) {
			matMap = new Map();
			map.set(object, matMap);
		}

		var entry = matMap.get(material);
		if (entry == null) {
			entry = new Map();
			matMap.set(material, entry);
		}

		entry.set(link, value); // parameter name, value
    }

	// Method to set map Object -> Material -> Link -> Vec3 
    public static function setVec3Value(material: MaterialData, object: Object, link: String, value: Vec4){
        
		if(object == null || material == null || link == null) return;

        var map = vectorsMap;

        var matMap = map.get(object);
        if (matMap == null) {
			matMap = new Map();
			map.set(object, matMap);
		}

		var entry = matMap.get(material);
		if (entry == null) {
			entry = new Map();
			matMap.set(material, entry);
		}

		entry.set(link, value); // parameter name, value
    }

	// Method to set map Object -> Material -> Link -> Texture 
    public static function setTextureValue(material: MaterialData, object: Object, link: String, value: kha.Image){
        
		if(object == null || material == null || link == null) return;

        var map = texturesMap;

        var matMap = map.get(object);
        if (matMap == null) {
			matMap = new Map();
			map.set(object, matMap);
		}

		var entry = matMap.get(material);
		if (entry == null) {
			entry = new Map();
			matMap.set(material, entry);
		}

		entry.set(link, value); // parameter name, value
    }

	// Mehtod to get object specific material parameter float value
    static function floatLink(object: Object, mat: MaterialData, link: String): Null<kha.FastFloat> {
		
		if(object == null || mat == null) return null;

		if(! floatsMap.exists(object)){
			object = Scene.active.root;
		}

		var material = floatsMap.get(object);
		if (material == null) return null;

		var entry = material.get(mat);
		if (entry == null) return null;

		return entry.get(link);
	}

	// Mehtod to get object specific material parameter vec3 value
    static function vec3Link(object: Object, mat: MaterialData, link: String): iron.math.Vec4 {
		
		if(object == null || mat == null) return null;

        if(! vectorsMap.exists(object)){
			object = Scene.active.root;
		}

        var material = vectorsMap.get(object);
		if (material == null) return null;

		var entry = material.get(mat);
		if (entry == null) return null;

		return entry.get(link);
	}

	// Mehtod to get object specific material parameter texture value
    static function textureLink(object: Object, mat: MaterialData, link: String): kha.Image {
		
		if(object == null || mat == null) return null;

        if(! texturesMap.exists(object)){
			object = Scene.active.root;
		}

        var material = texturesMap.get(object);
		if (material == null) return null;

		var entry = material.get(mat);
		if (entry == null) return null;

		return entry.get(link);
	}

	// Returns complete map of float value material paramets
	public static function getFloatsMap():Map<Object, Map<MaterialData, Map<String, Null<kha.FastFloat>>>>{

		return floatsMap;
	}

	// Returns complete map of vec3 value material paramets
	public static function getVectorsMap():Map<Object, Map<MaterialData, Map<String, Vec4>>>{

		return vectorsMap;
	}

	// Returns complete map of texture value material paramets
	public static function getTexturesMap():Map<Object, Map<MaterialData, Map<String, kha.Image>>>{

		return texturesMap;
	}

	// Remove all object specific material paramenter keys
	public static function removeObjectFromAllMaps(object: Object) {

		floatsMap.remove(object);
		vectorsMap.remove(object);
		texturesMap.remove(object);
		
	}

	// Remove object specific material paramenter keys
	public static function removeObjectFromMap(object: Object, type: UniformType) {

		switch (type){
			case Float: floatsMap.remove(object);

			case Vector: vectorsMap.remove(object);

			case Texture: texturesMap.remove(object);
		}
		
	}
}

@:enum abstract UniformType(Int) from Int to Int {
	var Float = 0;
	var Vector = 1;
	var Texture = 2;
}