package wings.w3d.meshes;

class ObjGeometry extends Geometry {

	var indexedVertices;
	var indexedUVs;
	var indexedNormals;
	var indexedIndices;

	var index:Int;

	public function new(data:String)
	{
		var vertices:Array<Float> = new Array();
		var uvs:Array<Float> = new Array();
		var normals:Array<Float> = new Array();

		var vertexIndices:Array<Int> = new Array();
		var uvIndices:Array<Int> = new Array();
		var normalIndices:Array<Int> = new Array();

		var tempVertices:Array<Array<Float>> = new Array();
		var tempUVs:Array<Array<Float>> = new Array();
		var tempNormals:Array<Array<Float>> = new Array();

		var lines:Array<String> = data.split("\n");

		for (i in 0...lines.length)
		{
			var words:Array<String> = lines[i].split(" ");

			if (words[0] == "v")
			{
				var vector:Array<Float> = new Array<Float>();
				vector.push(Std.parseFloat(words[1]));
				vector.push(Std.parseFloat(words[2]));
				vector.push(Std.parseFloat(words[3]));
				tempVertices.push(vector);
			}
			else if (words[0] == "vt")
			{
				var vector:Array<Float> = new Array<Float>();
				vector.push(Std.parseFloat(words[1]));
				vector.push(Std.parseFloat(words[2]));
				tempUVs.push(vector);
			}
			else if (words[0] == "vn")
			{
				var vector:Array<Float> = new Array<Float>();
				vector.push(Std.parseFloat(words[1]));
				vector.push(Std.parseFloat(words[2]));
				vector.push(Std.parseFloat(words[3]));
				tempNormals.push(vector);
			}
			else if (words[0] == "f")
			{
				var sec1:Array<String> = words[1].split("/");
				var sec2:Array<String> = words[2].split("/");
				var sec3:Array<String> = words[3].split("/");

				vertexIndices.push(Std.int(Std.parseFloat(sec1[0])));
				vertexIndices.push(Std.int(Std.parseFloat(sec2[0])));
				vertexIndices.push(Std.int(Std.parseFloat(sec3[0])));

				uvIndices.push(Std.int(Std.parseFloat(sec1[1])));
				uvIndices.push(Std.int(Std.parseFloat(sec2[1])));
				uvIndices.push(Std.int(Std.parseFloat(sec3[1])));
				
				normalIndices.push(Std.int(Std.parseFloat(sec1[2])));
				normalIndices.push(Std.int(Std.parseFloat(sec2[2])));
				normalIndices.push(Std.int(Std.parseFloat(sec3[2])));
			}
		}

		for (i in 0...vertexIndices.length)
		{
			var vertex:Array<Float> = tempVertices[vertexIndices[i] - 1];
			var uv:Array<Float> = tempUVs[uvIndices[i] - 1];
			var normal:Array<Float> = tempNormals[normalIndices[i] - 1];

			vertices.push(vertex[0]);
			vertices.push(vertex[1]);
			vertices.push(vertex[2]);
			uvs.push(uv[0]);
			uvs.push(uv[1]);
			normals.push(normal[0]);
			normals.push(normal[1]);
			normals.push(normal[2]);
		}

		build(vertices, uvs, normals);

		var data:Array<Float> = new Array();
		for (i in 0...Std.int(vertices.length / 3)) {
			data.push(indexedVertices[i * 3]);
			data.push(indexedVertices[i * 3 + 1]);
			data.push(indexedVertices[i * 3 + 2]);
			data.push(indexedUVs[i * 2]);
			data.push(indexedUVs[i * 2 + 1]);
			data.push(indexedNormals[i * 3]);
			data.push(indexedNormals[i * 3 + 1]);
			data.push(indexedNormals[i * 3 + 2]);
		}

		super(data, indexedIndices);
	}

	function build(_vertices:Array<Float>, _uvs:Array<Float>, _normals:Array<Float>) {

		indexedVertices = new Array();
		indexedUVs = new Array();
		indexedNormals = new Array();
		indexedIndices = new Array();

		// For each input vertex
		for (i in 0...Std.int(_vertices.length / 3)) {

			// Try to find a similar vertex in out_XXXX
			var found:Bool = getSimilarVertexIndex(
				_vertices[i * 3], _vertices[i * 3 + 1], _vertices[i * 3 + 2],
				_uvs[i * 2], _uvs[i * 2 + 1],
				_normals[i * 3], _normals[i * 3 + 1], _normals[i * 3 + 2]);

			if (found) { // A similar vertex is already in the VBO, use it instead !
				indexedIndices.push(index);
			}else{ // If not, it needs to be added in the output data.
				indexedVertices.push(_vertices[i * 3]);
				indexedVertices.push(_vertices[i * 3 + 1]);
				indexedVertices.push(_vertices[i * 3 + 2]);
				indexedUVs.push(_uvs[i * 2 ]);
				indexedUVs.push(_uvs[i * 2 + 1]);
				indexedNormals.push(_normals[i * 3]);
				indexedNormals.push(_normals[i * 3 + 1]);
				indexedNormals.push(_normals[i * 3 + 2]);
				indexedIndices.push(Std.int(indexedVertices.length / 3) - 1);
			}
		}
	}


	// Returns true if v1 can be considered equal to v2
	function isNear(v1:Float, v2:Float):Bool {
		return Math.abs(v1 - v2) < 0.01;
	}

	// Searches through all already-exported vertices
	// for a similar one.
	// Similar = same position + same UVs + same normal
	function getSimilarVertexIndex( 
		vertexX:Float, vertexY:Float, vertexZ:Float,
		uvX:Float, uvY:Float,
		normalX:Float, normalY:Float, normalZ:Float
	):Bool {
		// Lame linear search
		for (i in 0...Std.int(indexedVertices.length / 3)) {
			if (
				isNear(vertexX, indexedVertices[i * 3]) &&
				isNear(vertexY, indexedVertices[i * 3 + 1]) &&
				isNear(vertexZ, indexedVertices[i * 3 + 2]) &&
				isNear(uvX    , indexedUVs     [i * 2]) &&
				isNear(uvY    , indexedUVs     [i * 2 + 1]) &&
				isNear(normalX, indexedNormals [i * 3]) &&
				isNear(normalY, indexedNormals [i * 3 + 1]) &&
				isNear(normalZ, indexedNormals [i * 3 + 2])
			){
				index = i;
				return true;
			}
		}
		// No other vertex could be used instead.
		// Looks like we'll have to add it to the VBO.
		return false;
	}
}
