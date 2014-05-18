package wings.w3d.mesh;

import wings.w3d.material.Material;

class Md5Mesh extends Mesh {

	public var childMaterials:Array<Material>;

	public function new(geometry:Md5Geometry, materials:Array<Material>) {

		super(geometry, materials[0]);

		this.childMaterials = materials.splice(1, materials.length - 1);

		for (i in 0...geometry.childGeometries.length) {
			geometry.childGeometries[i].build(childMaterials[i]);
		}
	}
}
