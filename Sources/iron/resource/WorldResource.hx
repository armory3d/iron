package iron.resource;

import kha.Image;
import iron.math.Vec4;
import iron.node.Transform;
import iron.resource.SceneFormat;

class WorldResource extends Resource {

	public var resource:TWorldResource;
	
	var probes:Array<Probe>; 
	public var brdf:Image;
	
	public function new(resource:TWorldResource) {
		super();

		this.resource = resource;
		brdf = Reflect.field(kha.Assets.images, resource.brdf);
		
		// Parse probes
		if (resource.probes != null && resource.probes.length > 0) {
			probes = [];
			for (p in resource.probes) {
				probes.push(new Probe(p));
			}
		}
	}

	public static function parse(name:String, id:String):WorldResource {
		var format:TSceneFormat = Resource.getSceneResource(name);
		var resource:TWorldResource = Resource.getWorldResourceById(format.world_resources, id);
		if (resource == null) {
			trace('World resource "$id" not found!');
			return null;
		}
		return new WorldResource(resource);
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
			shirr = new haxe.ds.Vector(27 * 20);
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
}

class Probe {
	
	public var resource:TProbe;
	
	public var radiance:Image;
	public var numMipmaps:Int;
	public var irradiance:haxe.ds.Vector<kha.FastFloat>;
	public var strength:Float;
	public var blending:Float;
	public var volume:Vec4;
	public var volumeCenter:Vec4;
	
	public var volumeMin:Vec4;
	public var volumeMax:Vec4;
	
	public function new(resource:TProbe) {
		this.resource = resource;
		
		// Parse probe data
		if (resource.irradiance == "") {
			// Use default if no data provided
			var irr:Array<kha.FastFloat> = [1.0281457342829743,1.1617608778901902,1.3886220898440544,-0.13044863139637752,-0.2794659158733846,-0.5736106907295643,0.04065421813873111,0.0434367391348577,0.03567450494792305,0.10964557605577738,0.1129839085793664,0.11261660812141877,-0.08271974283263238,-0.08068091195339556,-0.06432614970480094,-0.12517787967665814,-0.11638582546310804,-0.09743696224655113,0.20068697715947176,0.2158788783296805,0.2109374396869599,0.19636637427150455,0.19445523113118082,0.17825330699680575,0.31440860839538637,0.33041120060402407,0.30867788630062676];
			// var irr = [];
			// for (i in 0...9) {
				// irr.push(1.0); irr.push(1.0); irr.push(1.0);
			// }
			irradiance = haxe.ds.Vector.fromData(irr);
		}
		else {
			var irradianceData:kha.Blob = Reflect.field(kha.Assets.blobs, resource.irradiance + "_arm");
#if WITH_JSON
			var irradianceParsed:TIrradiance = haxe.Json.parse(irradianceData.toString());
#else
			var irradianceParsed:TIrradiance = iron.resource.msgpack.MsgPack.decode(irradianceData.toBytes());
#end
			irradiance = haxe.ds.Vector.fromData(irradianceParsed.irradiance);
		}
		
		if (resource.radiance != null) {
			numMipmaps = resource.radiance_mipmaps;
			
			radiance = Reflect.field(kha.Assets.images, resource.radiance);
			var radianceMipmaps:Array<kha.Image> = [];
			for (i in 0...numMipmaps) {
				radianceMipmaps.push(Reflect.field(kha.Assets.images,resource.radiance + '_' + i));
			}
			radiance.setMipmaps(radianceMipmaps);
		}
		
		strength = resource.strength;
		blending = resource.blending;
		
		volume = new Vec4(resource.volume[0] / 4, resource.volume[1] / 4, resource.volume[2] / 4);
		volumeCenter = new Vec4(resource.volume_center[0], resource.volume_center[1], resource.volume_center[2]);
	
		volumeMin = new Vec4(volumeCenter.x - volume.x, volumeCenter.y - volume.y, volumeCenter.z - volume.z);
		volumeMax = new Vec4(volumeCenter.x + volume.x, volumeCenter.y + volume.y, volumeCenter.z + volume.z);
	}
}
