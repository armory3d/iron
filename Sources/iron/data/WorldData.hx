package iron.data;

import kha.Image;
import iron.math.Vec4;
import iron.object.Transform;
import iron.data.SceneFormat;

class WorldData extends Data {

	public var name:String;
	public var raw:TWorldData;
	
	var probes:Array<Probe>; 
	public var brdf:Image;
	
	public function new(raw:TWorldData, done:WorldData->Void) {
		super();

		this.raw = raw;
		this.name = raw.name;

		iron.data.Data.getImage(raw.brdf, function(image:kha.Image) {
			brdf = image;
		
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
		});
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
	
	public function getGlobalProbe():Probe {
		return probes[0];
	}
	
	public function getLocalProbe(i:Int):Probe {
		return i < probes.length ? probes[i] : null;
	}
	
	var shirr:haxe.ds.Vector<kha.FastFloat> = null;
	public function getSHIrradiance():haxe.ds.Vector<kha.FastFloat> {
		// Fetch spherical harmonics from all probes
		if (shirr == null) {
			shirr = new haxe.ds.Vector(27 * 6); // Just 6 sets for now
			for (i in 0...probes.length) {
				var p = probes[i];
				for (j in 0...p.irradiance.length) {
					shirr[j + i * 27] = p.irradiance[j];
				}
			}
		}
		return shirr;
	}
	
	var vec = new Vec4();
	public function getProbeID(t:Transform):Int {
		vec.x = t.absx();
		vec.y = t.absy();
		vec.z = t.absz();
		var size = t.size;
		for (i in 1...probes.length) {
			var p = probes[i];
			// Transform not in volume
			if (vec.x + size.x / 2 < p.volumeMin.x || vec.x - size.x / 2 > p.volumeMax.x ||
				vec.y + size.y / 2 < p.volumeMin.y || vec.y - size.y / 2 > p.volumeMax.y ||
				vec.z + size.z / 2 < p.volumeMin.z || vec.z - size.z / 2 > p.volumeMax.z) {
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
			var irr:Array<kha.FastFloat> = [1.0281457342829743,1.1617608778901902,1.3886220898440544,-0.13044863139637752,-0.2794659158733846,-0.5736106907295643,0.04065421813873111,0.0434367391348577,0.03567450494792305,0.10964557605577738,0.1129839085793664,0.11261660812141877,-0.08271974283263238,-0.08068091195339556,-0.06432614970480094,-0.12517787967665814,-0.11638582546310804,-0.09743696224655113,0.20068697715947176,0.2158788783296805,0.2109374396869599,0.19636637427150455,0.19445523113118082,0.17825330699680575,0.31440860839538637,0.33041120060402407,0.30867788630062676];
			// var irr = [];
			// for (i in 0...9) {
				// irr.push(1.0); irr.push(1.0); irr.push(1.0);
			// }
			done(haxe.ds.Vector.fromData(irr));
		}
		else {
			iron.data.Data.getBlob(raw.irradiance + '.arm', function(b:kha.Blob) {
				var irradianceData = b;
#if WITH_JSON
				var irradianceParsed:TIrradiance = haxe.Json.parse(irradianceData.toString());
#else
				var irradianceParsed:TIrradiance = iron.system.msgpack.MsgPack.decode(irradianceData.toBytes());
#end
				done(haxe.ds.Vector.fromData(irradianceParsed.irradiance));
			});
		}
	}
}
