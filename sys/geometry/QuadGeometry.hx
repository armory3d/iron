package fox.sys.geometry;

class QuadGeometry extends Geometry {

	public function new(w:Float, h:Float) {

		var vertices = [
			-w / 2,  h / 2, 0,
			-w / 2, -h / 2, 0,
			w / 2,  -h / 2, 0,
			w / 2, h / 2, 0
		];

		var uvs = [
			0, 0,
			0, 1,
			1, 1,
			1, 0
		];

		var normals = [
			0, 0, 1,
			0, 0, 1,
			0, 0, 1,
			0, 0, 1
		];

		var indices = [0, 1, 2, 0, 2, 3];

		var data:Array<Float> = new Array();
		for (i in 0...Std.int(vertices.length / 3)) {
			data.push(vertices[i * 3]);
			data.push(vertices[i * 3 + 1]);
			data.push(vertices[i * 3 + 2]);
			data.push(uvs[i * 2]);
			data.push(uvs[i * 2 + 1]);
			data.push(normals[i * 3]);
			data.push(normals[i * 3 + 1]);
			data.push(normals[i * 3 + 2]);
		}

    	super(data, indices);
	}
}
