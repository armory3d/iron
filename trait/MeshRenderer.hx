package wings.trait;

import kha.graphics.Texture;
import kha.Sys;
import wings.math.Mat4;
import wings.math.Vec3;
import wings.sys.material.TextureMaterial;
import wings.sys.mesh.Mesh;
import wings.sys.Assets;

class MeshRenderer extends Renderer {

	@inject
	public var transform:Transform;

	@inject({asc:true,sibl:false})
	public var scene:SceneRenderer;

	public var mvpMatrix:Mat4;

	var mesh:Mesh;

	public var textures:Array<Texture>;
	var constantMat4s:Array<Mat4>;
	var constantVec3s:Array<Vec3>;
	var constantVec4s:Array<Vec3>;

	public function new(mesh:String) {
		super();

		mvpMatrix = new Mat4();

		this.mesh = Assets.getMesh(mesh);

		textures = new Array();
		constantMat4s = new Array();
		constantVec3s = new Array();
		constantVec4s = new Array();

		if (this.mesh.material != null) this.mesh.material.registerRenderer(this);
	}

	public var prerenderCallBack:Int->Void = null;
	public var renderPasses = 1;

	public override function render() {
		super.render();

		// Update model-view-projection matrix
		mvpMatrix.identity();
		mvpMatrix.append(transform.matrix);
		mvpMatrix.append(scene.camera.viewMatrix);
		mvpMatrix.append(scene.camera.projectionMatrix);
		
		// Render mesh
		Sys.graphics.setVertexBuffer(mesh.geometry.vertexBuffer);
		Sys.graphics.setIndexBuffer(mesh.geometry.indexBuffer);
		Sys.graphics.setProgram(mesh.material.shader.program);
	
		for (i in 0...renderPasses) {

			if (prerenderCallBack != null) prerenderCallBack(i);

			Sys.graphics.setTexture(mesh.material.shader.textures[0], textures[0]);

			setConstants();

			Sys.graphics.drawIndexedVertices();
		}
	}

	function setConstants() {
		for (i in 0...constantVec3s.length) {
			Sys.graphics.setFloat3(mesh.material.shader.constantVec3s[i], constantVec3s[i].x,
								   constantVec3s[i].y, constantVec3s[i].z);
		}

		for (i in 0...constantVec4s.length) {
			Sys.graphics.setFloat4(mesh.material.shader.constantVec4s[i], constantVec4s[i].x,
								   constantVec4s[i].y, constantVec4s[i].z, constantVec4s[i].w);
		}
		
		for (i in 0...constantMat4s.length) {
			var mat = kha.math.Matrix4.empty();
			mat.matrix = constantMat4s[i].getFloats();
			Sys.graphics.setMatrix(mesh.material.shader.constantMat4s[i], mat);
		}
	}

	public override function setTexture(tex:Texture) {
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

	/*public function scaleTo(x:Float, y:Float, z:Float) {
		transform.scale.x = x / mesh.geometry.size.x;
		transform.scale.y = y / mesh.geometry.size.y;
		transform.scale.z = z / mesh.geometry.size.z;
	}*/
}
