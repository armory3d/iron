package fox.trait;

import kha.Image;
import fox.core.Trait;
import fox.math.Mat4;
import fox.math.Vec3;
import fox.sys.mesh.Mesh;

class Renderer extends Trait {

	public var mesh:Mesh;

	public var textures:Array<Image> = [];
	var constantMat4s:Array<Mat4> = [];
	var constantVec3s:Array<Vec3> = [];
	var constantVec4s:Array<Vec3> = [];
	var constantBools:Array<Bool> = [];

	public function new(mesh:Mesh) {
		super();

		this.mesh = mesh;

		if (this.mesh.material != null) this.mesh.material.registerRenderer(this);
	}

	function setConstants(g:kha.graphics4.Graphics) {
		for (i in 0...constantVec3s.length) {
			g.setFloat3(mesh.material.shader.constantVec3s[i], constantVec3s[i].x,
						constantVec3s[i].y, constantVec3s[i].z);
		}

		for (i in 0...constantVec4s.length) {
			g.setFloat4(mesh.material.shader.constantVec4s[i], constantVec4s[i].x,
						constantVec4s[i].y, constantVec4s[i].z, constantVec4s[i].w);
		}
		
		for (i in 0...constantMat4s.length) {
			var mat = new kha.math.Matrix4(constantMat4s[i].getFloats());
			g.setMatrix(mesh.material.shader.constantMat4s[i], mat);
		}

		for (i in 0...constantBools.length) {
			g.setBool(mesh.material.shader.constantBools[i], constantBools[i]);
		}
	}

	public function setTexture(tex:Image) {
		textures.push(tex);
	}

	public function setVec3(vec:Vec3) {
		constantVec3s.push(vec);
	}

	public function setVec4(vec:Vec3) {
		constantVec4s.push(vec);
	}

	public function setMat4(mat:Mat4) {
		constantMat4s.push(mat);
	}

	public function setBool(b:Bool) {
		constantBools.push(b);
	}
}
