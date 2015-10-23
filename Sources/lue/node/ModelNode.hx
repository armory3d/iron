package lue.node;

import kha.graphics4.Graphics;
import kha.graphics4.ConstantLocation;
import lue.math.Vec3;
import lue.math.Mat4;
import lue.resource.ModelResource;
import lue.resource.MaterialResource;
import lue.resource.importer.SceneFormat;

class ModelNode extends Node {

	var resource:ModelResource;
	var material:MaterialResource;

	var dbMVP:Mat4;

	public function new(resource:ModelResource, material:MaterialResource) {
		super();

		this.resource = resource;
		this.material = material;

		dbMVP = new Mat4();

		setTransformSize();

		Node.models.push(this);
	}

	function setConstants(g:Graphics, camera:CameraNode, light:LightNode) {
		for (i in 0...material.shader.resource.constants.length) {
			var c = material.shader.resource.constants[i];

			setConstant(g, camera, light, material.shader.constants[i], c);
		}
    	//TODO: setMat4(g, CONST_MAT4_DBMVP, dbMVP);
	}

	function setConstant(g:Graphics, camera:CameraNode, light:LightNode,
						 location:ConstantLocation, c:TShaderConstant) {
		if (c.type == "mat4") {
			var m:Mat4 = null;
			if (c.value == "_modelMatrix") m = transform.matrix;
			else if (c.value == "_viewMatrix") m = camera.V;
			else if (c.value == "_projectionMatrix") m = camera.P;
			if (m == null) return;

			var mat = new kha.math.Matrix4(m._11, m._21, m._31, m._41,
									  	   m._12, m._22, m._32, m._42,
										   m._13, m._23, m._33, m._43,
									       m._14, m._24, m._34, m._44);
			g.setMatrix(location, mat);
		}
		else if (c.type == "vec3") {
			var v:Vec3 = null;
			if (c.value == "_lightPosition") v = light.transform.pos;
			else if (c.value == "_cameraPosition") v = camera.transform.pos;
			if (v == null) return;
			g.setFloat3(location, v.x, v.y, v.z);
		}
		// TODO: other types
	}

	function setMaterialConstants(g:Graphics) {
		for (i in 0...material.resource.params.length) {
			var p = material.resource.params[i];
			// TODO: material params must be in the same order as shader material constants
			var c = material.shader.resource.material_constants[i];

			setMaterialConstant(g, material.shader.materialConstants[i], c, p);
		}

		for (i in 0...material.textures.length) {
			g.setTexture(material.shader.textureUnits[i], material.textures[i]);
		}
	}

	function setMaterialConstant(g:Graphics, location:ConstantLocation, c:TShaderMaterialConstant, p:TMaterialParam) {
		if (c.type == "vec4") {
			g.setFloat4(location, p.vec4[0], p.vec4[1], p.vec4[2], p.vec4[3]);
		}
		else if (c.type == "float") {
			g.setFloat(location, p.float);
		}
		else if (c.type == "bool") {
			g.setBool(location, p.bool);
		}
		// TODO: other types
	}

	public override function render(g:Graphics, camera:CameraNode, light:LightNode) {
		super.render(g, camera, light);

		transform.update();

		// Frustum culling
		//if (camera.sphereInFrustum(transform, mesh.geometry.radius)) {
			
			//dbMVP.mult(camera.biasMat);

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
				
				// TODO: only one material per model
				//var mat = resource.geometry.materialIndices[i];
				setMaterialConstants(g);

				g.setIndexBuffer(resource.geometry.indexBuffers[i]);

				g.drawIndexedVertices();
			}
		//}
	}

	function setTransformSize() {
    	transform.size.x = resource.geometry.size.x * transform.scale.x;
		transform.size.y = resource.geometry.size.y * transform.scale.y;
		transform.size.z = resource.geometry.size.z * transform.scale.z;
    }
}
