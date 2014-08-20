package wings.sys.material;

import kha.graphics.Program;
import kha.graphics.ConstantLocation;
import kha.graphics.TextureUnit;
import kha.Sys;

class Shader {

	public var program:Program;
	public var structure:VertexStructure;

	public var constantVec3s:Array<ConstantLocation>;
	public var constantVec4s:Array<ConstantLocation>;
	public var constantMat4s:Array<ConstantLocation>;
	public var textures:Array<TextureUnit>;

	public function new(fragmentShader:String, vertexShader:String, structure:VertexStructure) {

		var fragmentShader = Sys.graphics.createFragmentShader(kha.Loader.the.getShader(fragmentShader));
		var vertexShader = Sys.graphics.createVertexShader(kha.Loader.the.getShader(vertexShader));
	
		program = Sys.graphics.createProgram();
		program.setFragmentShader(fragmentShader);
		program.setVertexShader(vertexShader);

		this.structure = structure;

		constantVec3s = new Array();
		constantVec4s = new Array();
		constantMat4s = new Array();
		textures = new Array();

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

	public function addTexture(s:String):TextureUnit {

		var tu:TextureUnit = program.getTextureUnit(s);
		textures.push(tu);

		return tu;
	}
}
