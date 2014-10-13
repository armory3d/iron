package fox.sys.mesh;

import fox.sys.geometry.Geometry;
import fox.sys.material.Material;
import fox.sys.Assets;

class Mesh {

	public var geometry:Geometry;
	public var material:Material;

	public function new(geometry:Geometry, material:Material) {

		this.geometry = geometry;
		this.material = material;

		this.geometry.build(this.material);
	}
}
