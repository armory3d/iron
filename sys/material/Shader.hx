package fox.sys.material;

import kha.graphics4.Program;
import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureUnit;
import kha.graphics4.FragmentShader;
import kha.graphics4.VertexShader;

class Shader {

	public var program:Program;
	public var structure:VertexStructure;

	public var constantVec3s:Array<ConstantLocation> = [];
	public var constantVec4s:Array<ConstantLocation> = [];
	public var constantMat4s:Array<ConstantLocation> = [];
	public var constantBools:Array<ConstantLocation> = [];
	public var constantFloats:Array<ConstantLocation> = [];
	public var textures:Array<TextureUnit> = [];

	public function new(fragmentShader:String, vertexShader:String, structure:VertexStructure) {

		var fragmentShader = new FragmentShader(kha.Loader.the.getShader(fragmentShader));
		var vertexShader = new VertexShader(kha.Loader.the.getShader(vertexShader));
	
		program = new Program();
		program.setFragmentShader(fragmentShader);
		program.setVertexShader(vertexShader);

		this.structure = structure;

		link();
	}

	public function link() {
		program.link(structure.structure);
	}

	public function addConstantVec3(s:String) {
		constantVec3s.push(program.getConstantLocation(s));
	}

	public function addConstantVec4(s:String) {
		constantVec4s.push(program.getConstantLocation(s));
	}

	public function addConstantMat4(s:String) {
		constantMat4s.push(program.getConstantLocation(s));
	}

	public function addConstantBool(s:String) {
		constantBools.push(program.getConstantLocation(s));
	}

	public function addConstantFloats(s:String) {
		constantFloats.push(program.getConstantLocation(s));
	}

	public function addTexture(s:String):TextureUnit {

		var tu:TextureUnit = program.getTextureUnit(s);
		textures.push(tu);

		return tu;
	}
}
