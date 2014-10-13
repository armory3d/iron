package fox.w3d.scene;

import fox.w3d.material.Material;
import fox.w3d.mesh.Mesh;
import fox.w3d.mesh.PlaneGeometry;
import fox.w3d.mesh.QuadGeometry;
import fox.w3d.mesh.Geometry;
import fox.wxd.Perlin;

class Terrain extends Model {

	var terrainW:Int;
	var terrainH:Int;
	var segmentsX:Int;
	var segmentsY:Int;
	var heightData:Array<Int>;

	public function new(w:Int, h:Int, material:Material) {
		terrainW = w;
		terrainH = h;

		segmentsX = 70;
		segmentsY = 70;

		var perlin = new Perlin();
		heightData = perlin.fill(segmentsX, segmentsY, 0, 0, 0);

		super(new Mesh(new PlaneGeometry(w, h, segmentsX, segmentsY, 1, 1, heightData, PlaneGeometry.AXIS_Y),
					   material));
	}

	public function generateGrass(density:Int, mat:Material) {
		//var grass:Grass = new Grass();

		var stepX:Float = terrainW / (terrainW * density);
		var stepZ:Float = terrainH / (terrainH * density);

		var data:Array<Float> = new Array();
		var indices:Array<Int> = new Array();

		// Generate grass blades geometry
		for (j in 0...terrainH * density) {
			for (i in 0...terrainW * density) {

				var rX:Float = (Std.random(1000) / 500 - 1) / 4;
				var rZ:Float = (Std.random(1000) / 500 - 1) / 4;
				var xx:Float = (i * stepX - terrainW / 2 + rX);// * 2;
				var zz:Float = (j * stepZ - terrainH / 2 + rZ);// * 2;

				generateBlade(data, indices,
					xx,
					getHeight(i * stepX + rX, j * stepZ + rZ) / 3 + 1.9,// - 1.9,
					zz);
			}
		}

		// Create grass model
		var model:Model = new Model(new Mesh(new Geometry(data, indices), mat));
		model.setMat4(model.mvpMatrix);
		addChild(model);
	}

	public function generateGrassBillboards(density:Float, mat:Material) {
		var stepX:Float = terrainW / (terrainW * density);
		var stepZ:Float = terrainH / (terrainH * density);

		// Generate grass blades geometry
		for (j in 0...Std.int(terrainH * density)) {
			for (i in 0...Std.int(terrainW * density)) {

				var rX:Float = (Std.random(1000) / 500 - 1) / 4;
				var rZ:Float = (Std.random(1000) / 500 - 1) / 4;
				var xx:Float = (i * stepX - terrainW / 2 + rX);// * 2;
				var zz:Float = (j * stepZ - terrainH / 2 + rZ);// * 2;

				var bill:Billboard = new Billboard(new Mesh(new QuadGeometry(2, 2), mat));
				bill.setPosition(xx / 2, getHeight(i * stepX + rX, j * stepZ + rZ) / 5.6 + 1, zz / 2);
				bill.setMat4(bill.mvpMatrix);
				bill.setVec3(bill.position);
				bill.setVec3(bill.size);
				bill.setVec3(bill.camRightWorld);
				bill.setVec3(bill.camUpWorld);
				addChild(bill);
			}
		}
	}

	function generateBlade(data:Array<Float>, indices:Array<Int>, x:Float, y:Float, z:Float) {

		var size:Float = 1;

		var vertices = [
		   -size + x,  size + y, 0 + z,
		   -size + x, -size + y, 0 + z,
			size + x, -size + y, 0 + z,
			size + x,  size + y, 0 + z,

		   -size * 0.8 + x,  size + y,  size * 0.8 + z,
		   -size * 0.8 + x, -size + y,  size * 0.8 + z,
			size * 0.8 + x, -size + y, -size * 0.8 + z,
			size * 0.8 + x,  size + y, -size * 0.8 + z,

			size * 0.8 + x,  size + y,  size * 0.8 + z,
			size * 0.8 + x, -size + y,  size * 0.8 + z,
		   -size * 0.8 + x, -size + y, -size * 0.8 + z,
		   -size * 0.8 + x,  size + y, -size * 0.8 + z
		];

		var uvs = [
			0, 0,
			0, 1,
			1, 1,
			1, 0,

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
			0, 1, 0,
			0, 1, 0,
			0, 1, 0,
			0, 1, 0,

			0, 1, 0,
			0, 1, 0,
			0, 1, 0,
			0, 1, 0,

			0, 1, 0,
			0, 1, 0,
			0, 1, 0,
			0, 1, 0
		];
		
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

		var offset:Int = Std.int(Std.int(data.length / 8) / 4) * 4 - 4;
		offset -= 8;
		indices.push(0 + offset);
		indices.push(1 + offset);
		indices.push(2 + offset);
		indices.push(0 + offset);
		indices.push(2 + offset);
		indices.push(3 + offset);

		offset += 4;
		indices.push(0 + offset);
		indices.push(1 + offset);
		indices.push(2 + offset);
		indices.push(0 + offset);
		indices.push(2 + offset);
		indices.push(3 + offset);

		offset += 4;
		indices.push(0 + offset);
		indices.push(1 + offset);
		indices.push(2 + offset);
		indices.push(0 + offset);
		indices.push(2 + offset);
		indices.push(3 + offset);
	}

	function generateWater(height:Float) {

	}


