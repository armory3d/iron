package iron.data;
import haxe.io.BytesInput;
import iron.data.SceneFormat;

// Global data list and asynchronous data loading
class Data {

	public static var cachedSceneRaws:Map<String, TSceneFormat> = new Map();
	public static var cachedMeshes:Map<String, MeshData> = new Map();
	public static var cachedLights:Map<String, LightData> = new Map();
	public static var cachedCameras:Map<String, CameraData> = new Map();
	public static var cachedMaterials:Map<String, MaterialData> = new Map();
	public static var cachedParticles:Map<String, ParticleData> = new Map();
	public static var cachedWorlds:Map<String, WorldData> = new Map();
	// public static var cachedGreasePencils:Map<String, GreasePencilData> = new Map();
	public static var cachedShaders:Map<String, ShaderData> = new Map();
	#if rp_probes
	public static var cachedProbes:Map<String, ProbeData> = new Map();
	#end

	public static var cachedBlobs:Map<String, kha.Blob> = new Map();
	public static var cachedImages:Map<String, kha.Image> = new Map();
	public static var cachedSounds:Map<String, kha.Sound> = new Map();
	public static var cachedVideos:Map<String, kha.Video> = new Map();
	public static var cachedFonts:Map<String, kha.Font> = new Map();

	#if arm_data_dir
	public static var dataPath = './data/';
	#else
	public static var dataPath = '';
	#end

	public function new() { }

	public static function deleteAll() {
		for (c in cachedMeshes) c.delete();
		cachedMeshes = new Map();
		for (c in cachedShaders) c.delete();
		cachedShaders = new Map();
		cachedSceneRaws = new Map();
		cachedLights = new Map();
		cachedCameras = new Map();
		cachedMaterials = new Map();
		cachedParticles = new Map();
		cachedWorlds = new Map();
		// cachedGreasePencils = new Map();
		if (RenderPath.active != null) RenderPath.active.unload();

		for (c in cachedBlobs) c.unload();
		cachedBlobs = new Map();
		for (c in cachedImages) c.unload();
		cachedImages = new Map();
		for (c in cachedSounds) c.unload();
		cachedSounds = new Map();
		for (c in cachedVideos) c.unload();
		cachedVideos = new Map();
		for (c in cachedFonts) c.unload();
		cachedFonts = new Map();
	}

	// Experimental scene patching
	public static function clearSceneData() {
		cachedSceneRaws = new Map();
		cachedMeshes = new Map(); // Delete data
		cachedLights = new Map();
		cachedMaterials = new Map();
		cachedCameras = new Map();
		cachedParticles = new Map();
		cachedWorlds = new Map();
		// cachedGreasePencils = new Map();
		cachedShaders = new Map(); // Slow
		cachedBlobs = new Map();
	}

	static var loadingMeshes:Map<String, Array<MeshData->Void>> = new Map();
	public static function getMesh(file:String, name:String, done:MeshData->Void) {
		var handle = file + name;
		var cached = cachedMeshes.get(handle);
		if (cached != null) { done(cached); return; }

		var loading = loadingMeshes.get(handle);
		if (loading != null) { loading.push(done); return; }

		loadingMeshes.set(handle, [done]);

		MeshData.parse(file, name, function(b:MeshData) {
			cachedMeshes.set(handle, b);
			b.handle = handle;
			for (f in loadingMeshes.get(handle)) f(b);
			loadingMeshes.remove(handle);
		});
	}

	public static function deleteMesh(handle:String) {
		// Remove cached mesh
		var mesh = cachedMeshes.get(handle);
		if (mesh == null) return;
		mesh.delete();
		cachedMeshes.remove(handle);
	}

	static var loadingLights:Map<String, Array<LightData->Void>> = new Map();
	public static function getLight(file:String, name:String, done:LightData->Void) {
		var handle = file + name;
		var cached = cachedLights.get(handle);
		if (cached != null) { done(cached); return; }

		var loading = loadingLights.get(handle);
		if (loading != null) { loading.push(done); return; }

		loadingLights.set(handle, [done]);

		LightData.parse(file, name, function(b:LightData) {
			cachedLights.set(handle, b);
			for (f in loadingLights.get(handle)) f(b);
			loadingLights.remove(handle);
		});
	}

	#if rp_probes
	static var loadingProbes:Map<String, Array<ProbeData->Void>> = new Map();
	public static function getProbe(file:String, name:String, done:ProbeData->Void) {
		var handle = file + name;
		var cached = cachedProbes.get(handle);
		if (cached != null) { done(cached); return; }

		var loading = loadingProbes.get(handle);
		if (loading != null) { loading.push(done); return; }

		loadingProbes.set(handle, [done]);

		ProbeData.parse(file, name, function(b:ProbeData) {
			cachedProbes.set(handle, b);
			for (f in loadingProbes.get(handle)) f(b);
			loadingProbes.remove(handle);
		});
	}
	#end

