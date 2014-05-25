package wings.w3d.scene;

import kha.graphics.Texture;
import kha.Painter;
import kha.Sys;
import wings.w3d.material.TextureMaterial;
import wings.w3d.material.Shader;
import wings.w3d.mesh.Mesh;
import wings.w3d.mesh.Geometry;
import wings.math.Mat4;
import wings.math.Vec3;
import wings.w3d.Object;

class Model extends Object {

	public var mesh:Mesh;

	var textures:Array<Texture>;
	var constantMat4s:Array<Mat4>;
	var constantVec3s:Array<Vec3>;

	public function new(mesh:Mesh, parent:Object = null) {
		super(parent);

		this.mesh = mesh;

		textures = new Array();
		constantMat4s = new Array();
		constantVec3s = new Array();

		for (i in 0...mesh.materials.length) {
			if (mesh.materials[i] != null) mesh.materials[i].registerModel(this);
		}
	}

	public override function render(painter:Painter) {
		super.render(painter);

		// TODO: prevent empty material
		/*if (mesh.geometries[i] == null || mesh.material == null) {
			if (mesh.material == null)
				mesh.material = new TextureMaterial(com.luboslenco.test.R.shader, com.luboslenco.test.R.box);
			return;
		}*/
		
		for (i in 0...mesh.geometries.length) {
			Sys.graphics.setVertexBuffer(mesh.geometries[i].vertexBuffer);
			Sys.graphics.setIndexBuffer(mesh.geometries[i].indexBuffer);
			Sys.graphics.setProgram(mesh.materials[i].shader.program);
		
			Sys.graphics.setTexture(mesh.materials[i].shader.textures[0], textures[i]);
		
			setConstants(i);

			Sys.graphics.drawIndexedVertices();
		}
	}

	function setConstants(pos:Int) {
		for (i in 0...constantVec3s.length) {
			Sys.graphics.setFloat3(mesh.materials[pos].shader.constantVec3s[i], constantVec3s[i].x,
								   constantVec3s[i].y, constantVec3s[i].z);
		}
		
		for (i in 0...constantMat4s.length) {
			var mat = kha.math.Matrix4.empty();
			mat.matrix = constantMat4s[i].getFloats();
			Sys.graphics.setMatrix(mesh.materials[pos].shader.constantMat4s[i], mat);
		}
	}

	public function setTexture(tex:Texture) {
		textures.push(tex);
	}

	public function setVec3(vec:Vec3) {
		constantVec3s.push(vec);
	}

	public function setMat4(mat:Mat4) {
		constantMat4s.push(mat);
	}

	// TODO: move to object and set size vector with geometry.size
	public function scaleTo(x:Float, y:Float, z:Float) {
		scale.x = x / mesh.geometries[0].size.x;
		scale.y = y / mesh.geometries[0].size.y;
		scale.z = z / mesh.geometries[0].size.z;
	}
}
