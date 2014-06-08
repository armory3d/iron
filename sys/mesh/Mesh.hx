package wings.sys.mesh;

import wings.sys.geometry.Geometry;
import wings.sys.material.Material;
import wings.sys.Factory;

class Mesh {

	public var geometry:Geometry;
	public var material:Material;

	public function new(geometry:String, material:String) {

		this.geometry = Factory.getGeometry(geometry);
		this.material = Factory.getMaterial(material);

		this.geometry.build(this.material);
	}
}
