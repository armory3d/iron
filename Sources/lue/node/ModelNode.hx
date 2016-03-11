package lue.node;

import kha.graphics4.Graphics;
import kha.graphics4.ConstantLocation;
import lue.math.Vec4;
import lue.math.Mat4;
import lue.math.Quat;
import lue.resource.ModelResource;
import lue.resource.MaterialResource;
import lue.resource.ShaderResource;
import lue.resource.importer.SceneFormat;

class ModelNode extends Node {

	public var resource:ModelResource;
	var materials:Array<MaterialResource>;

	public var particleSystem:ParticleSystem = null;
	public var skinning:Skinning = null;

	static var helpMat = Mat4.identity();

	var cachedContexts:Map<String, CachedModelContext> = new Map();

	public function new(resource:ModelResource, materials:Array<MaterialResource>) {
		super();

		this.resource = resource;
		this.materials = materials;

		setTransformSize();

		Node.models.push(this);
	}

	public function setupAnimation(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>) {
		if (resource.isSkinned) {
			skinning = new Skinning(resource);
			skinning.setupAnimation(startTrack, names, starts, ends);
		}
	}

	public function setupParticleSystem(sceneName:String, pref:TParticleReference) {
		particleSystem = new ParticleSystem(this, sceneName, pref);
	}

	public inline function setAnimationParams(delta:Float) {
		skinning.setAnimationParams(delta);
	}

	public static function setConstants(g:Graphics, context:ShaderContext, node:Node, camera:CameraNode, light:LightNode, bindParams:Array<String>) {

		for (i in 0...context.resource.constants.length) {
			var c = context.resource.constants[i];
			setConstant(g, node, camera, light, context.constants[i], c);
		}

		if (bindParams != null) { // Bind targets
			for (i in 0...Std.int(bindParams.length / 2)) {
				var pos = i * 2; // bind params = [texture, samplerID]
				var rtID = bindParams[pos];
				var samplerID = bindParams[pos + 1];
				var rt = camera.resource.pipeline.renderTargets.get(rtID);
				var tus = context.resource.texture_units;

				var postfix = "";
				if (rt.additionalImages != null) postfix = "0"; // MRT - postfix main image id with 0

				for (j in 0...tus.length) {
					if (samplerID + postfix == tus[j].id) {
						g.setTexture(context.textureUnits[j], rt.image);
					}
				}

				if (rt.additionalImages != null) { // Set MRT
					for (k in 0...rt.additionalImages.length) {
						for (j in 0...tus.length) {
							if ((samplerID + (k + 1)) == tus[j].id) {
								g.setTexture(context.textureUnits[j], cast(rt.additionalImages[k], kha.Image));
							}
						}
					}
				}
			}
		}
		// for (j in 0...context.resource.texture_units.length) { // Passing texture constants
		// 	if (context.resource.texture_units[j].id == "skinTex") {
		// 		g.setTexture(context.textureUnits[j], cast(node, ModelNode).skinTexture);
		// 	}
		// }
	}
	static function setConstant(g:Graphics, node:Node, camera:CameraNode, light:LightNode,
						 		location:ConstantLocation, c:TShaderConstant) {
		if (c.link == null) return;

		if (c.type == "mat4") {
			var m:Mat4 = null;
			if (c.link == "_modelMatrix") {
				m = node.transform.matrix;
			}
			else if (c.link == "_normalMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(node.transform.matrix);
				// Non uniform anisotropic scaling, calculate normal matrix
				//if (!(node.transform.scale.x == node.transform.scale.y && node.transform.scale.x == node.transform.scale.z)) {
				//	helpMat.mult2(camera.V); // For view space
					helpMat.inverse2(helpMat);
					helpMat.transpose2();
				//}
				m = helpMat;
			}
			else if (c.link == "_viewMatrix") {
				m = camera.V;
			}
			else if (c.link == "_inverseViewMatrix") {
				helpMat.inverse2(camera.V);
				m = helpMat;
			}
			else if (c.link == "_projectionMatrix") {
				m = camera.P;
			}
			else if (c.link == "_modelViewProjectionMatrix") {
				helpMat.setIdentity();
		    	helpMat.mult2(node.transform.matrix);
		    	helpMat.mult2(camera.V);
		    	helpMat.mult2(camera.P);
		    	m = helpMat;
			}
			else if (c.link == "_lightModelViewProjectionMatrix") {
				helpMat.setIdentity();
		    	helpMat.mult2(node.transform.matrix);
		    	helpMat.mult2(light.V);
		    	helpMat.mult2(light.P);
		    	m = helpMat;
			}
			if (m == null) return;
			g.setMatrix(location, m);
		}
		else if (c.type == "vec3") {
			var v:Vec4 = null;
			if (c.link == "_lightPosition") {
				v = light.transform.pos;
			}
			else if (c.link == "_cameraPosition") {
				v = camera.transform.pos;
			}
			if (v == null) return;
			g.setFloat3(location, v.x, v.y, v.z);
		}
		else if (c.type == "float") {
			var f = 0.0;
			if (c.link == "_time") {
				f = lue.sys.Time.total;
			}
			g.setFloat(location, f);
		}
		else if (c.type == "floats") {
			var fa:haxe.ds.Vector<kha.FastFloat> = null;
			if (c.link == "_skinBones") {
				fa = cast(node, ModelNode).skinning.skinBuffer;
			}
			g.setFloats(location, fa);
		}
	}

