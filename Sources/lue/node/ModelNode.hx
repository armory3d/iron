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

	var resource:ModelResource;
	var material:MaterialResource;

	//static var dbMVP:Mat4 = null;
	var dbMVP:Mat4 = null;

	// Skinned
	var animation:Animation;
	var boneMats = new Map<TNode, Mat4>();
	var boneTimeIndices = new Map<TNode, Int>();

	var m = new Mat4(); // Skinning matrix
	var bm = new Mat4(); // Absolute bone matrix
	var pos = new Vec3();
	var nor = new Vec3();

	public function new(resource:ModelResource, material:MaterialResource) {
		super();

		this.resource = resource;
		this.material = material;

		//if (dbMVP == null) dbMVP = new Mat4();
		dbMVP = new Mat4();

		setTransformSize();

		Node.models.push(this);
	}

	public function setupAnimation(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>) {
		if (resource.isSkinned) {
			animation = new Animation(startTrack, names, starts, ends);
			for (b in resource.geometry.skeletonBones) {
				boneMats.set(b, new Mat4(b.transform.values));
				boneTimeIndices.set(b, 0);
			}
		}
	}

	function setConstants(g:Graphics, context:ShaderContext, camera:CameraNode, light:LightNode) {

		for (i in 0...context.resource.constants.length) {
			var c = context.resource.constants[i];

			setConstant(g, camera, light, context.constants[i], c);
		}

		for (i in 0...context.textureUnits.length) {
			var tures = context.resource.texture_units[i];
			if (tures.value == "_shadowpass") {
				g.setTexture(context.textureUnits[i], camera.resource.shadowMap);
			}
		}
	}

	function setConstant(g:Graphics, camera:CameraNode, light:LightNode,
						 location:ConstantLocation, c:TShaderConstant) {

		if (c.type == "mat4") {
			var m:Mat4 = null;
			if (c.value == "_modelMatrix") m = transform.matrix;
			else if (c.value == "_viewMatrix") m = camera.V;
			else if (c.value == "_projectionMatrix") m = camera.P;
			else if (c.value == "_dbMVP") {
				dbMVP.identity();
		    	dbMVP.mult(transform.matrix);
		    	dbMVP.mult(camera.dV);
		    	dbMVP.mult(camera.dP);
		    	m = dbMVP;
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
			if (c.value == "_lightPosition") v = light.transform.pos;
			else if (c.value == "_cameraPosition") v = camera.transform.pos;
			if (v == null) return;
			g.setFloat3(location, v.x, v.y, v.z);
		}
		// TODO: other types
	}

	function setMaterialConstants(g:Graphics, context:ShaderContext, materialContext:MaterialContext) {

		for (i in 0...materialContext.resource.material_constants.length) {
			var matc = materialContext.resource.material_constants[i];
			// TODO: material params must be in the same order as shader material constants
			var c = context.resource.material_constants[i];

			setMaterialConstant(g, context.materialConstants[i], c, matc);
		}

		if (materialContext.textures != null) {
			for (i in 0...materialContext.textures.length) {
				g.setTexture(context.textureUnits[i], materialContext.textures[i]);
			}
		}
	}

	function setMaterialConstant(g:Graphics, location:ConstantLocation, c:TShaderMaterialConstant, matc:TMaterialConstant) {

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

	public override function render(g:Graphics, context:String, camera:CameraNode, light:LightNode) {
		super.render(g, context, camera, light);

		// Find context
		var materialContext:MaterialContext = null;
		var shaderContext:ShaderContext = null;
		for (i in 0...material.resource.contexts.length) {
			// TODO: make sure contexts are stored in the same order
			if (material.resource.contexts[i].id == context) {
				materialContext = material.contexts[i];
				shaderContext = material.shader.contexts[i];
				break;
			}
		}

		if (context == "shadowpass") {
			if (!material.resource.cast_shadow) return;
		}

		transform.update();

		// Frustum culling
		//if (camera.sphereInFrustum(transform, mesh.geometry.radius)) {
			
			//dbMVP.mult(camera.biasMat);

			// Render mesh
			g.setProgram(shaderContext.program);

			/*g.setTextureParameters(mesh.material.shader.textures[1],
								   kha.graphics4.TextureAddressing.Clamp,
								   kha.graphics4.TextureAddressing.Clamp,
								   kha.graphics4.TextureFilter.LinearFilter,
								   kha.graphics4.TextureFilter.LinearFilter,
								   kha.graphics4.MipMapFilter.NoMipFilter);*/
			//g.setTexture(mesh.shader.textures[CONST_TEX_SMAP], lue.core.FrameRenderer.shadowMap);

			g.setVertexBuffer(resource.geometry.vertexBuffer);

			setConstants(g, shaderContext, camera, light);

			for (i in 0...resource.geometry.indexBuffers.length) {
				
				// TODO: only one material per model
				//var mat = resource.geometry.materialIndices[i];
				setMaterialConstants(g, shaderContext, materialContext);

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

    public function setAnimationParams(delta:Float) {
    	if (resource.isSkinned) {
    		animation.animTime += delta;

			updateAnim();
			updateSkin();

			animation.dirty = false;
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
					animation.timeIndex = animation.current.start;
					animation.animTime = track.time.values[animation.timeIndex];
				}

				//var timeIndex = boneTimeIndices.get(b);

				// Move keyframe
				while (animation.animTime > track.time.values[animation.timeIndex + 1]) {
					animation.timeIndex++;
				}
				//boneTimeIndices.set(b, timeIndex);

				// Rewind
				if (animation.timeIndex >= track.time.values.length - 2 ||
					animation.timeIndex >= animation.current.end) {
					animation.timeIndex = animation.current.start;
					animation.animTime = track.time.values[animation.timeIndex];
					//boneTimeIndices.set(b, animation.timeIndex);
					//continue;
					return;
				}

				var t1 = track.time.values[animation.timeIndex];
				var t2 = track.time.values[animation.timeIndex + 1];
				var s = (animation.animTime - t1) / (t2 - t1);

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

	function updateSkin() {
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

				// TODO: remove skin transform
				m.mult(resource.geometry.skinTransform);

				m.mult(resource.geometry.skeletonTransformsI[boneIndex]);

				bm.loadFrom(boneMats.get(bone));
				var p = bone.parent;
				while (p != null) {
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

			v.set(i * l, pos.x);
			v.set(i * l + 1, pos.y);
			v.set(i * l + 2, pos.z);
			v.set(i * l + 5, nor.x);
			v.set(i * l + 6, nor.y);
			v.set(i * l + 7, nor.z);
		}

		resource.geometry.vertexBuffer.unlock();
	}
}

class Animation {

	public var animTime:Float = 0;
	public var timeIndex:Int = 0; // TODO: use boneTimeIndices
	public var dirty:Bool = false;

	public var current:Track;
	var tracks:Map<String, Track> = new Map();

    public function new(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>) {

        for (i in 0...names.length) {
        	addTrack(names[i], starts[i], ends[i]);
        }

        play(startTrack);
    }

    public function play(name:String) {
 		current = tracks.get(name);
 		dirty = true;
    }

    public function pause() {

    }

    public function stop() {

    }

    function addTrack(name:String, start:Int, end:Int) {
    	var t = new Track(start, end);
    	tracks.set(name, t);
    }
}

class Track {
	public var start:Int;
	public var end:Int;

	public function new(start:Int, end:Int) {
		this.start = start;
		this.end = end;
	}
}
