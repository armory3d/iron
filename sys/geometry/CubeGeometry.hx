package wings.sys.geometry;

class CubeGeometry extends Geometry {
	
	public function new(width:Float, height:Float, depth:Float) {

		var w = width / 2;
		var h = height / 2;
		var d = depth / 2;

		// TODO: Use indices :)

		var vertices = [
			// Front face
			-w,-h, d,
			-w, h, d,
			 w,-h, d,
			 w, h, d,
			-w, h, d,
			 w,-h, d,

			// Back face
			-w,-h,-d,
			-w, h,-d,
			 w,-h,-d,
			 w, h,-d,
			-w, h,-d,
			 w,-h,-d,

			// Left face
			-w,-h, d,
			-w, h, d,
			-w,-h,-d,
			-w,-h,-d,
			-w, h,-d,
			-w, h, d,

			// Right face
			 w,-h, d,
			 w, h, d,
			 w,-h,-d,
			 w,-h,-d,
			 w, h,-d,
			 w, h, d,

			// Top face
			-w, h, d,
			 w, h, d,
			-w, h,-d,
			 w, h, d,
			 w, h,-d,
			-w, h,-d,

			// Bottom face
			-w,-h, d,
			 w,-h, d,
			-w,-h,-d,
			 w,-h, d,
			 w,-h,-d,
			-w,-h,-d,
		];

		var uvs = [
			// Front
			0, 1,
			0, 0,
			1, 1,
			1, 0,
			0, 0,
			1, 1,

			// Back
			0, 1,
			0, 0,
			1, 1,
			1, 0,
			0, 0,
			1, 1,

			// Left
			1, 1,
			1, 0,
			0, 1,
			0, 1,
			0, 0,
			1, 0,

			// Right
			1, 1,
			1, 0,
			0, 1,
			0, 1,
			0, 0,
			1, 0,

			// Top
			0, 1,
			1, 1,
			0, 0,
			1, 1,
			1, 0,
			0, 0,

			// Bottom
			0, 1,
			1, 1,
			0, 0,
			1, 1,
			1, 0,
			0, 0
		];

		var normals = [
			0, 0, 1,
			0, 0, 1,
			0, 0, 1,
			0, 0, 1,
			0, 0, 1,
			0, 0, 1,

			0, 0, -1,
			0, 0, -1,
			0, 0, -1,
			0, 0, -1,
			0, 0, -1,
			0, 0, -1,

			-1, 0, 0,
			-1, 0, 0,
			-1, 0, 0,
			-1, 0, 0,
			-1, 0, 0,
			-1, 0, 0,

			1, 0, 0,
			1, 0, 0,
			1, 0, 0,
			1, 0, 0,
			1, 0, 0,
			1, 0, 0,

			0, 1, 0,
			0, 1, 0,
			0, 1, 0,
			0, 1, 0,
			0, 1, 0,
			0, 1, 0,

			0, -1, 0,
			0, -1, 0,
			0, -1, 0,
			0, -1, 0,
			0, -1, 0,
			0, -1, 0
		];

		var indices = [for (i in 0...Std.int(vertices.length / 3)) i];

		/*
		var vertices = [
			-w,  h, d,
			-w, -h, d,
			 w, -h, d,
			 w,  h, d,

			-w,  h, -d,
			-w, -h, -d,
			 w, -h, -d,
			 w,  h, -d
		];

		var uvs = [
			0, 0,
			0, 1,
			1, 1,
			1, 0,

			0, 0,
			0, 1,
			1, 1,
			1, 0
		];

		var normals = [
			0, 0, 1,
			0, 0, 1,
			0, 0, 1,
			0, 0, 1,

			0, 0, -1,
			0, 0, -1,
			0, 0, -1,
			0, 0, -1
		];

		var indices = [0, 1, 2, 0, 2, 3,
					   3, 2, 6, 3, 6, 7,
					   7, 6, 5, 7, 5, 4,
					   0, 1, 5, 0, 5, 4,
					   0, 3, 7, 0, 7, 4,
					   1, 2, 6, 1, 6, 5];*/


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
