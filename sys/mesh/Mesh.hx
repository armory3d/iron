package wings.sys.mesh;

import wings.sys.geometry.Geometry;
import wings.sys.material.Material;
import wings.sys.Assets;

class Mesh {

	public var geometry:Geometry;
	public var material:Material;

	public function new(geometry:Geometry, material:Material) {

		this.geometry = geometry;
		this.material = material;

		this.geometry.build(this.material);
	}
}
