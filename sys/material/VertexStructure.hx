package fox.sys.material;

import kha.graphics4.VertexData;

class VertexStructure {

	public var structure:kha.graphics4.VertexStructure;
	public var structureLength:Int = 0;

	public function new() {

		structure = new kha.graphics4.VertexStructure();
	}

	public function addFloat2(s:String) {
		structure.add(s, VertexData.Float2);
		structureLength += 2;
	}

	public function addFloat3(s:String) {
		structure.add(s, VertexData.Float3);
		structureLength += 3;
	}

	public function addFloat4(s:String) {
		structure.add(s, VertexData.Float4);
		structureLength += 4;
	}
}
