package lue.resource;

import kha.Image;
import lue.math.Vec4;
import lue.node.Transform;
import lue.resource.SceneFormat;

class WorldResource extends Resource {

	public var resource:TWorldResource;
	
	var probes:Array<Probe>; 
	public var brdf:Image;
	
	public function new(resource:TWorldResource) {
		super();

		if (resource == null) {
			trace("Resource not found!");
			return;
		}

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
		var irradianceData = Reflect.field(kha.Assets.blobs, resource.irradiance + "_json").toString();
		var irradianceParsed:TIrradiance = haxe.Json.parse(irradianceData);
		irradiance = haxe.ds.Vector.fromData(irradianceParsed.irradiance);
		
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