	function getHeight(xPos:Float, zPos:Float, scaleFactor:Float = 1):Float {
	    // we first get the height of four points of the quad underneath the point
	    // Check to make sure this point is not off the map at all
	    var x:Int = Std.int(xPos / scaleFactor);      
	    var z:Int = Std.int(zPos / scaleFactor);      

	    var xPlusOne:Int = x + 1;
	    var zPlusOne:Int = z + 1;

	    var triZ0:Float = heightData[x + z * terrainW];
	    var triZ1:Float = heightData[xPlusOne + z * terrainW];
	    var triZ2:Float = heightData[x + zPlusOne * terrainW];
	    var triZ3:Float = heightData[xPlusOne + zPlusOne * terrainW];

	    var height:Float = 0;
	    var sqX:Float = (xPos / scaleFactor) - x;
	    var sqZ:Float = (zPos / scaleFactor) - z;
	    
	    if ((sqX + sqZ) < 1) {
	        height = triZ0;
	        height += (triZ1 - triZ0) * sqX;
	        height += (triZ2 - triZ0) * sqZ;
	    }
	    else {
	        height = triZ3;
	        height += (triZ1 - triZ3) * (1.0 - sqZ);
	        height += (triZ2 - triZ3) * (1.0 - sqX);
	    }

	    return height;
	}



	function calculateNormals() {
		/*var i:Int, j, index1, index2, index3, index, count;
		var float vertex1[3], vertex2[3], vertex3[3], vector1[3], vector2[3], sum[3], length;
		VectorType* normals;


		// Create a temporary array to hold the un-normalized normal vectors.
		normals = new VectorType[(segmentsY-1) * (segmentsX-1)];
		if (!normals) return false;

		// Go through all the faces in the mesh and calculate their normals.
		for (j in 0...segmentsY - 1)
		{
			for (i in 0...segmentsX - 1)
			{
				index1 = (j * segmentsY) + i;
				index2 = (j * segmentsY) + (i+1);
				index3 = ((j+1) * segmentsY) + i;

				// Get three vertices from the face.
				vertex1[0] = m_heightMap[index1].x;
				vertex1[1] = m_heightMap[index1].y;
				vertex1[2] = m_heightMap[index1].z;
			
				vertex2[0] = m_heightMap[index2].x;
				vertex2[1] = m_heightMap[index2].y;
				vertex2[2] = m_heightMap[index2].z;
			
				vertex3[0] = m_heightMap[index3].x;
				vertex3[1] = m_heightMap[index3].y;
				vertex3[2] = m_heightMap[index3].z;

				// Calculate the two vectors for this face.
				vector1[0] = vertex1[0] - vertex3[0];
				vector1[1] = vertex1[1] - vertex3[1];
				vector1[2] = vertex1[2] - vertex3[2];
				vector2[0] = vertex3[0] - vertex2[0];
				vector2[1] = vertex3[1] - vertex2[1];
				vector2[2] = vertex3[2] - vertex2[2];

				index = (j * (segmentsY-1)) + i;

				// Calculate the cross product of those two vectors to get the un-normalized value for this face normal.
				normals[index].x = (vector1[1] * vector2[2]) - (vector1[2] * vector2[1]);
				normals[index].y = (vector1[2] * vector2[0]) - (vector1[0] * vector2[2]);
				normals[index].z = (vector1[0] * vector2[1]) - (vector1[1] * vector2[0]);
			}
		}

		// Now go through all the vertices and take an average of each face normal 	
		// that the vertex touches to get the averaged normal for that vertex.
		for (j in 0...segmentsY) {
			for (i in 0...segmentsX) {
				// Initialize the sum.
				sum[0] = 0.0f;
				sum[1] = 0.0f;
				sum[2] = 0.0f;

				// Initialize the count.
				count = 0;

				// Bottom left face.
				if (((i-1) >= 0) && ((j-1) >= 0)) {
					index = ((j-1) * (segmentsY-1)) + (i-1);

					sum[0] += normals[index].x;
					sum[1] += normals[index].y;
					sum[2] += normals[index].z;
					count++;
				}

				// Bottom right face.
				if ((i < (m_terrainWidth-1)) && ((j-1) >= 0)) {
					index = ((j-1) * (segmentsY-1)) + i;

					sum[0] += normals[index].x;
					sum[1] += normals[index].y;
					sum[2] += normals[index].z;
					count++;
				}

				// Upper left face.
				if (((i-1) >= 0) && (j < (segmentsY-1))) {
					index = (j * (segmentsY-1)) + (i-1);

					sum[0] += normals[index].x;
					sum[1] += normals[index].y;
					sum[2] += normals[index].z;
					count++;
				}

				// Upper right face.
				if((i < (segmentsX-1)) && (j < (segmentsY-1))) {
					index = (j * (segmentsY-1)) + i;

					sum[0] += normals[index].x;
					sum[1] += normals[index].y;
					sum[2] += normals[index].z;
					count++;
				}
				
				// Take the average of the faces touching this vertex.
				sum[0] = (sum[0] / (float)count);
				sum[1] = (sum[1] / (float)count);
				sum[2] = (sum[2] / (float)count);

				// Calculate the length of this normal.
				length = sqrt((sum[0] * sum[0]) + (sum[1] * sum[1]) + (sum[2] * sum[2]));
				
				// Get an index to the vertex location in the height map array.
				index = (j * segmentsY) + i;

				// Normalize the final shared normal for this vertex and store it in the height map array.
				m_heightMap[index].nx = (sum[0] / length);
				m_heightMap[index].ny = (sum[1] / length);
				m_heightMap[index].nz = (sum[2] / length);
			}
		}*/
	}
}