	static var loadingCameras:Map<String, Array<CameraData->Void>> = new Map();
	public static function getCamera(file:String, name:String, done:CameraData->Void) {
		var handle = file + name;
		var cached = cachedCameras.get(handle);
		if (cached != null) { done(cached); return; }

		var loading = loadingCameras.get(handle);
		if (loading != null) { loading.push(done); return; }

		loadingCameras.set(handle, [done]);

		CameraData.parse(file, name, function(b:CameraData) {
			cachedCameras.set(handle, b);
			for (f in loadingCameras.get(handle)) f(b);
			loadingCameras.remove(handle);
		});
	}

	static var loadingMaterials:Map<String, Array<MaterialData->Void>> = new Map();
	public static function getMaterial(file:String, name:String, done:MaterialData->Void) {
		var handle = file + name;
		var cached = cachedMaterials.get(handle);
		if (cached != null) { done(cached); return; }

		var loading = loadingMaterials.get(handle);
		if (loading != null) { loading.push(done); return; }

		loadingMaterials.set(handle, [done]);

		MaterialData.parse(file, name, function(b:MaterialData) {
			cachedMaterials.set(handle, b);
			for (f in loadingMaterials.get(handle)) f(b);
			loadingMaterials.remove(handle);
		});
	}

	static var loadingParticles:Map<String, Array<ParticleData->Void>> = new Map();
	public static function getParticle(file:String, name:String, done:ParticleData->Void) {
		var handle = file + name;
		var cached = cachedParticles.get(handle);
		if (cached != null) { done(cached); return; }

		var loading = loadingParticles.get(handle);
		if (loading != null) { loading.push(done); return; }

		loadingParticles.set(handle, [done]);

		ParticleData.parse(file, name, function(b:ParticleData) {
			cachedParticles.set(handle, b);
			for (f in loadingParticles.get(handle)) f(b);
			loadingParticles.remove(handle);
		});
	}

	static var loadingWorlds:Map<String, Array<WorldData->Void>> = new Map();
	public static function getWorld(file:String, name:String, done:WorldData->Void) {
		if (name == null) { done(null); return; } // No world defined in scene

		var handle = file + name;
		var cached = cachedWorlds.get(handle);
		if (cached != null) { done(cached); return; }

		var loading = loadingWorlds.get(handle);
		if (loading != null) { loading.push(done); return; }

		loadingWorlds.set(handle, [done]);

		WorldData.parse(file, name, function(b:WorldData) {
			cachedWorlds.set(handle, b);
			for (f in loadingWorlds.get(handle)) f(b);
			loadingWorlds.remove(handle);
		});
	}

	// static var loadingGreasePencils:Map<String, Array<GreasePencilData->Void>> = new Map();
	// public static function getGreasePencil(file:String, name:String, done:GreasePencilData->Void) {
	//	var handle = file + name;
	// 	var cached = cachedGreasePencils.get(handle);
	// 	if (cached != null) { done(cached); return; }

	// 	var loading = loadingGreasePencils.get(handle);
	// 	if (loading != null) { loading.push(done); return; }

	// 	loadingGreasePencils.set(handle, [done]);

	// 	GreasePencilData.parse(file, name, function(b:GreasePencilData) {
	// 		cachedGreasePencils.set(handle, b);
	// 		for (f in loadingGreasePencils.get(handle)) f(b);
	// 		loadingGreasePencils.remove(handle);
	// 	});
	// }

	static var loadingShaders:Map<String, Array<ShaderData->Void>> = new Map();
	public static function getShader(file:String, name:String, done:ShaderData->Void, overrideContext:TShaderOverride = null) {
		// Only one context override per shader data for now
		var cacheName = name;
		if (overrideContext != null) cacheName += "2";
		var cached = cachedShaders.get(cacheName); // Shader must have unique name
		if (cached != null) { done(cached); return; }

		var loading = loadingShaders.get(cacheName);
		if (loading != null) { loading.push(done); return; }

		loadingShaders.set(cacheName, [done]);

		ShaderData.parse(file, name, function(b:ShaderData) {
			cachedShaders.set(cacheName, b);
			for (f in loadingShaders.get(cacheName)) f(b);
			loadingShaders.remove(cacheName);
		}, overrideContext);
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
		var isJson = StringTools.endsWith(file, '.json');
		var ext = (compressed || isJson || StringTools.endsWith(file, '.arm')) ? '' : '.arm';

		getBlob(file + ext, function(b:kha.Blob) {

			if (compressed) {
				#if (arm_compress && !hl) // TODO: korehl - unresolved external symbol _fmt_inflate_buffer
				var input = new BytesInput(b.toBytes());
				var entry = haxe.zip.Reader.readZip(input).first();
				if (entry == null) {
					trace('Failed to uncompress ' + file);
					return;
				}
				if (entry.compressed) b = kha.Blob.fromBytes(haxe.zip.Reader.unzip(entry));
				else b = kha.Blob.fromBytes(entry.data);
				#end
			}

			var parsed:TSceneFormat = null;
			if (isJson) {
				var s = b.toString();
				parsed = s.charAt(0) == "{" ? haxe.Json.parse(s) : iron.system.ArmPack.decode(b.toBytes());
			}
			else {
				parsed = iron.system.ArmPack.decode(b.toBytes());
			}

			returnSceneRaw(file, parsed);
		});
	}

