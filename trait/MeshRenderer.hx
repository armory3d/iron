package fox.trait;

import kha.Image;
import fox.math.Mat4;
import fox.math.Vec3;
import fox.sys.material.TextureMaterial;
import fox.sys.mesh.Mesh;
import fox.sys.Assets;

class MeshRenderer extends Renderer {

	public var transform:Transform;

	@inject({asc:true,sibl:false})
	public var scene:SceneRenderer;

	public var mvpMatrix:Mat4;
	public var shadowMapMatrix:Mat4;

	public var mesh:Mesh;
	public var texturing:Bool = true;
	public var lighting:Bool = true;
	public var castShadow:Bool = false;
	public var receiveShadow:Bool = false;

	public var textures:Array<Image> = [];
	var constantMat4s:Array<Mat4> = [];
	var constantVec3s:Array<Vec3> = [];
	var constantVec4s:Array<Vec3> = [];
	var constantBools:Array<Bool> = [];

	public function new(mesh:Mesh) {
		super();

		mvpMatrix = new Mat4();
		shadowMapMatrix = new Mat4();

		this.mesh = mesh;

		if (this.mesh.material != null) this.mesh.material.registerRenderer(this);
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;

        transform.size.x = mesh.geometry.size.x * transform.scale.x;
		transform.size.y = mesh.geometry.size.y * transform.scale.y;
		transform.size.z = mesh.geometry.size.z * transform.scale.z;
    }

    public function renderShadowMap(g:kha.graphics4.Graphics) {

    	shadowMapMatrix.identity();
    	shadowMapMatrix.append(transform.matrix);
    	shadowMapMatrix.append(scene.camera.depthViewMatrix);
    	shadowMapMatrix.append(scene.camera.depthProjectionMatrix);
    	shadowMapMatrix.append(scene.camera.biasMat);

    	var shader = Assets.getShader("shadowmapshader");
		var mat = kha.math.Matrix4.empty();
		mat.matrix = shadowMapMatrix.getFloats();
		g.setMatrix(shader.constantMat4s[0], mat);

		// Render mesh
		g.setVertexBuffer(mesh.geometry.vertexBuffer);
		g.setIndexBuffer(mesh.geometry.indexBuffer);
		g.setProgram(shader.program);

		g.drawIndexedVertices();
    }

	public override function render(g:kha.graphics4.Graphics) {
		super.render(g);

		// Update model-view-projection matrix
		mvpMatrix.identity();
		mvpMatrix.append(transform.matrix);
		mvpMatrix.append(scene.camera.viewMatrix);
		mvpMatrix.append(scene.camera.projectionMatrix);
		
		// Render mesh
		g.setVertexBuffer(mesh.geometry.vertexBuffer);
		g.setIndexBuffer(mesh.geometry.indexBuffer);
		g.setProgram(mesh.material.shader.program);

		if (texturing) {
			g.setTexture(mesh.material.shader.textures[0], textures[0]);
		}

		setConstants(g);

		g.drawIndexedVertices();
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
			var mat = kha.math.Matrix4.empty();
			mat.matrix = constantMat4s[i].getFloats();
			g.setMatrix(mesh.material.shader.constantMat4s[i], mat);
		}

		for (i in 0...constantBools.length) {
			g.setBool(mesh.material.shader.constantBools[i], constantBools[i]);
		}
	}

	public override function setTexture(tex:Image) {
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

	/*public function scaleTo(x:Float, y:Float, z:Float) {
		transform.scale.x = x / mesh.geometry.size.x;
		transform.scale.y = y / mesh.geometry.size.y;
		transform.scale.z = z / mesh.geometry.size.z;
	}*/
}
