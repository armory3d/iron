package wings.w3d.meshes;

import wings.w3d.materials.Material;

class Mesh {

	public var name:String;

	public var geometry:Geometry;
	public var material:Material;

	public function new(geometry:Geometry, material:Material) {

		this.geometry = geometry;
		this.material = material;
	}
}
