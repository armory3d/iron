package fox.sys.mesh;

import fox.sys.geometry.Geometry;
import fox.sys.material.Material;

class SkinnedMesh extends Mesh {

	public var binds:Array<kha.math.Matrix4>;
	public var weight:Array<kha.math.Vector4>;
	public var bone:Array<kha.math.Vector4>;

	public function new(geometry:Geometry, material:Material) {

		super(geometry, material);
	}
}
