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

	static var helpMat:Mat4 = new Mat4();

	// Skinned
	var animation:Animation;
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
			for (b in resource.geometry.skeletonBones) {
				boneMats.set(b, new Mat4(b.transform.values));
				boneTimeIndices.set(b, 0);
			}
		}
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
	}
	static function setConstant(g:Graphics, node:Node, camera:CameraNode, light:LightNode,
						 		location:ConstantLocation, c:TShaderConstant) {
		if (c.link == null) return;

		if (c.type == "mat4") {
			var m:Mat4 = null;
			if (c.link == "_modelMatrix") m = node.transform.matrix;
			else if (c.link == "_viewMatrix") m = camera.V;
			else if (c.link == "_inverseViewMatrix") {
				helpMat.inverse(camera.V);
				m = helpMat;
			}
			else if (c.link == "_projectionMatrix") m = camera.P;
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
			if (c.link == "_lightPosition") v = light.transform.pos;
			else if (c.link == "_cameraPosition") v = camera.transform.pos;
			if (v == null) return;
			g.setFloat3(location, v.x, v.y, v.z);
		}
		else if (c.type == "float") {
			var f = 0.0;
			if (c.link == "_time") f = lue.sys.Time.total;
			g.setFloat(location, f);
		}
		// TODO: other types
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

		// Frustum culling
		//if (camera.sphereInFrustum(transform, mesh.geometry.radius)) {

			// Render mesh
			g.setPipeline(shaderContext.pipeState);

			g.setVertexBuffer(resource.geometry.vertexBuffer);

			setConstants(g, shaderContext, this, camera, light, bindParams);

			for (i in 0...resource.geometry.indexBuffers.length) {
				
				var mi = resource.geometry.materialIndices[i];
				if (materialContexts.length > mi) {
					setMaterialConstants(g, shaderContext, materialContexts[mi]);
				}

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

class CachedModelContext {
	public var materialContexts:Array<MaterialContext>;
	public var context:ShaderContext;
	public function new() {}
}
