package lue.node;

import kha.graphics4.Graphics;
import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.MipMapFilter;
import lue.Env;
import lue.math.Vec4;
import lue.math.Mat4;
import lue.math.Quat;
import lue.resource.ModelResource;
import lue.resource.MaterialResource;
import lue.resource.ShaderResource;
import lue.resource.PipelineResource.RenderTarget; // Ping-pong
import lue.resource.SceneFormat;

class ModelNode extends Node {

	public var resource:ModelResource;
	public var materials:Array<MaterialResource>;

	public var particleSystem:ParticleSystem = null;
	public var skinning:Skinning = null;

	static var helpMat = Mat4.identity();
	static var helpMat2 = Mat4.identity();
	static var helpVec = new Vec4();

	var cachedContexts:Map<String, CachedModelContext> = new Map();
	
	// public static var _u1:Float = 0.25;
	// public static var _u2:Float = 0.1;
	// public static var _u3:Float = 5;
	// public static var _u4:Float = 3.0;
	// public static var _u5:Float = 0.0;
	// public static var _u6:Float = 0.34;

	public function new(resource:ModelResource, materials:Array<MaterialResource>) {
		super();

		this.resource = resource;
		this.materials = materials;

		// setTransformSize(); // TODO: remove

		RootNode.models.push(this);
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
				
				var colorBufIndex = -1; // Attach specific color buffer if number is appended
				var char = rtID.charAt(rtID.length - 1);
				if (char == "0") colorBufIndex = 0;
				else if (char == "1") colorBufIndex = 1;
				else if (char == "2") colorBufIndex = 2;
				else if (char == "3") colorBufIndex = 3;
				if (colorBufIndex >= 0) rtID = rtID.substr(0, rtID.length - 1);
				
				var samplerID = bindParams[pos + 1];
				var rt = camera.resource.pipeline.renderTargets.get(rtID);
				var tus = context.resource.texture_units;

				// Ping-pong
				if (rt.pong != null) {			
					if (!RenderTarget.is_last_target_pong) {
						if (RenderTarget.last_pong_target_pong)
							rt = rt.pong;
					}
					else if (!RenderTarget.is_pong) rt = rt.pong;
				}

				var postfix = "";
				if (rt.additionalImages != null && colorBufIndex == -1) postfix = "0"; // MRT - postfix main image id with 0

				for (j in 0...tus.length) { // Set texture
					if (samplerID + postfix == tus[j].id) {
						var image = colorBufIndex <= 0 ? rt.image : cast(rt.additionalImages[colorBufIndex - 1], kha.Image);
						g.setTexture(context.textureUnits[j], image);
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
		
		// Texture links
		for (j in 0...context.resource.texture_units.length) {
			var tuid = context.resource.texture_units[j].id;
			var tulink = context.resource.texture_units[j].link;
			if (tulink == "_envmapIrradiance") {
				g.setTexture(context.textureUnits[j], Env.irradiance);
			}
			else if (tulink == "_envmapRadiance") {
				g.setTexture(context.textureUnits[j], Env.radiance);
				g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.LinearMipFilter);
			}
			else if (tulink == "_envmapBrdf") {
				g.setTexture(context.textureUnits[j], Env.brdf);
			}
			else if (tulink == "_noise8") {
				g.setTexture(context.textureUnits[j], kha.Assets.images.noise8);
				g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
			}
			else if (tulink == "_noise64") {
				g.setTexture(context.textureUnits[j], kha.Assets.images.noise64);
				g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
			}
			else if (tulink == "_noise256") {
				g.setTexture(context.textureUnits[j], kha.Assets.images.noise256);
				g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
			}
			// else if (tulink == "_checker") {
				// g.setTexture(context.textureUnits[j], kha.Assets.images.checker);
				// g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
			// }
		}
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
					helpMat.inverse2(helpMat);
					helpMat.transpose23x3();
				//}
				m = helpMat;
			}
			else if (c.link == "_viewNormalMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(node.transform.matrix);
				helpMat.mult2(camera.V); // View space
				helpMat.inverse2(helpMat);
				helpMat.transpose23x3();
				m = helpMat;
			}
			else if (c.link == "_viewMatrix") {
				m = camera.V;
			}
			else if (c.link == "_transposeInverseViewMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(camera.V);
				helpMat.inverse2(helpMat);
				helpMat.transpose2();
				m = helpMat;
			}
			else if (c.link == "_inverseViewMatrix") {
				helpMat.inverse2(camera.V);
				m = helpMat;
			}
			else if (c.link == "_transposeViewMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(camera.V);
				helpMat.transpose23x3();
				m = helpMat;
			}
			else if (c.link == "_projectionMatrix") {
				m = camera.P;
			}
			else if (c.link == "_inverseProjectionMatrix") {
				helpMat.inverse2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_inverseViewProjectionMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(camera.V);
				helpMat.mult2(camera.P);
				helpMat.inverse2(helpMat);
				m = helpMat;
			}
			else if (c.link == "_modelViewProjectionMatrix") {
				helpMat.setIdentity();
		    	helpMat.mult2(node.transform.matrix);
		    	helpMat.mult2(camera.V);
		    	helpMat.mult2(camera.P);
		    	m = helpMat;
			}
			else if (c.link == "_modelViewMatrix") {
				helpMat.setIdentity();
		    	helpMat.mult2(node.transform.matrix);
		    	helpMat.mult2(camera.V);
		    	m = helpMat;
			}
			else if (c.link == "_viewProjectionMatrix") {
				helpMat.setIdentity();
		    	helpMat.mult2(camera.V);
		    	helpMat.mult2(camera.P);
		    	m = helpMat;
			}
			else if (c.link == "_prevViewProjectionMatrix") {
				helpMat.setIdentity();
		    	helpMat.mult2(camera.prevV);
		    	helpMat.mult2(camera.P);
		    	m = helpMat;
			}
			else if (c.link == "_lightModelViewProjectionMatrix") {
				helpMat.setIdentity();
		    	if (node != null) helpMat.mult2(node.transform.matrix); // node is null for DrawQuad
		    	helpMat.mult2(light.V);
		    	helpMat.mult2(light.P);
		    	m = helpMat;
			}
			else if (c.link == "_lightViewMatrix") {
		    	m = light.V;
			}
			else if (c.link == "_lightProjectionMatrix") {
		    	m = light.P;
			}
			if (m == null) return;
			g.setMatrix(location, m);
		}
		else if (c.type == "vec3") {
			var v:Vec4 = null;
			if (c.link == "_lightPosition") {
				helpVec.set(light.transform.absx(), light.transform.absy(), light.transform.absz());
				v = helpVec;
			}
			else if (c.link == "_cameraPosition") {
				helpVec.set(camera.transform.absx(), camera.transform.absy(), camera.transform.absz());
				v = helpVec;
			}
			else if (c.link == "_cameraLook") {
				var look = camera.look();
				helpVec.set(-look.x, -look.y, -look.z);
				v = helpVec;
			}
			if (v == null) return;
			g.setFloat3(location, v.x, v.y, v.z);
		}
		else if (c.type == "vec2") {
			var vx:Float = 0;
			var vy:Float = 0;
			if (c.link == "_vec2x") {
				vx = 1.0;
			}
			else if (c.link == "_vec2y") {
				vy = 1.0;
			}
			g.setFloat2(location, vx, vy);
		}
		else if (c.type == "float") {
			var f = 0.0;
			if (c.link == "_time") {
				f = lue.sys.Time.total;
			}
			else if (c.link == "_deltaTime") {
				f = lue.sys.Time.delta;
			}
			// else if (c.link == "_u1") { f = ModelNode._u1; }
			// else if (c.link == "_u2") { f = ModelNode._u2; }
			// else if (c.link == "_u3") { f = ModelNode._u3; }
			// else if (c.link == "_u4") { f = ModelNode._u4; }
			// else if (c.link == "_u5") { f = ModelNode._u5; }
			// else if (c.link == "_u6") { f = ModelNode._u6; }
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
		else if (c.type == "vec3") {
			g.setFloat3(location, matc.vec3[0], matc.vec3[1], matc.vec3[2]);
		}
		else if (c.type == "vec2") {
			g.setFloat2(location, matc.vec2[0], matc.vec2[1]);
		}
		else if (c.type == "float") {
			g.setFloat(location, matc.float);
		}
		else if (c.type == "bool") {
			g.setBool(location, matc.bool);
		}
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

	// function setTransformSize() {
    // 	transform.size.x = resource.geometry.size.x * transform.scale.x;
	// 	transform.size.y = resource.geometry.size.y * transform.scale.y;
	// 	transform.size.z = resource.geometry.size.z * transform.scale.z;
    // }
}

class CachedModelContext {
	public var materialContexts:Array<MaterialContext>;
	public var context:ShaderContext;
	public function new() {}
}
