package lue.node;

import kha.graphics4.Graphics;
import kha.graphics4.ConstantLocation;
import lue.math.Vec3;
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

	static var helpMat:Mat4 = new Mat4();

	// Skinned
	var skinBuffer:Array<Float>;
	public var animation:Animation = null;
	var boneMats = new Map<TNode, Mat4>();
	var boneTimeIndices = new Map<TNode, Int>();

	var m = new Mat4(); // Skinning matrix
	var bm = new Mat4(); // Absolute bone matrix
	var pos = new Vec3();
	var nor = new Vec3();

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
			animation = new Animation(startTrack, names, starts, ends);

			if (!ModelResource.ForceCpuSkinning) {
				skinBuffer = [];
				for (i in 0...(50 * 12)) skinBuffer.push(0);
			}

			for (b in resource.geometry.skeletonBones) {
				boneMats.set(b, new Mat4(b.transform.values));
				boneTimeIndices.set(b, 0);
			}
		}
	}

	public function setupParticleSystem(sceneName:String, pref:TParticleReference) {
		particleSystem = new ParticleSystem(this, sceneName, pref);
	}

	public static function setConstants(g:Graphics, context:ShaderContext, node:Node, camera:CameraNode, light:LightNode, bindParams:Array<String>) {

		for (i in 0...context.resource.constants.length) {
			var c = context.resource.constants[i];
			setConstant(g, node, camera, light, context.constants[i], c);
		}

		if (bindParams != null) {
			for (i in 0...Std.int(bindParams.length / 2)) {
				var pos = i * 2 + 1;
				for (j in 0...context.resource.texture_units.length) {
					if (bindParams[pos] == context.resource.texture_units[j].id) {
						g.setTexture(context.textureUnits[j], camera.resource.pipeline.renderTargets.get(bindParams[pos - 1]));
					}
				}
			}
		}
		// for (j in 0...context.resource.texture_units.length) { // TODO: properly pass skin texture!
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
				helpMat.identity();
				helpMat.mult(node.transform.matrix);
				helpMat.mult(camera.V);
				helpMat.inverse(helpMat);
				helpMat.transpose();
				m = helpMat;
			}
			else if (c.link == "_viewMatrix") {
				m = camera.V;
			}
			else if (c.link == "_inverseViewMatrix") {
				helpMat.inverse(camera.V);
				m = helpMat;
			}
			else if (c.link == "_projectionMatrix") {
				m = camera.P;
			}
			else if (c.link == "_MVP") {
				helpMat.identity();
		    	helpMat.mult(node.transform.matrix);
		    	helpMat.mult(camera.V);
		    	helpMat.mult(camera.P);
		    	m = helpMat;
			}
			else if (c.link == "_lightMVP") {
				helpMat.identity();
		    	helpMat.mult(node.transform.matrix);
		    	helpMat.mult(light.V);
		    	helpMat.mult(light.P);
		    	m = helpMat;
			}
			if (m == null) return;

			var mat = new kha.math.Matrix4(m._11, m._21, m._31, m._41,
									  	   m._12, m._22, m._32, m._42,
										   m._13, m._23, m._33, m._43,
									       m._14, m._24, m._34, m._44);
			g.setMatrix(location, mat);
		}
		else if (c.type == "vec3") {
			var v:Vec3 = null;
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
			var fa:Array<Float> = null;
			if (c.link == "_skinBones") {
				fa = cast(node, ModelNode).skinBuffer;
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
						// TODO: remove setparams
						g.setTextureParameters(context.textureUnits[j], kha.graphics4.TextureAddressing.Repeat, kha.graphics4.TextureAddressing.Repeat, kha.graphics4.TextureFilter.LinearFilter, kha.graphics4.TextureFilter.LinearFilter, kha.graphics4.MipMapFilter.NoMipFilter);
						g.setTexture(context.textureUnits[j], materialContext.textures[i]);
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

    public function setAnimationParams(delta:Float) {
    	if (resource.isSkinned) {
    		
    		if (animation.paused) return;

    		animation.animTime += delta * animation.speed;

			updateAnim();
			updateSkin();
		}
    }

    function updateAnim() {
    	// Animate bones
		for (b in resource.geometry.skeletonBones) {
			var boneAnim = b.animation;

			if (boneAnim != null) {
				var track = boneAnim.track;

				// Current track has been changed
				if (animation.dirty) {
					animation.dirty = false;
					// Single frame - set skin and pause
					if (animation.current.frames == 0) {
						animation.paused = true;
						setAnimFrame(animation.current.start);
						return;
					}
					// Animation - loop frames
					else {
						animation.timeIndex = animation.current.start;
						animation.animTime = track.time.values[animation.timeIndex];
					}
				}

				// Move keyframe
				//var timeIndex = boneTimeIndices.get(b);
				while (track.time.values.length > (animation.timeIndex + 1) &&
					   animation.animTime > track.time.values[animation.timeIndex + 1]) {
					animation.timeIndex++;
				}
				//boneTimeIndices.set(b, timeIndex);

				// End of track
				if (animation.timeIndex >= track.time.values.length - 1 ||
					animation.timeIndex >= animation.current.end) {

					// Rewind
					if (animation.loop) {
						animation.dirty = true;
					}
					// Pause
					else {
						animation.paused = true;
					}

					// Give chance to change current track
					if (animation.onTrackComplete != null) animation.onTrackComplete();

					//boneTimeIndices.set(b, animation.timeIndex);
					//continue;
					return;
				}

				var t1 = track.time.values[animation.timeIndex];
				var t2 = track.time.values[animation.timeIndex + 1];
				var s = (animation.animTime - t1) / (t2 - t1);
				// TODO: lerp is inverted on certain nodes
				if (b.id == "stringPuller") {
					s = 1.0 - s;
				}

				var v1:Array<Float> = track.value.values[animation.timeIndex];
				var v2:Array<Float> = track.value.values[animation.timeIndex + 1];

				var m1 = new Mat4(v1);
				var m2 = new Mat4(v2);

				// Decompose
				var p1 = m1.pos();
				var p2 = m2.pos();
				var s1 = m1.scaleV();
				var s2 = m2.scaleV();
				var q1 = m1.getQuat();
				var q2 = m2.getQuat();

				// Lerp
				var fp = Vec3.lerp(p1, p2, s);
				var fs = Vec3.lerp(s1, s2, s);
				var fq = Quat.lerp(q1, q2, s);

				// Compose
				var m = boneMats.get(b);
				fq.saveToMatrix(m);
				m.scale(fs);
				m._41 = fp.x;
				m._42 = fp.y;
				m._43 = fp.z;
				boneMats.set(b, m);
			}
		}
	}

	function setAnimFrame(frame:Int) {
		for (b in resource.geometry.skeletonBones) {
			var boneAnim = b.animation;

			if (boneAnim != null) {
				var track = boneAnim.track;
				var v1:Array<Float> = track.value.values[frame];
				var m1 = new Mat4(v1);
				boneMats.set(b, m1);
			}
		}
		updateSkin();
	}

	function updateSkin() {
		if (ModelResource.ForceCpuSkinning) updateSkinCpu();
		else updateSkinGpu();
	}

	function updateSkinGpu() {
		var bones = resource.geometry.skeletonBones;
		for (i in 0...bones.length) {
			
			bm.loadFrom(resource.geometry.skinTransform);
			bm.mult(resource.geometry.skeletonTransformsI[i]);
			var m = new Mat4();
			m.loadFrom(boneMats.get(bones[i]));
			var p = bones[i].parent;
			while (p != null) { // TODO: store absolute transforms per bone
				var pm = boneMats.get(p);
				if (pm == null) pm = new Mat4(p.transform.values);
				m.mult(pm);
				p = p.parent;
			}
			bm.mult(m);
			bm.transpose();

		 	skinBuffer[i * 12] = bm._11;
		 	skinBuffer[i * 12 + 1] = bm._12;
		 	skinBuffer[i * 12 + 2] = bm._13;
		 	skinBuffer[i * 12 + 3] = bm._14;
		 	skinBuffer[i * 12 + 4] = bm._21;
		 	skinBuffer[i * 12 + 5] = bm._22;
		 	skinBuffer[i * 12 + 6] = bm._23;
		 	skinBuffer[i * 12 + 7] = bm._24;
		 	skinBuffer[i * 12 + 8] = bm._31;
		 	skinBuffer[i * 12 + 9] = bm._32;
		 	skinBuffer[i * 12 + 10] = bm._33;
		 	skinBuffer[i * 12 + 11] = bm._34;
		}
	}

	function updateSkinCpu() {
		var v = resource.geometry.vertexBuffer.lock();
		var l = resource.geometry.structureLength;

		var index = 0;

		for (i in 0...Std.int(v.length / l)) {

			var boneCount = resource.geometry.skinBoneCounts[i];
			var boneIndices = [];
			var boneWeights = [];
			for (j in index...(index + boneCount)) {
				boneIndices.push(resource.geometry.skinBoneIndices[j]);
				boneWeights.push(resource.geometry.skinBoneWeights[j]);
			}
			index += boneCount;

			pos.set(0, 0, 0);
			nor.set(0, 0, 0);
			for (j in 0...boneCount) {
				var boneIndex = boneIndices[j];
				var boneWeight = boneWeights[j];
				var bone = resource.geometry.skeletonBones[boneIndex];

				// Position
				m.initTranslate(resource.geometry.positions[i * 3],
								resource.geometry.positions[i * 3 + 1],
								resource.geometry.positions[i * 3 + 2]);

				m.mult(resource.geometry.skinTransform);

				m.mult(resource.geometry.skeletonTransformsI[boneIndex]);

				bm.loadFrom(boneMats.get(bone));
				var p = bone.parent;
				while (p != null) { // TODO: store absolute transforms per bone
					var pm = boneMats.get(p);
					if (pm == null) pm = new Mat4(p.transform.values);
					bm.mult(pm);
					p = p.parent;
				}
				m.mult(bm);

				m.multiplyScalar(boneWeight);
				
				pos.add(m.pos());

				// Normal
				m.getInverse(bm);

				m.mult(resource.geometry.skeletonTransforms[boneIndex]);

				m.mult(resource.geometry.skinTransformI);

				m.translate(resource.geometry.normals[i * 3],
							resource.geometry.normals[i * 3 + 1],
							resource.geometry.normals[i * 3 + 2]);

				m.multiplyScalar(boneWeight);

				nor.add(m.pos());
			}

			// TODO: use correct vertex structure
			v.set(i * l, pos.x);
			v.set(i * l + 1, pos.y);
			v.set(i * l + 2, pos.z);
			v.set(i * l + 3, nor.x);
			v.set(i * l + 4, nor.y);
			v.set(i * l + 5, nor.z);
		}

		resource.geometry.vertexBuffer.unlock();
	}
}

class CachedModelContext {
	public var materialContexts:Array<MaterialContext>;
	public var context:ShaderContext;
	public function new() {}
}
