package iron.data;

import kha.Image;
import iron.math.Vec4;
import iron.object.Transform;
import iron.data.SceneFormat;

class WorldData extends Data {

	public var name:String;
	public var raw:TWorldData;
	
	var probes:Array<Probe>; 

	static var emptyIrr:haxe.ds.Vector<kha.FastFloat> = null;
	
	public function new(raw:TWorldData, done:WorldData->Void) {
		super();

		this.raw = raw;
		this.name = raw.name;
		
		// Parse probes
		if (raw.probes != null && raw.probes.length > 0) {
			probes = [];
			for (p in raw.probes) {
				new Probe(p, function(self:Probe) {
					probes.push(self);
					if (probes.length == raw.probes.length) done(this);
				});
			}
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

	public static function getEmptyIrradiance():haxe.ds.Vector<kha.FastFloat> {
		if (emptyIrr == null) {
			emptyIrr = new haxe.ds.Vector<kha.FastFloat>(28);
			for (i in 0...emptyIrr.length) emptyIrr.set(i, 0.0);
		}
		return emptyIrr;
	}
	
	public function getGlobalProbe():Probe {
		return probes[0];
	}
	
	public function getLocalProbe(i:Int):Probe {
		return i < probes.length ? probes[i] : null;
	}
	
	var shirr:haxe.ds.Vector<kha.FastFloat> = null;
	public function getSHIrradiance():haxe.ds.Vector<kha.FastFloat> {
		// Fetch spherical harmonics from probe
		if (shirr == null) {
			shirr = new haxe.ds.Vector(28);
			// for (i in 0...probes.length) {
				var p = probes[0];
				for (j in 0...p.irradiance.length) {
					shirr[j] = p.irradiance[j];
				}
			// }
		}
		return shirr;
	}
	
	var vec = new Vec4();
	public function getProbeID(t:Transform):Int {
		vec.x = t.worldx();
		vec.y = t.worldy();
		vec.z = t.worldz();
		var dim = t.dim;
		for (i in 1...probes.length) {
			var p = probes[i];
			// Transform not in volume
			if (vec.x + dim.x / 2 < p.volumeMin.x || vec.x - dim.x / 2 > p.volumeMax.x ||
				vec.y + dim.y / 2 < p.volumeMin.y || vec.y - dim.y / 2 > p.volumeMax.y ||
				vec.z + dim.z / 2 < p.volumeMin.z || vec.z - dim.z / 2 > p.volumeMax.z) {
				continue;
			}
			// Transform intersects volume
			return i;
		}
		return 0;
	}
	
	public function getProbeVolumeCenter(t:Transform):Vec4 {
		return probes[getProbeID(t)].volumeCenter;
	}
	
	public function getProbeVolumeSize(t:Transform):Vec4 {
		return probes[getProbeID(t)].volume;
	}

	public function getProbeStrength(t:Transform):Float {
		return probes[getProbeID(t)].raw.strength;
	}

	public function getProbeBlending(t:Transform):Float {
		return probes[getProbeID(t)].raw.blending;
	}
}

class Probe {
	
	public var raw:TProbe;
	public var radiance:Image;
	public var irradiance:haxe.ds.Vector<kha.FastFloat>;
	public var volume:Vec4;
	public var volumeCenter:Vec4;
	public var volumeMin:Vec4;
	public var volumeMax:Vec4;
	
	public function new(raw:TProbe, done:Probe->Void) {
		this.raw = raw;
		
		setIrradiance(function(irr:haxe.ds.Vector<kha.FastFloat>) {
			irradiance = irr;
		
			if (raw.radiance != null) {
				
				iron.data.Data.getImage(raw.radiance, function(rad:kha.Image) {

					radiance = rad;
					var radianceMipmaps:Array<kha.Image> = [];
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
								mipsSet(done);
							}
						}, true); // Readable
					}
				});
			}
			else mipsSet(done);
		});
	}

	function mipsSet(done:Probe->Void) {
		// Cube half-extents
		volume = new Vec4(raw.volume[0], raw.volume[1], raw.volume[2]);
		volumeCenter = new Vec4(raw.volume_center[0], raw.volume_center[1], raw.volume_center[2]);
	
		volumeMin = new Vec4(volumeCenter.x - volume.x, volumeCenter.y - volume.y, volumeCenter.z - volume.z);
		volumeMax = new Vec4(volumeCenter.x + volume.x, volumeCenter.y + volume.y, volumeCenter.z + volume.z);

		done(this);
	}

	function setIrradiance(done:haxe.ds.Vector<kha.FastFloat>->Void) {
		// Parse probe data
		if (raw.irradiance == '') {
			// Use default if no data provided
			var ar:Array<kha.FastFloat> = [0.7759665994411109, 1.1676103577251633, 1.498638725994038, 0.1336947481217397, 0.2152815237067897, 0.05665912629858376, -0.02226816760879319, -0.019376587567080147, -0.010651384270937897, 0.000279290102432495, 0.0001858273851672515, 6.33030727032015e-05, -6.78543609893525e-05, -0.0003936997772915445, -0.0007750453454300294, 0.010973699524451886, 0.02726825295855786, 0.04391820633315139, 0.08526796789315332, 0.07367063541652231, 0.03887702349408202, -1.34621815948975e-05, -3.9675084850967e-05, -3.7799572176155e-05, 0.13517727692935497, 0.11561459222778457, 0.06079408647605916];
			done(haxe.ds.Vector.fromData(ar));
		}
		else {
			iron.data.Data.getBlob(raw.irradiance + '.arm', function(b:kha.Blob) {
				var irradianceData = b;
				#if arm_json
				var irradianceParsed:TIrradiance = haxe.Json.parse(irradianceData.toString());
				#else
				var irradianceParsed:TIrradiance = iron.system.ArmPack.decode(irradianceData.toBytes());
				#end
				var irr = new haxe.ds.Vector(28); // Align to mult of 4 - 27->28
				for (i in 0...27) irr.set(i, irradianceParsed.irradiance[i]); 
				irr.set(27, 0.0);
				done(irr);
			});
		}
	}
}
