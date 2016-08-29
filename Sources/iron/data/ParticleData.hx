package iron.data;

import iron.data.SceneFormat;

class ParticleData extends Data {

	public var name:String;
	public var raw:TParticleData;

	public function new(raw:TParticleData) {
		super();

		this.raw = raw;
		this.name = raw.name;
	}

	public static function parse(name:String, id:String):ParticleData {
		var format:TSceneFormat = Data.getSceneRaw(name);
		var raw:TParticleData = Data.getParticleRawByName(format.particle_datas, id);
		if (raw == null) {
			trace('Particle data "$id" not found!');
			return null;
		}
		return new ParticleData(raw);
	}
}
