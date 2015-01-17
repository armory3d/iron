package fox.trait;

import kha.Image;
import fox.math.Mat4;
import fox.math.Vec3;
import fox.sys.material.TextureMaterial;
import fox.sys.mesh.Mesh;
import fox.sys.Assets;
import fox.core.IRenderable;

class MeshRenderer extends Renderer implements IRenderable {

	public var transform:Transform;

	@inject({asc:true,sibl:false})
	public var scene:GameScene;

	public var M:Mat4;
	public var V:Mat4; // Camera copy
	public var P:Mat4; // Camera copy
	public var dbMVP:Mat4;
	public var light:Vec3;
	public var eye:Vec3;

	public var texturing:Bool = true;
	public var lighting:Bool = true;
	public var rim:Bool = true;
	public var castShadow:Bool = false;
	public var receiveShadow:Bool = false;

	public function new(mesh:Mesh) {
		super(mesh);

		M = new Mat4();
		V = new Mat4();
		P = new Mat4();
		dbMVP = new Mat4();
		light = new Vec3();
		eye = new Vec3();
	}

	public override function initConstants() {
		setMat4(M);
		setMat4(V);
		setMat4(P);
		setMat4(dbMVP);
		//setVec3(light);
		//setVec3(eye);
		setBool(texturing);
		setBool(lighting);
		setBool(rim);
		setBool(receiveShadow);
		setTexture(fox.core.FrameRenderer.shadowMap);
	}

	@injectAdd
    public function addTransform(trait:Transform) {
        transform = trait;

        transform.size.x = mesh.geometry.size.x * transform.scale.x;
		transform.size.y = mesh.geometry.size.y * transform.scale.y;
		transform.size.z = mesh.geometry.size.z * transform.scale.z;
    }

    public function renderShadowMap(g:kha.graphics4.Graphics) {
    	if (!castShadow) return;

    	dbMVP.identity();
    	dbMVP.append(transform.matrix);
    	dbMVP.append(scene.camera.dV);
    	dbMVP.append(scene.camera.dP);

    	var shadowShader = Assets.getShader("shadowmapshader");

		// Render mesh
		g.setVertexBuffer(mesh.geometry.vertexBuffer);
		g.setIndexBuffer(mesh.geometry.indexBuffer);
		g.setProgram(shadowShader.program);

		var mat1 = new kha.math.Matrix4(dbMVP.getFloats());
		g.setMatrix(shadowShader.constantMat4s[0], mat1);

		g.drawIndexedVertices();
    }

	public function render(g:kha.graphics4.Graphics) {

		// Frustum culling
		//if (scene.camera.sphereInFrustum(transform, mesh.geometry.radius)) {
			
			fox.core.FrameRenderer.numRenders++;
			
			//dbMVP.append(scene.camera.biasMat);

			// Update matrices
			M.identity();
			M.append(transform.matrix);

			V.identity();
			V.append(scene.camera.V);

			P.identity();
			P.append(scene.camera.P);

			// Eye
			eye.set(-scene.camera.transform.x, -scene.camera.transform.y, -scene.camera.transform.z);
			
			// Light
			light.set(scene.light.transform.x, scene.light.transform.y, scene.light.transform.z);

			// Render mesh
			g.setVertexBuffer(mesh.geometry.vertexBuffer);
			g.setIndexBuffer(mesh.geometry.indexBuffer);
			g.setProgram(mesh.material.shader.program);

			if (texturing) {
				g.setTexture(mesh.material.shader.textures[0], textures[0]);
			}

			/*g.setTextureParameters(mesh.material.shader.textures[1],
								   kha.graphics4.TextureAddressing.Clamp,
								   kha.graphics4.TextureAddressing.Clamp,
								   kha.graphics4.TextureFilter.LinearFilter,
								   kha.graphics4.TextureFilter.LinearFilter,
								   kha.graphics4.MipMapFilter.NoMipFilter);*/
			g.setTexture(mesh.material.shader.textures[1], fox.core.FrameRenderer.shadowMap);

			setConstants(g);

			g.drawIndexedVertices();
		//}
	}

	/*public function scaleTo(x:Float, y:Float, z:Float) {
		transform.scale.x = x / mesh.geometry.size.x;
		transform.scale.y = y / mesh.geometry.size.y;
		transform.scale.z = z / mesh.geometry.size.z;
	}*/
}
