package wings.sys;

import kha.Loader;
import kha.Image;
import kha.graphics.Texture;
import kha.Sound;
import kha.Music;
import kha.Font;
import kha.FontStyle;
import kha.Blob;

import wings.sys.geometry.Geometry;
import wings.sys.material.Material;
import wings.sys.material.Shader;
import wings.sys.mesh.Mesh;
import wings.sys.importer.TextureAtlas;

class Assets {

	static var geometries = new Map<String, Geometry>();
	static var materials = new Map<String, Material>();
	static var meshes = new Map<String, Mesh>();
	static var shaders = new Map<String, Shader>();
	static var atlases = new Map<String, TextureAtlas>();

	public function new() {
		
	}
	
	public static inline function addGeometry(name:String, geometry:Geometry) {
		geometries.set(name, geometry);
	}

	public static inline function getGeometry(name:String):Geometry {
		return geometries.get(name);
	}

	public static inline function addMaterial(name:String, material:Material) {
		materials.set(name, material);
	}

	public static inline function getMaterial(name:String):Material {
		return materials.get(name);
	}

	public static inline function addMesh(name:String, mesh:Mesh) {
		meshes.set(name, mesh);
	}

	public static inline function getMesh(name:String):Mesh {
		return meshes.get(name);
	}

	public static inline function addShader(name:String, shader:Shader) {
		shaders.set(name, shader);
	}

	public static inline function getShader(name:String):Shader {
		return shaders.get(name);
	}


	public static inline function addAtlas(name:String, atlas:TextureAtlas) {
		atlases.set(name, atlas);
	}

	public static inline function getAtlas(name:String):TextureAtlas {
		return atlases.get(name);
	}

	public static inline function getImage(name:String):Image {
		return Loader.the.getImage(name);
	}

	public static inline function getTexture(name:String):Texture {
		return cast(Loader.the.getImage(name), Texture);
	}

	public static inline function getSound(name:String):Sound {
		return Loader.the.getSound(name);
	}

	public static inline function getMusic(name:String):Music {
		return Loader.the.getMusic(name);
	}

	public static inline function getFont(name:String, size:Int):Font {
		return Loader.the.loadFont(name, new FontStyle(false, false, false), size);
	}

	public static inline function getBlob(name:String):Blob {
		return Loader.the.getBlob(name);
	}

	public static inline function getString(name:String):String {
		return Loader.the.getBlob(name).toString();
	}
}
