package iron.resource;

import iron.resource.SceneFormat;

class Resource {

	static var cachedScenes:Map<String, TSceneFormat> = new Map();
	static var cachedModels:Map<String, ModelResource> = new Map();
	static var cachedLights:Map<String, LightResource> = new Map();
	static var cachedCameras:Map<String, CameraResource> = new Map();
	static var cachedPipelines:Map<String, PipelineResource> = new Map();
	static var cachedMaterials:Map<String, MaterialResource> = new Map();
	static var cachedParticles:Map<String, ParticleResource> = new Map();
	static var cachedWorlds:Map<String, WorldResource> = new Map();
	static var cachedShaders:Map<String, ShaderResource> = new Map();

	public function new() { }

	public static function deleteAll() {
		for (res in cachedModels) {
			res.delete();
		}
		for (res in cachedShaders) {
			res.delete();
		}
		cachedScenes = new Map();
		cachedModels = new Map();
		cachedLights = new Map();
		cachedCameras = new Map();
		cachedPipelines = new Map();
		cachedMaterials = new Map();
		cachedParticles = new Map();
		cachedWorlds = new Map();
		cachedShaders = new Map();
	}

	// Experimental scene reloading
	public static function clearSceneData() {
		cachedScenes = new Map();
		cachedMaterials = new Map();
	}

	public static function getModel(name:String, id:String, boneNodes:Array<TNode> = null):ModelResource {
		// boneNodes - used when geometry is parsed from separate file
		// TODO: preparse bone nodes
		var cached = cachedModels.get(name + id);
		if (cached == null) {
			var parsed = ModelResource.parse(name, id, boneNodes);
			cachedModels.set(name + id, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getLight(name:String, id:String):LightResource {
		var cached = cachedLights.get(name + id);
		if (cached == null) {
			var parsed = LightResource.parse(name, id);
			cachedLights.set(name + id, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getCamera(name:String, id:String):CameraResource {
		var cached = cachedCameras.get(name + id);
		if (cached == null) {
			var parsed = CameraResource.parse(name, id);
			cachedCameras.set(name + id, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getPipeline(name:String, id:String):PipelineResource {
		var cached = cachedPipelines.get(name + id);
		if (cached == null) {
			var parsed = PipelineResource.parse(name, id);
			cachedPipelines.set(name + id, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getMaterial(name:String, id:String):MaterialResource {
		var cached = cachedMaterials.get(name + id);
		if (cached == null) {
			var parsed = MaterialResource.parse(name, id);
			cachedMaterials.set(name + id, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getParticle(name:String, id:String):ParticleResource {
		var cached = cachedParticles.get(name + id);
		if (cached == null) {
			var parsed = ParticleResource.parse(name, id);
			cachedParticles.set(name + id, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getWorld(name:String, id:String):WorldResource {
		var cached = cachedWorlds.get(name + id);
		if (cached == null) {
			var parsed = WorldResource.parse(name, id);
			cachedWorlds.set(name + id, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getShader(name:String, id:String, overrideContext:TShaderOverride = null):ShaderResource {
		// Only one context override per shader resource for now
		var cacheId = id;
		if (overrideContext != null) cacheId += "2";
		var cached = cachedShaders.get(cacheId); // Shader must have unique id
		if (cached == null) {
			var parsed = ShaderResource.parse(name, id, overrideContext);
			cachedShaders.set(cacheId, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getSceneResource(name:String):TSceneFormat {
		var cached = cachedScenes.get(name);
		if (cached == null) {
			var data:kha.Blob = Reflect.field(kha.Assets.blobs, name + '_arm');
#if WITH_JSON
			var parsed:TSceneFormat = haxe.Json.parse(data.toString());
#else
			var parsed:TSceneFormat = iron.resource.msgpack.MsgPack.decode(data.toBytes());
#end
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

	public static function getPipelineResourceById(resources:Array<TPipelineResource>, id:String):TPipelineResource {
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

	public static function getParticleResourceById(resources:Array<TParticleResource>, id:String):TParticleResource {
		if (id == "") return resources[0];
		for (res in resources) {
			if (res.id == id) return res;
		}
		return null;
	}

	public static function getWorldResourceById(resources:Array<TWorldResource>, id:String):TWorldResource {
		if (id == "") return resources[0];
		for (res in resources) {
			if (res.id == id) return res;
		}
		return null;
	}

	public static function getShaderResourceById(resources:Array<TShaderResource>, id:String):TShaderResource {
		if (id == "") return resources[0];
		for (res in resources) {
			if (res.id == id) return res;
		}
		return null;
	}

	public static function getSpeakerResourceById(resources:Array<TSpeakerResource>, id:String):TSpeakerResource {
		if (id == "") return resources[0];
		for (res in resources) {
			if (res.id == id) return res;
		}
		return null;
	}
}