	public static function setMaterialConstants(g:Graphics, context:ShaderContext, materialContext:MaterialContext) {
		for (i in 0...materialContext.resource.bind_constants.length) {
			var matc = materialContext.resource.bind_constants[i];
			// TODO: cache
			var pos = -1;
			for (i in 0...context.resource.constants.length) {
				if (context.resource.constants[i].id == matc.id) {
					pos = i;
					break;
				}
			}
			if (pos == -1) continue;
			var c = context.resource.constants[pos];
			
			setMaterialConstant(g, context.constants[pos], c, matc);
		}

		if (materialContext.textures != null) {
			for (i in 0...materialContext.textures.length) {
				var mid = materialContext.resource.bind_textures[i].id;

				// TODO: cache
				for (j in 0...context.textureUnits.length) {
					var sid = context.resource.texture_units[j].id;
					if (mid == sid) {
						g.setTexture(context.textureUnits[j], materialContext.textures[i]);
						// After texture sampler have been assigned, set texture parameters
						materialContext.setTextureParameters(g, i, context, j);
						break;
					}
				}
			}
		}
	}
	static function setMaterialConstant(g:Graphics, location:ConstantLocation, c:TShaderConstant, matc:TBindConstant) {

		if (c.type == "vec4") {
			g.setFloat4(location, matc.vec4[0], matc.vec4[1], matc.vec4[2], matc.vec4[3]);
		}
		else if (c.type == "float") {
			g.setFloat(location, matc.float);
		}
		else if (c.type == "bool") {
			g.setBool(location, matc.bool);
		}
		// TODO: other types
	}

	public override function render(g:Graphics, context:String, camera:CameraNode, light:LightNode, bindParams:Array<String>) {
		super.render(g, context, camera, light, bindParams);

		// Frustum culling
		if (camera.resource.resource.frustum_culling &&
			!camera.sphereInFrustum(transform, resource.geometry.radius)) {
			return;
		}

		if (particleSystem != null) particleSystem.update();

		// Get context
		var cc = cachedContexts.get(context);
		if (cc == null) {
			cc = new CachedModelContext();
			cc.materialContexts = [];

			for (mat in materials) {
				for (i in 0...mat.resource.contexts.length) {
					if (mat.resource.contexts[i].id == context) {
						cc.materialContexts.push(mat.contexts[i]);
						break;
					}
				}
			}
			// TODO: only one shader per model
			cc.context = materials[0].shader.getContext(context);
			cachedContexts.set(context, cc);
		}

		var materialContexts = cc.materialContexts;
		var shaderContext = cc.context;
		
		//if (context == "shadowpass") {
		//	if (!material.resource.cast_shadow) return;
		//}

		transform.update();
		
		// Render mesh
		g.setPipeline(shaderContext.pipeState);
		
		if (resource.geometry.instanced) {
			g.setVertexBuffers(resource.geometry.instancedVertexBuffers);
		}
		else {
			g.setVertexBuffer(resource.geometry.vertexBuffer);
		}

		setConstants(g, shaderContext, this, camera, light, bindParams);

		for (i in 0...resource.geometry.indexBuffers.length) {
			
			var mi = resource.geometry.materialIndices[i];
			if (materialContexts.length > mi) {
				setMaterialConstants(g, shaderContext, materialContexts[mi]);
			}

			g.setIndexBuffer(resource.geometry.indexBuffers[i]);

			if (resource.geometry.instanced) {
				g.drawIndexedVerticesInstanced(resource.geometry.instanceCount);
			}
			else {
				g.drawIndexedVertices();
			}
		}
	}

	function setTransformSize() {
    	transform.size.x = resource.geometry.size.x * transform.scale.x;
		transform.size.y = resource.geometry.size.y * transform.scale.y;
		transform.size.z = resource.geometry.size.z * transform.scale.z;
    }
}

class CachedModelContext {
	public var materialContexts:Array<MaterialContext>;
	public var context:ShaderContext;
	public function new() {}
}
