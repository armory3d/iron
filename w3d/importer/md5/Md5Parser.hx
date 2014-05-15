package wings.w3d.importer.md5;

import haxe.io.StringInput;
import wings.math.Vec3;
import wings.math.Vec2;
import wings.math.Quat;
import wings.math.Mat4;
using StringTools;

class Vertex {

	public var pos:Vec3;
	public var normal:Vec3;
	public var tex0:Vec2;
	public var startWeight:Int;
	public var weightCount:Int;

	public function new() {
		pos = new Vec3();
		normal = new Vec3();
		tex0 = new Vec2();
	}
}

class Triangle {
	public var indices = [0, 0, 0];

	public function new() { }
}

class Weight {
	public var jointID:Int;
	public var bias:Float;
	public var pos:Vec3;

	public function new() {
		pos = new Vec3();
	}
}

class Joint {
	public var name:String;
	public var parentID:Int;
	public var pos:Vec3;
	public var orient:Quat;

	public function new() {
		pos = new Vec3();
		orient = new Quat();
	}
}

class Mesh {
	public var shader:String;
	public var verts:Array<Vertex> = [];
	public var tris:Array<Triangle> = [];
	public var weights:Array<Weight> = [];

	public var texID:Int;

	public var positionBuffer:Array<Vec3> = [];
	public var normalBuffer:Array<Vec3> = [];
	public var tex2DBuffer:Array<Vec2> = [];
	public var indexBuffer:Array<Int> = [];

	public function new() { }
}

class Md5Model {
	var md5Version:Int = -1;
	var numJoints:Int = 0;
	var numMeshes:Int = 0;
	var hasAnimation:Bool = false;

	public var joints:Array<Joint>;
	public var meshes:Array<Mesh>;

	//Md5Animation animation;

	var modelMatrix:Mat4;

	var file:StringInput;
	var str:Array<String>;

	public function new() {
		modelMatrix = new Mat4();
	}

	function readLine():Array<String> {
		var line = file.readLine();
		line = line.replace("\t", " ");
		var str = line.split(" ");
		if (str[0] == "") str.splice(0, 1);
		return str;
	}

	public function loadModel(data:String) {
		joints = [];
		meshes = [];

		file = new StringInput(data);

		try {
			while (true) {
				str = readLine();

				if (str[0] == "MD5Version") {
					md5Version = Std.parseInt(str[1]);
					if (md5Version != 10) throw "Unsupported Md5 version";
				}
				else if (str[0] == "commandline") {
					continue;
				}
				else if (str[0] == "numJoints") {
					numJoints = Std.parseInt(str[1]);
				}
				else if (str[0] == "numMeshes") {
					numMeshes = Std.parseInt(str[1]);
				}
				else if (str[0] == "joints") {
					for (i in 0...numJoints) {
						str = readLine();

						var joint = new Joint();
						joint.name = str[0];
						joint.parentID = Std.parseInt(str[1]);
						joint.pos.x = Std.parseFloat(str[3]);
						joint.pos.y = Std.parseFloat(str[4]);
						joint.pos.z = Std.parseFloat(str[5]);
						joint.orient.x = Std.parseFloat(str[8]);
						joint.orient.y = Std.parseFloat(str[9]);
						joint.orient.z = Std.parseFloat(str[10]);
						joint.name = joint.name.substring(1, joint.name.length - 1);
						computeQuatW(joint.orient);
						joints.push(joint);
					}
				}
				else if (str[0] == "mesh") {
					var mesh = new Mesh();
					var numVerts:Int;
					var numTris:Int;
					var numWeights:Int;

					while (true) {
						str = readLine();

						if (str[0] == "}") {
							break;
						}
						else if (str[0] == "shader") {
							mesh.shader = str[1];
							mesh.shader = mesh.shader.substring(1, mesh.shader.length - 1);
							//mesh.texID = shaderTex;
						}
						else if (str[0] == "numverts") {
							numVerts = Std.parseInt(str[1]);

							for (i in 0...numVerts) {
								str = readLine();

								var vert = new Vertex();

								vert.tex0.x = Std.parseFloat(str[3]);
								vert.tex0.y = Std.parseFloat(str[4]);
								vert.startWeight = Std.parseInt(str[6]);
								vert.weightCount = Std.parseInt(str[7]);

								mesh.verts.push(vert);
								mesh.tex2DBuffer.push(vert.tex0);
							}
						}
						else if (str[0] == "numtris") {
							numTris = Std.parseInt(str[1]);

							for (i in 0...numTris) {
								str = readLine();

								var tri = new Triangle();
								tri.indices[0] = Std.parseInt(str[2]);
								tri.indices[1] = Std.parseInt(str[3]);
								tri.indices[2] = Std.parseInt(str[4]);

								mesh.tris.push(tri);
								mesh.indexBuffer.push(tri.indices[0]);
								mesh.indexBuffer.push(tri.indices[1]);
								mesh.indexBuffer.push(tri.indices[2]);
							}
						}
						else if (str[0] == "numweights") {
							numWeights = Std.parseInt(str[1]);

							for (i in 0...numWeights) {
								str = readLine();

								var weight = new Weight();

								weight.jointID = Std.parseInt(str[2]);
								weight.bias = Std.parseFloat(str[3]);
								weight.pos.x = Std.parseFloat(str[5]);
								weight.pos.y = Std.parseFloat(str[6]);
								weight.pos.z = Std.parseFloat(str[7]);

								mesh.weights.push(weight);
							}
						}
					}

					prepareMesh(mesh);
					prepareNormals(mesh);

					meshes.push(mesh);
				}
			}
		}
		catch(ex:haxe.io.Eof) { }

		file.close();
	}

