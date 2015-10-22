package lue.resource;

import lue.resource.importer.SceneFormat;

class Resource {

	static var cachedScenes:Map<String, TSceneFormat> = new Map();

	public function new() {

	}

	public static function getSceneResource(name:String):TSceneFormat {
		var cached = cachedScenes.get(name);
		if (cached == null) {
			var data = kha.Loader.the.getBlob(name).toString();
			var parsed:TSceneFormat = haxe.Json.parse(data);
			cachedScenes.set(name, parsed);

			return parsed;
		}
		else {
			return cached;
		}	
	}

	public static function getGeometryResourceById(resources:Array<TGeometryResource>, id:String):TGeometryResource {
		if (id == "") return resources[0];
		for (res in resources) {
			if (res.id == id) return res;
		}
		return null;
	}

	public static function getLightResourceById(resources:Array<TLightResource>, id:String):TLightResource {
		if (id == "") return resources[0];
		for (res in resources) {
			if (res.id == id) return res;
		}
		return null;
	}

	public static function getCameraResourceById(resources:Array<TCameraResource>, id:String):TCameraResource {
		if (id == "") return resources[0];
		for (res in resources) {
			if (res.id == id) return res;
		}
		return null;
	}

	public static function getMaterialResourceById(resources:Array<TMaterialResource>, id:String):TMaterialResource {
		if (id == "") return resources[0];
		for (res in resources) {
			if (res.id == id) return res;
		}
		return null;
	}
}
