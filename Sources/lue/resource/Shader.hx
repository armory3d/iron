package lue.resource;

import kha.graphics4.Program;
import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureUnit;
import kha.graphics4.FragmentShader;
import kha.graphics4.VertexShader;
import kha.graphics4.VertexStructure;
import kha.graphics4.VertexData;
import kha.Loader;

class Shader {

	public static var defaultStructure:VertexStructure;
	public static var defaultStructureLength:Int;
	static var shaders = new Map<String, Shader>();

	public var program:Program;
	public var constants:Array<ConstantLocation> = [];
	public var textures:Array<TextureUnit> = [];

	public function new(fragmentShader:String, vertexShader:String) {

		var fragmentShader = new FragmentShader(Loader.the.getShader(fragmentShader));
		var vertexShader = new VertexShader(Loader.the.getShader(vertexShader));
	
		program = new Program();
		program.setFragmentShader(fragmentShader);
		program.setVertexShader(vertexShader);

		link();
	}

	public function link() {
		program.link(defaultStructure);
	}

	public function addConstant(s:String) {
		constants.push(program.getConstantLocation(s));
	}

	public function addTexture(s:String):TextureUnit {
		var tu:TextureUnit = program.getTextureUnit(s);
		textures.push(tu);
		return tu;
	}

	public static function createDefaults() {
		defaultStructure = new VertexStructure();
		defaultStructure.add("pos", VertexData.Float3);
		defaultStructure.add("tex", VertexData.Float2);
		defaultStructure.add("nor", VertexData.Float3);
		defaultStructure.add("col", VertexData.Float4);
		defaultStructureLength = 12;

		// Mesh
		var shader = new Shader("mesh.frag", "mesh.vert");
		shader.addConstant("M");
		shader.addConstant("V");
		shader.addConstant("P");
		shader.addConstant("dbMVP");
		shader.addConstant("light");
		shader.addConstant("eye");
		shader.addConstant("diffuseColor");
		shader.addConstant("texturing");
		shader.addConstant("lighting");
		shader.addConstant("receiveShadow");
		shader.addConstant("roughness");
		shader.addTexture("stex");
		shader.addTexture("shadowMap");
		shaders.set("mesh", shader);
	}

	public static function get(name:String) {
		return shaders.get(name);
	}
}