	public function loadAnim() {

	}

	public function update() {

	}

	public function render() {

	}


	function prepareMesh(mesh:Mesh) {
		mesh.positionBuffer = [];
		mesh.tex2DBuffer = [];

		for (i in 0...mesh.verts.length) {
			var finalPos = new Vec3();
			var vert = mesh.verts[i];

			vert.pos = new Vec3();
			vert.normal = new Vec3();

			for (j in 0...vert.weightCount) {
				var weight = mesh.weights[vert.startWeight + j];
				var joint = joints[weight.jointID];

				var rotPos = new Vec3();
				//rotPos = joint.orient * weight.pos;

				//vert.pos += (joint.pos + rotPos) * weight.bias;
			}

			mesh.positionBuffer.push(vert.pos);
			mesh.tex2DBuffer.push(vert.tex0);
		}
	}

	function prepareNormals(mesh:Mesh) {
		mesh.normalBuffer = [];

		for (i in 0...mesh.tris.length) {
			var v0 = mesh.verts[mesh.tris[i].indices[0]].pos;
			var v1 = mesh.verts[mesh.tris[i].indices[1]].pos;
			var v2 = mesh.verts[mesh.tris[i].indices[2]].pos;

			//var normal = cross(v2 - v0, v1 - v0);

			//mesh.verts[mesh.tris[i].indices[0]].normal += normal;
			//mesh.verts[mesh.tris[i].indices[1]].normal += normal;
			//mesh.verts[mesh.tris[i].indices[2]].normal += normal;
		}

		// Normalize all normals
		for (i in 0...mesh.verts.length) {
			var vert = mesh.verts[i];

			//var normal = normalize(vert.normal);
			//mesh.normalBuffer.push(normal);

			//vert.normal = new Vec3();

			for (j in 0...vert.weightCount) {
				var weight = mesh.weights[vert.startWeight + j];
				var joint = joints[weight.jointID];
				//vert.normal += (normal * joint.orient) * weight.bias;
			}
		}
	}

	function renderMesh() {

	}

	// Computes the W component of the quaternion based on the X, Y, and Z components.
    // This method assumes the quaternion is of unit length.
    function computeQuatW(quat:Quat) {
        var t:Float = 1.0 - (quat.x * quat.x) - (quat.y * quat.y) - (quat.z * quat.z);
        
        if (t < 0.0) {
            quat.w = 0.0;
        }
        else {
            quat.w = -Math.sqrt(t);
        }
    }
}


class Md5Parser {
    
}
