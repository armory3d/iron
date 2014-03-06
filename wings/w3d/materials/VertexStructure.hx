package wings.w3d.materials;

import kha.graphics.VertexData;

class VertexStructure {

	public var structure:kha.graphics.VertexStructure;
	public var structureLength:Int;

	public function new() {

		structure = new kha.graphics.VertexStructure();
		structureLength = 0;
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
