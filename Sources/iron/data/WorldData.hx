package iron.data;

import kha.Image;
import iron.math.Vec4;
import iron.object.Transform;
import iron.data.SceneFormat;

class WorldData {

	public var name:String;
	public var raw:TWorldData;
	public var envmap:Image;
	public var probe:Probe;
	
	static var emptyIrr:kha.arrays.Float32Array = null;
	
	public function new(raw:TWorldData, done:WorldData->Void) {
		this.raw = raw;
		this.name = raw.name;
		
		// Parse probes
		if (raw.probe != null) {
			new Probe(raw.probe, function(self:Probe) {
				probe = self;
				loadEnvmap(done);
			});
		}
		else loadEnvmap(done);
	}

	function loadEnvmap(done:WorldData->Void) {
		if (raw.envmap != null) {
			iron.data.Data.getImage(raw.envmap, function(image:kha.Image) {
				envmap = image;
				done(this);
			});
		}
		else done(this);
	}

	public static function parse(name:String, id:String, done:WorldData->Void) {
		Data.getSceneRaw(name, function(format:TSceneFormat) {
			var raw:TWorldData = Data.getWorldRawByName(format.world_datas, id);
			if (raw == null) {
				trace('World data "$id" not found!');
				done(null);
			}
			new WorldData(raw, done);
		});
	}

	public static function getEmptyIrradiance():kha.arrays.Float32Array {
		if (emptyIrr == null) {
			emptyIrr = new kha.arrays.Float32Array(28);
			for (i in 0...emptyIrr.length) emptyIrr.set(i, 0.0);
		}
		return emptyIrr;
	}
}

class Probe {
	
	public var raw:TProbeData;
	public var radiance:Image;
	public var radianceMipmaps:Array<kha.Image> = [];
	public var irradiance:kha.arrays.Float32Array;
	
	public function new(raw:TProbeData, done:Probe->Void) {
		this.raw = raw;
		
		setIrradiance(function(irr:kha.arrays.Float32Array) {
			irradiance = irr;
		
			if (raw.radiance != null) {
				
				iron.data.Data.getImage(raw.radiance, function(rad:kha.Image) {

					radiance = rad;
					while (radianceMipmaps.length < raw.radiance_mipmaps) radianceMipmaps.push(null);
					var ext = raw.radiance.substring(raw.radiance.length - 4);
					var base = raw.radiance.substring(0, raw.radiance.length - 4);

					var mipsLoaded = 0;
					for (i in 0...raw.radiance_mipmaps) {
						iron.data.Data.getImage(base + '_' + i + ext, function(mipimg:kha.Image) {
							radianceMipmaps[i] = mipimg;
							mipsLoaded++;
							
							if (mipsLoaded == raw.radiance_mipmaps) {
								radiance.setMipmaps(radianceMipmaps);
								done(this);
							}
						}, true); // Readable
					}
				});
			}
			else done(this);
		});
	}

	function setIrradiance(done:kha.arrays.Float32Array->Void) {
		// Parse probe data
		if (raw.irradiance == null) {
			// Use default if no data provided
			var ar:Array<kha.FastFloat> = [0.775966, 1.167610, 1.498638, 0.133694, 0.215281, 0.056659, -0.022268, -0.019376, -0.010651, 0.000279, 0.000185, 0.0, 0.0, -0.000393, -0.000775, 0.010973, 0.027268, 0.043918, 0.085267, 0.073670, 0.038877, 0.0, 0.0, 0.0, 0.135177, 0.115614, 0.060794];
			var far = new kha.arrays.Float32Array(ar.length);
			for (i in 0...far.length) far[i] = ar[i];
			done(far);
		}
		else {
			var ext = StringTools.endsWith(raw.irradiance, '.json') ? '' : '.arm';
			iron.data.Data.getBlob(raw.irradiance + ext, function(b:kha.Blob) {
				var irradianceParsed:TSceneFormat = ext == '' ?
					haxe.Json.parse(b.toString()) :
					iron.system.ArmPack.decode(b.toBytes());
				var irr = new kha.arrays.Float32Array(28); // Align to mult of 4 - 27->28
				for (i in 0...27) irr[i] = irradianceParsed.irradiance[i];
				irr[27] = 0.0;
				done(irr);
			});
		}
	}
}
