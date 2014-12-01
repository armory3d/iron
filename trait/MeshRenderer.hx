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
	public var scene:SceneRenderer;

	public var mvpMatrix:Mat4;
	public var viewMatrix:Mat4; // Camera copy
	public var shadowMapMatrix:Mat4;

	public var texturing:Bool = true;
	public var lighting:Bool = true;
	public var rim:Bool = true;
	public var castShadow:Bool = false;
	public var receiveShadow:Bool = false;

	public function new(mesh:Mesh) {
		super(mesh);

		mvpMatrix = new Mat4();
		shadowMapMatrix = new Mat4();
		viewMatrix = new Mat4();
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
    	shadowMapMatrix.append(scene.camera.depthModelMatrix);
    	shadowMapMatrix.append(scene.camera.depthViewMatrix);
    	//shadowMapMatrix.append(scene.camera.depthProjectionMatrix);
    	shadowMapMatrix.append(scene.camera.projectionMatrix);

    	var shadowShader = Assets.getShader("shadowmapshader");

		// Render mesh
		g.setVertexBuffer(mesh.geometry.vertexBuffer);
		g.setIndexBuffer(mesh.geometry.indexBuffer);
		g.setProgram(shadowShader.program);

		var mat1 = new kha.math.Matrix4(shadowMapMatrix.getFloats());
		var mat2 = new kha.math.Matrix4(transform.matrix.getFloats());
		g.setMatrix(shadowShader.constantMat4s[0], mat1);
		g.setMatrix(shadowShader.constantMat4s[1], mat2);

		g.drawIndexedVertices();
    }

	public function render(g:kha.graphics4.Graphics) {

		// Frustum culling
		if (scene.camera.sphereInFrustum(transform, mesh.geometry.radius)) {
			fox.core.FrameRenderer.numRenders++;
			//shadowMapMatrix.append(scene.camera.biasMat);

			// Update model-view-projection matrix
			mvpMatrix.identity();
			mvpMatrix.append(transform.matrix);
			mvpMatrix.append(scene.camera.viewMatrix);
			mvpMatrix.append(scene.camera.projectionMatrix);

			viewMatrix.identity();
			viewMatrix.append(scene.camera.viewMatrix);
			
			// Render mesh
			g.setVertexBuffer(mesh.geometry.vertexBuffer);
			g.setIndexBuffer(mesh.geometry.indexBuffer);
			g.setProgram(mesh.material.shader.program);

			if (texturing) {
				g.setTexture(mesh.material.shader.textures[0], textures[0]);
			}

			/*g.setTexture(mesh.material.shader.textures[0], fox.core.FrameRenderer.shadowMap);
			g.setTextureParameters(mesh.material.shader.textures[1],
								   kha.graphics4.TextureAddressing.Clamp,
								   kha.graphics4.TextureAddressing.Clamp,
								   kha.graphics4.TextureFilter.LinearFilter,
								   kha.graphics4.TextureFilter.LinearFilter,
								   kha.graphics4.MipMapFilter.NoMipFilter);
			g.setTexture(mesh.material.shader.textures[1], fox.core.FrameRenderer.shadowMap);*/

			setConstants(g);

			g.drawIndexedVertices();
		}
	}

	/*public function scaleTo(x:Float, y:Float, z:Float) {
		transform.scale.x = x / mesh.geometry.size.x;
		transform.scale.y = y / mesh.geometry.size.y;
		transform.scale.z = z / mesh.geometry.size.z;
	}*/
}
