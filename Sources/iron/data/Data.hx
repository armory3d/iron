package iron.data;
import haxe.io.BytesInput;
import haxe.zip.Reader;
import iron.data.SceneFormat;

// Global data list and asynchronous data loading
class Data {

	// TODO: get rid of maps..
	static var cachedSceneRaws:Map<String, TSceneFormat> = new Map();
	static var cachedMeshes:Map<String, MeshData> = new Map();
	static var cachedLamps:Map<String, LampData> = new Map();
	static var cachedCameras:Map<String, CameraData> = new Map();
	static var cachedRenderPaths:Map<String, RenderPathData> = new Map();
	static var cachedMaterials:Map<String, MaterialData> = new Map();
	static var cachedParticles:Map<String, ParticleData> = new Map();
	static var cachedWorlds:Map<String, WorldData> = new Map();
	static var cachedGreasePencils:Map<String, GreasePencilData> = new Map();
	static var cachedShaders:Map<String, ShaderData> = new Map();

	static var cachedBlobs:Map<String, kha.Blob> = new Map();
	static var cachedImages:Map<String, kha.Image> = new Map();
	static var cachedSounds:Map<String, kha.Sound> = new Map();
	static var cachedVideos:Map<String, kha.Video> = new Map();
	static var cachedFonts:Map<String, kha.Font> = new Map();

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
		cachedGreasePencils = new Map();
		cachedShaders = new Map();