	static function returnSceneRaw(file:String, parsed:TSceneFormat) {
		cachedSceneRaws.set(file, parsed);
		for (f in loadingSceneRaws.get(file)) f(parsed);
		loadingSceneRaws.remove(file);
	}

	public static function getMeshRawByName(datas:Array<TMeshData>, name:String):TMeshData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	public static function getLightRawByName(datas:Array<TLightData>, name:String):TLightData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}

	#if rp_probes
	public static function getProbeRawByName(datas:Array<TProbeData>, name:String):TProbeData {
		if (name == "") return datas[0];
		for (dat in datas) if (dat.name == name) return dat;
		return null;
	}
	#end

	public static function getCameraRawByName(datas:Array<TCameraData>, name:String):TCameraData {
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

	// public static function getGreasePencilRawByName(datas:Array<TGreasePencilData>, name:String):TGreasePencilData {
	// 	if (name == "") return datas[0];
	// 	for (dat in datas) if (dat.name == name) return dat;
	// 	return null;
	// }

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

		var p = (file.charAt(0) == '/' || file.charAt(1) == ':') ? file : dataPath + file;

		kha.Assets.loadBlobFromPath(p, function(b:kha.Blob) {
			cachedBlobs.set(file, b);
			for (f in loadingBlobs.get(file)) f(b);
			loadingBlobs.remove(file);
			assetsLoaded++;
		});
	}

	static var loadingImages:Map<String, Array<kha.Image->Void>> = new Map();
	public static function getImage(file:String, done:kha.Image->Void, readable = false, format = 'RGBA32') {
		#if (cpp || hl)
		file = file.substring(0, file.length - 4) + '.k';
		#end

		var cached = cachedImages.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingImages.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingImages.set(file, [done]);

		var p = (file.charAt(0) == '/' || file.charAt(1) == ':') ? file : dataPath + file;

		// TODO: process format in Kha
		kha.Assets.loadImageFromPath(p, readable, function(b:kha.Image) {
			cachedImages.set(file, b);
			for (f in loadingImages.get(file)) f(b);
			loadingImages.remove(file);
			assetsLoaded++;
		});
	}

	public static function deleteImage(handle:String) {
		var image = cachedImages.get(handle);
		if (image == null) return;
		image.unload();
		cachedImages.remove(handle);
	}

	static var loadingSounds:Map<String, Array<kha.Sound->Void>> = new Map();
	/**
	 * Load sound file from disk into ram.
	 *
	 * @param	file A String matching the file name of the sound file on disk.
	 * @param	done Completion handler function to do something after the sound is loaded.
	 */
	public static function getSound(file:String, done:kha.Sound->Void) {
		#if arm_no_audio
		done(null);
		return;
		#end

		#if arm_soundcompress
		if (StringTools.endsWith(file, '.wav')) file = file.substring(0, file.length - 4) + '.ogg';
		#end

		var cached = cachedSounds.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingSounds.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingSounds.set(file, [done]);

		var p = (file.charAt(0) == '/' || file.charAt(1) == ':') ? file : dataPath + file;

		kha.Assets.loadSoundFromPath(p, function(b:kha.Sound) {
			#if arm_soundcompress
			b.uncompress(function () {
			#end
				cachedSounds.set(file, b);
				for (f in loadingSounds.get(file)) f(b);
				loadingSounds.remove(file);
				assetsLoaded++;
			#if arm_soundcompress
			});
			#end
		});
	}

	static var loadingVideos:Map<String, Array<kha.Video->Void>> = new Map();
	public static function getVideo(file:String, done:kha.Video->Void) {
		#if (cpp || hl)
		file = file.substring(0, file.length - 4) + '.avi';
		#end
		var cached = cachedVideos.get(file);
		if (cached != null) { done(cached); return; }

		var loading = loadingVideos.get(file);
		if (loading != null) { loading.push(done); return; }

		loadingVideos.set(file, [done]);

		var p = (file.charAt(0) == '/' || file.charAt(1) == ':') ? file : dataPath + file;

		kha.Assets.loadVideoFromPath(p, function(b:kha.Video) {
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

		var p = (file.charAt(0) == '/' || file.charAt(1) == ':') ? file : dataPath + file;

		kha.Assets.loadFontFromPath(p, function(b:kha.Font) {
			cachedFonts.set(file, b);
			for (f in loadingFonts.get(file)) f(b);
			loadingFonts.remove(file);
			assetsLoaded++;
		});
	}
}
