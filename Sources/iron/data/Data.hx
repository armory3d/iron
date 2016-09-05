package iron.data;

import iron.data.SceneFormat;

class Data {

	static var cachedSceneRaws:Map<String, TSceneFormat> = new Map();
	static var cachedMeshes:Map<String, MeshData> = new Map();
	static var cachedLamps:Map<String, LampData> = new Map();
	static var cachedCameras:Map<String, CameraData> = new Map();
	static var cachedRenderPaths:Map<String, RenderPathData> = new Map();
	static var cachedMaterials:Map<String, MaterialData> = new Map();
	static var cachedParticles:Map<String, ParticleData> = new Map();
	static var cachedWorlds:Map<String, WorldData> = new Map();
	static var cachedShaders:Map<String, ShaderData> = new Map();

	public function new() { }

	public static function deleteAll() {
		for (dat in cachedMeshes) {
			dat.delete();
		}
		for (dat in cachedShaders) {
			dat.delete();
		}
		cachedSceneRaws = new Map();
		cachedMeshes = new Map();
		cachedLamps = new Map();
		cachedCameras = new Map();
		cachedRenderPaths = new Map();
		cachedMaterials = new Map();
		cachedParticles = new Map();
		cachedWorlds = new Map();
		cachedShaders = new Map();
	}

	// Experimental scene patching
	public static function clearSceneData() {
		cachedSceneRaws = new Map();
		cachedMeshes = new Map(); // Delete data
		cachedLamps = new Map();
		cachedMaterials = new Map();
		cachedRenderPaths = new Map();
		cachedCameras = new Map();
		// cachedParticles = new Map();
		// cachedWorlds = new Map();
		// cachedShaders = new Map(); // Slow
	}

	public static function getMesh(file:String, name:String, boneObjects:Array<TObj> = null):MeshData {
		// boneObjects - used when mesh is parsed from separate file
		// TODO: preparse bone objects
		var cached = cachedMeshes.get(file + name);
		if (cached == null) {
			var parsed = MeshData.parse(file, name, boneObjects);
			cachedMeshes.set(file + name, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getLamp(file:String, name:String):LampData {
		var cached = cachedLamps.get(file + name);
		if (cached == null) {
			var parsed = LampData.parse(file, name);
			cachedLamps.set(file + name, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getCamera(file:String, name:String):CameraData {
		var cached = cachedCameras.get(file + name);
		if (cached == null) {
			var parsed = CameraData.parse(file, name);
			cachedCameras.set(file + name, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getRenderPath(file:String, name:String):RenderPathData {
		var cached = cachedRenderPaths.get(file + name);
		if (cached == null) {
			var parsed = RenderPathData.parse(file, name);
			cachedRenderPaths.set(file + name, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getMaterial(file:String, name:String):MaterialData {
		var cached = cachedMaterials.get(file + name);
		if (cached == null) {
			var parsed = MaterialData.parse(file, name);
			cachedMaterials.set(file + name, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getParticle(file:String, name:String):ParticleData {
		var cached = cachedParticles.get(file + name);
		if (cached == null) {
			var parsed = ParticleData.parse(file, name);
			cachedParticles.set(file + name, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getWorld(file:String, name:String):WorldData {
		var cached = cachedWorlds.get(file + name);
		if (cached == null) {
			var parsed = WorldData.parse(file, name);
			cachedWorlds.set(file + name, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getShader(file:String, name:String, overrideContext:TShaderOverride = null):ShaderData {
		// Only one context override per shader data for now
		var cacheName = name;
		if (overrideContext != null) cacheName += "2";
		var cached = cachedShaders.get(cacheName); // Shader must have unique name
		if (cached == null) {
			var parsed = ShaderData.parse(file, name, overrideContext);
			cachedShaders.set(cacheName, parsed);
			return parsed;
		}
		else return cached;
	}

	public static function getSceneRaw(file:String):TSceneFormat {
		var cached = cachedSceneRaws.get(file);
		if (cached == null) {
			var blob:kha.Blob = Reflect.field(kha.Assets.blobs, file + '_arm');
#if WITH_LIVEPATCH
			// Attempt to load manually
			if (blob == null) {
				var data:Dynamic = null;
				untyped __js__('var fs = require("fs");');
				untyped __js__('{0} = fs.readFileSync(__dirname + "/" + {1} + ".arm");', data, file);
				blob = kha.Blob.fromBytes(haxe.io.Bytes.ofData(data));
			}
#end
#if WITH_JSON
			var parsed:TSceneFormat = haxe.Json.parse(blob.toString());
#else
			var parsed:TSceneFormat = iron.data.msgpack.MsgPack.decode(blob.toBytes());
#end
			cachedSceneRaws.set(file, parsed);
			return parsed;
		}
		else {
			return cached;
		}	
	}

	public static function getMeshRawByName(datas:Array<TMeshData>, name:String):TMeshData {
		if (name == "") return datas[0];
		for (dat in datas) {
			if (dat.name == name) return dat;
		}
		return null;
	}

	public static function getLampRawByName(datas:Array<TLampData>, name:String):TLampData {
		if (name == "") return datas[0];
		for (dat in datas) {
			if (dat.name == name) return dat;
		}
		return null;
	}

	public static function getCameraRawByName(datas:Array<TCameraData>, name:String):TCameraData {
		if (name == "") return datas[0];
		for (dat in datas) {
			if (dat.name == name) return dat;
		}
		return null;
	}

	public static function getRenderPathRawByName(datas:Array<TRenderPathData>, name:String):TRenderPathData {
		if (name == "") return datas[0];
		for (dat in datas) {
			if (dat.name == name) return dat;
		}
		return null;
	}

	public static function getMaterialRawByName(datas:Array<TMaterialData>, name:String):TMaterialData {
		if (name == "") return datas[0];
		for (dat in datas) {
			if (dat.name == name) return dat;
		}
		return null;
	}

	public static function getParticleRawByName(datas:Array<TParticleData>, name:String):TParticleData {
		if (name == "") return datas[0];
		for (dat in datas) {
			if (dat.name == name) return dat;
		}
		return null;
	}

	public static function getWorldRawByName(datas:Array<TWorldData>, name:String):TWorldData {
		if (name == "") return datas[0];
		for (dat in datas) {
			if (dat.name == name) return dat;
		}
		return null;
	}

	public static function getShaderRawByName(datas:Array<TShaderData>, name:String):TShaderData {
		if (name == "") return datas[0];
		for (dat in datas) {
			if (dat.name == name) return dat;
		}
		return null;
	}

	public static function getSpeakerRawByName(datas:Array<TSpeakerData>, name:String):TSpeakerData {
		if (name == "") return datas[0];
		for (dat in datas) {
			if (dat.name == name) return dat;
		}
		return null;
	}
}