		cachedBlobs = new Map();
		cachedImages = new Map();
		cachedSounds = new Map();
		cachedVideos = new Map();
		cachedFonts = new Map();
	}

	// Experimental scene patching
	public static function clearSceneData() {
		cachedSceneRaws = new Map();
		cachedMeshes = new Map(); // Delete data
		cachedLamps = new Map();
		cachedMaterials = new Map();
		cachedRenderPaths = new Map();
		cachedCameras = new Map();
		cachedParticles = new Map();
		cachedWorlds = new Map();
		// cachedGreasePencils = new Map();
		// cachedShaders = new Map(); // Slow
		cachedBlobs = new Map();
	}

	static var loadingMeshes:Map<String, Array<MeshData->Void>> = new Map();
	public static function getMesh(file:String, name:String, boneObjects:Array<TObj>, done:MeshData->Void) {
		// boneObjects - used when mesh is parsed from separate file
		// TODO: preparse bone objects
		var cached = cachedMeshes.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingMeshes.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingMeshes.set(file + name, [done]);

		MeshData.parse(file, name, boneObjects, function(b:MeshData) {
			cachedMeshes.set(file + name, b);
			for (f in loadingMeshes.get(file + name)) f(b);
			loadingMeshes.remove(file + name);
		});
	}

	static var loadingLamps:Map<String, Array<LampData->Void>> = new Map();
	public static function getLamp(file:String, name:String, done:LampData->Void) {
		var cached = cachedLamps.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingLamps.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingLamps.set(file + name, [done]);

		LampData.parse(file, name, function(b:LampData) {
			cachedLamps.set(file + name, b);
			for (f in loadingLamps.get(file + name)) f(b);
			loadingLamps.remove(file + name);
		});
	}

	static var loadingCameras:Map<String, Array<CameraData->Void>> = new Map();
	public static function getCamera(file:String, name:String, done:CameraData->Void) {
		var cached = cachedCameras.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingCameras.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingCameras.set(file + name, [done]);

		CameraData.parse(file, name, function(b:CameraData) {
			cachedCameras.set(file + name, b);
			for (f in loadingCameras.get(file + name)) f(b);
			loadingCameras.remove(file + name);
		});
	}

	static var loadingRenderPaths:Map<String, Array<RenderPathData->Void>> = new Map();
	public static function getRenderPath(file:String, name:String, done:RenderPathData->Void) {
		var cached = cachedRenderPaths.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingRenderPaths.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingRenderPaths.set(file + name, [done]);

		RenderPathData.parse(file, name, function(b:RenderPathData) {
			cachedRenderPaths.set(file + name, b);
			for (f in loadingRenderPaths.get(file + name)) f(b);
			loadingRenderPaths.remove(file + name);
		});
	}

	static var loadingMaterials:Map<String, Array<MaterialData->Void>> = new Map();
	public static function getMaterial(file:String, name:String, done:MaterialData->Void) {
		var cached = cachedMaterials.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingMaterials.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingMaterials.set(file + name, [done]);

		MaterialData.parse(file, name, function(b:MaterialData) {
			cachedMaterials.set(file + name, b);
			for (f in loadingMaterials.get(file + name)) f(b);
			loadingMaterials.remove(file + name);
		});
	}

	static var loadingParticles:Map<String, Array<ParticleData->Void>> = new Map();
	public static function getParticle(file:String, name:String, done:ParticleData->Void) {
		var cached = cachedParticles.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingParticles.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingParticles.set(file + name, [done]);

		ParticleData.parse(file, name, function(b:ParticleData) {
			cachedParticles.set(file + name, b);
			for (f in loadingParticles.get(file + name)) f(b);
			loadingParticles.remove(file + name);
		});
	}

	static var loadingWorlds:Map<String, Array<WorldData->Void>> = new Map();
	public static function getWorld(file:String, name:String, done:WorldData->Void) {
		var cached = cachedWorlds.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingWorlds.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingWorlds.set(file + name, [done]);

		WorldData.parse(file, name, function(b:WorldData) {
			cachedWorlds.set(file + name, b);
			for (f in loadingWorlds.get(file + name)) f(b);
			loadingWorlds.remove(file + name);
		});
	}

	static var loadingGreasePencils:Map<String, Array<GreasePencilData->Void>> = new Map();
	public static function getGreasePencil(file:String, name:String, done:GreasePencilData->Void) {
		var cached = cachedGreasePencils.get(file + name);
		if (cached != null) { done(cached); return; }

		var loading = loadingGreasePencils.get(file + name);
		if (loading != null) { loading.push(done); return; }

		loadingGreasePencils.set(file + name, [done]);

		GreasePencilData.parse(file, name, function(b:GreasePencilData) {
			cachedGreasePencils.set(file + name, b);
			for (f in loadingGreasePencils.get(file + name)) f(b);
			loadingGreasePencils.remove(file + name);
		});
	}

	static var loadingShaders:Map<String, Array<ShaderData->Void>> = new Map();
	public static function getShader(file:String, name:String, overrideContext:TShaderOverride, done:ShaderData->Void) {
		// Only one context override per shader data for now
		var cacheName = name;
		if (overrideContext != null) cacheName += "2";
		var cached = cachedShaders.get(cacheName); // Shader must have unique name
		if (cached != null) { done(cached); return; }

		var loading = loadingShaders.get(cacheName);
		if (loading != null) { loading.push(done); return; }

		loadingShaders.set(cacheName, [done]);

		ShaderData.parse(file, name, overrideContext, function(b:ShaderData) {
			cachedShaders.set(cacheName, b);
			for (f in loadingShaders.get(cacheName)) f(b);
			loadingShaders.remove(cacheName);
		});
	}

	static var loadingSceneRaws:Map<String, Array<TSceneFormat->Void>> = new Map();
	public static function getSceneRaw(file:String, done:TSceneFormat->Void) {
		var cached = cachedSceneRaws.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingSceneRaws.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingSceneRaws.set(file, [done]);

		// If no extension specified, set to .arm
		var compressed = StringTools.endsWith(file, '.zip');
		var ext = (compressed || StringTools.endsWith(file, '.arm')) ? '' : '.arm';

		getBlob(file + ext, function(b:kha.Blob) {

			if (compressed) {
				var input = new BytesInput(b.toBytes());
				var entry = Reader.readZip(input).first();
				if (entry == null) {
					trace('Failed to uncompress ' + file);
					return;
				}
				if (entry.compressed) b = kha.Blob.fromBytes(Reader.unzip(entry));
				else b = kha.Blob.fromBytes(entry.data);
			}

#if arm_json
			var parsed:TSceneFormat = haxe.Json.parse(b.toString());
#else
			var parsed:TSceneFormat = iron.system.msgpack.MsgPack.decode(b.toBytes());
#end
			cachedSceneRaws.set(file, parsed);
			for (f in loadingSceneRaws.get(file)) f(parsed);
			loadingSceneRaws.remove(file);
		});
	}

	public static function getMeshRawByName(datas:Array<TMeshData>, name:String):TMeshData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getLampRawByName(datas:Array<TLampData>, name:String):TLampData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getCameraRawByName(datas:Array<TCameraData>, name:String):TCameraData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getRenderPathRawByName(datas:Array<TRenderPathData>, name:String):TRenderPathData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getMaterialRawByName(datas:Array<TMaterialData>, name:String):TMaterialData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getParticleRawByName(datas:Array<TParticleData>, name:String):TParticleData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getWorldRawByName(datas:Array<TWorldData>, name:String):TWorldData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getGreasePencilRawByName(datas:Array<TGreasePencilData>, name:String):TGreasePencilData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getShaderRawByName(datas:Array<TShaderData>, name:String):TShaderData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getSpeakerRawByName(datas:Array<TSpeakerData>, name:String):TSpeakerData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	// Raw assets
	public static var assetsLoaded = 0;

	static var loadingBlobs:Map<String, Array<kha.Blob->Void>> = new Map();
	public static function getBlob(file:String, done:kha.Blob->Void) {
		var cached = cachedBlobs.get(file); // Is already cached
		if (cached != null) { done(cached); return; }

		var loading = loadingBlobs.get(file); // Is already being loaded
		if (loading != null) { loading.push(done); return; }

		loadingBlobs.set(file, [done]); // Start loading

		var description = { files: [file] };
		kha.LoaderImpl.loadBlobFromDescription(description, function(b:kha.Blob) {
			cachedBlobs.set(file, b);
			for (f in loadingBlobs.get(file)) f(b);
			loadingBlobs.remove(file);
			assetsLoaded++;
		});
	}

	static var loadingImages:Map<String, Array<kha.Image->Void>> = new Map();
	public static function getImage(file:String, done:kha.Image->Void, readable = false, format = 'RGBA32') {
#if cpp
		if (StringTools.endsWith(file, '.png')) file = file.substring(0, file.length - 4) + '.kng';
#end

		var cached = cachedImages.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingImages.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingImages.set(file, [done]);

		// TODO: process format in Kha
		var description = { files: [file], readable: readable, format: format };
		kha.LoaderImpl.loadImageFromDescription(description, function(b:kha.Image) {
			cachedImages.set(file, b);
			for (f in loadingImages.get(file)) f(b);
			loadingImages.remove(file);
			assetsLoaded++;
		});
	}

	static var loadingSounds:Map<String, Array<kha.Sound->Void>> = new Map();
	public static function getSound(file:String, done:kha.Sound->Void) {

		if (StringTools.endsWith(file, '.wav')) file = file.substring(0, file.length - 4) + '.ogg';

		var cached = cachedSounds.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingSounds.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingSounds.set(file, [done]);

		var description = { files: [file] };
		kha.LoaderImpl.loadSoundFromDescription(description, function(b:kha.Sound) {
			b.uncompress(function () {
				cachedSounds.set(file, b);
				for (f in loadingSounds.get(file)) f(b);
				loadingSounds.remove(file);
				assetsLoaded++;
			});
		});
	}

	static var loadingVideos:Map<String, Array<kha.Video->Void>> = new Map();
	public static function getVideo(file:String, done:kha.Video->Void) {
		// TODO: fix extension
		var cached = cachedVideos.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingVideos.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingVideos.set(file, [done]);

		var description = { files: [file] };
		kha.LoaderImpl.loadVideoFromDescription(description, function(b:kha.Video) {
			cachedVideos.set(file, b);
			for (f in loadingVideos.get(file)) f(b);
			loadingVideos.remove(file);
			assetsLoaded++;
		});
	}

	static var loadingFonts:Map<String, Array<kha.Font->Void>> = new Map();
	public static function getFont(file:String, done:kha.Font->Void) {
		var cached = cachedFonts.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingFonts.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingFonts.set(file, [done]);

		var description = { files: [file] };
		kha.LoaderImpl.loadFontFromDescription(description, function(b:kha.Font) {
			cachedFonts.set(file, b);
			for (f in loadingFonts.get(file)) f(b);
			loadingFonts.remove(file);
			assetsLoaded++;
		});
	}
}
