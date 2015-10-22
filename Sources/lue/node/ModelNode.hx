package lue.node;

import kha.graphics4.Graphics;
import lue.math.Vec3;
import lue.math.Mat4;
import lue.resource.ModelResource;
import lue.resource.MaterialResource;

class ModelNode extends Node {

	public static inline var CONST_SHADOW_MAT4_DBMVP = 0;
	public static inline var CONST_MAT4_M = 0;
    public static inline var CONST_MAT4_V = 1;
    public static inline var CONST_MAT4_P = 2;
    public static inline var CONST_MAT4_DBMVP = 3;
    public static inline var CONST_VEC3_LIGHT = 4;
    public static inline var CONST_VEC3_EYE = 5;
    public static inline var CONST_VEC4_DIFFUSE_COLOR = 6;
    public static inline var CONST_B_TEXTURING = 7;
    public static inline var CONST_B_LIGHTING = 8;
    public static inline var CONST_B_RECEIVE_SHADOW = 9;
    public static inline var CONST_F_ROUGHNESS = 10;
    public static inline var CONST_TEX_STEX = 0;
    public static inline var CONST_TEX_SMAP = 1;

	var resource:ModelResource;
	var material:MaterialResource;

	public var dbMVP:Mat4;

	public function new(resource:ModelResource, material:MaterialResource) {
		super();

		this.resource = resource;
		this.material = material;

		dbMVP = new Mat4();

		initConstants();
		setTransformSize();

		Node.models.push(this);
	}

	function initConstants() {
	}

	function setConstants(g:Graphics, camera:CameraNode, light:LightNode) {
		setMat4(g, CONST_MAT4_M, transform.matrix);
    	setMat4(g, CONST_MAT4_V, camera.V);
    	setMat4(g, CONST_MAT4_P, camera.P);
    	setMat4(g, CONST_MAT4_DBMVP, dbMVP);
    	setVec3(g, CONST_VEC3_LIGHT, light.transform.pos);
    	setVec3(g, CONST_VEC3_EYE, camera.transform.pos);
    	setBool(g, CONST_B_LIGHTING, material.resource.lighting);
    	setBool(g, CONST_B_RECEIVE_SHADOW, material.resource.receive_shadow);
	}

	public override function render(g:Graphics, camera:CameraNode, light:LightNode) {
		super.render(g, camera, light);

		transform.update();

		// Frustum culling
		//if (Eg.camera.sphereInFrustum(transform, mesh.geometry.radius)) {
			
			//dbMVP.mult(Eg.camera.biasMat);

			// Render mesh
			g.setProgram(material.shader.program);

			/*g.setTextureParameters(mesh.material.shader.textures[1],
								   kha.graphics4.TextureAddressing.Clamp,
								   kha.graphics4.TextureAddressing.Clamp,
								   kha.graphics4.TextureFilter.LinearFilter,
								   kha.graphics4.TextureFilter.LinearFilter,
								   kha.graphics4.MipMapFilter.NoMipFilter);*/
			//g.setTexture(mesh.shader.textures[CONST_TEX_SMAP], lue.core.FrameRenderer.shadowMap);

			g.setVertexBuffer(resource.geometry.vertexBuffer);

			setConstants(g, camera, light);

			for (i in 0...resource.geometry.indexBuffers.length) {
				var indexBuffer = resource.geometry.indexBuffers[i];
				var mat = resource.geometry.materialIndices[i];

				material.setConstants(g);

				g.setIndexBuffer(indexBuffer);

				g.drawIndexedVertices();
			}
		//}
	}

	function setTransformSize() {
    	transform.size.x = resource.geometry.size.x * transform.scale.x;
		transform.size.y = resource.geometry.size.y * transform.scale.y;
		transform.size.z = resource.geometry.size.z * transform.scale.z;
    }

	inline function setMat4(g:kha.graphics4.Graphics, index:Int, m:Mat4) {
		var mat = new kha.math.Matrix4(m._11, m._21, m._31, m._41,
									   m._12, m._22, m._32, m._42,
									   m._13, m._23, m._33, m._43,
									   m._14, m._24, m._34, m._44);
		g.setMatrix(material.shader.constants[index], mat);
	}

	inline function setVec3(g:kha.graphics4.Graphics, index:Int, v:Vec3) {
		g.setFloat3(material.shader.constants[index], v.x, v.y, v.z);
	}

	inline function setVec4(g:kha.graphics4.Graphics, index:Int, v:Vec3) {
		g.setFloat4(material.shader.constants[index], v.x, v.y, v.z, v.w);
	}

	inline function setBool(g:kha.graphics4.Graphics, index:Int, b:Bool) {
		g.setBool(material.shader.constants[index], b);
	}

	inline function setFloat(g:kha.graphics4.Graphics, index:Int, f:Float) {
		g.setFloat(material.shader.constants[index], f);
	}
}
