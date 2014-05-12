package wings.w3d.mesh;

import wings.w3d.material.Material;

class Mesh {

	public var name:String;

	public var geometry:Geometry;
	public var material:Material;

	public function new(geometry:Geometry, material:Material) {

		this.geometry = geometry;
		this.material = material;
		geometry.build(material);
	}
}
