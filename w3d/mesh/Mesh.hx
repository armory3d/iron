package wings.w3d.mesh;

import wings.w3d.material.Material;

class Mesh {

	public var name:String;

	public var geometries:Array<Geometry> = [];
	public var materials:Array<Material> = [];

	public function new(geometries:Array<Geometry>, materials:Array<Material>) {

		this.geometries = geometries;
		this.materials = materials;

		for (i in 0...geometries.length) {
			geometries[i].build(materials[i]);
		}
	}
}
