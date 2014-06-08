package wings.sys;

import wings.sys.geometry.Geometry;
import wings.sys.material.Material;
import wings.sys.mesh.Mesh;

class Factory {

	static var geometries = new Map<String, Geometry>();
	static var materials = new Map<String, Material>();
	static var meshes = new Map<String, Mesh>();

	public function new() {
		
	}
	
	public static function addGeometry(name:String, geometry:Geometry) {
		geometries.set(name, geometry);
	}

	public static function getGeometry(name:String):Geometry {
		return geometries.get(name);
	}

	public static function addMaterial(name:String, material:Material) {
		materials.set(name, material);
	}

	public static function getMaterial(name:String):Material {
		return materials.get(name);
	}

	public static function addMesh(name:String, mesh:Mesh) {
		meshes.set(name, mesh);
	}

	public static function getMesh(name:String):Mesh {
		return meshes.get(name);
	}
}
