package fox.trait;

import fox.core.Object;
import fox.core.Trait;
import fox.sys.importer.DaeData;
import fox.sys.importer.Animation;
import fox.sys.importer.AnimationClip;
import fox.sys.importer.AnimationClip.AnimationWrap;
import fox.sys.material.Material;
import fox.sys.material.TextureMaterial;
import fox.sys.mesh.SkinnedMesh;
import fox.sys.Assets;
import fox.sys.mesh.Geometry;
import fox.sys.mesh.Mesh;
import fox.trait.Renderer;
import fox.trait.MeshRenderer;
import fox.trait.SkinnedMeshRenderer;
import fox.trait.SceneRenderer;
import fox.trait.Transform;

typedef TGameData = {
	materials:Array<TGameMaterial>,
	scene:String,
	orient:Int,
	packageName:String,
	gravity:Array<Float>,
	clear:Array<Float>,
	fogColor:Array<Float>,
	fogDensity:Float,
	shadowMapping:Int,
	shadowMapSize:Int,
}

typedef TGameMaterial = {
	name:String,
	traits:Array<TGameTrait>,
}

typedef TGameTrait = {
	type:String,
	color:Array<Float>,
	texture:String,
	lighting:Bool,
	rim:Bool,
	cast_shadow:Bool,
	receive_shadow:Bool,
	shader:String,
	data:String,
	camera_type:String,
	light_type:String,
	body_shape:String,
	body_mass:Float,
	scene:String,
	class_name:String,
}

// TODO: rework into nodes
//typedef TGameNode = {
//	name:String,
//	value:Dynamic,
//}

class DaeParams {

	public var nodeObjectMap = new Map<DaeNode, Object>();
	public var transformControllerMap = new Map<Transform, DaeController>();
	public var materialMap = new Map<DaeMaterial, Material>();
	
	public var jointTransforms:Array<Transform> = [];
	public var jointNodes:Array<DaeNode> = [];
	public var skinnedRenderers:Array<SkinnedMeshRenderer> = [];

	public function new() { }
}

class DaeScene extends Trait {

	var daeData:DaeData;
	var gameData:TGameData;
	var daeParams:DaeParams;

	public function new(data:String) {

		super();

		daeData = new DaeData(data);
	}

	public function getNode(name:String):DaeNode {
		var node:DaeNode = null;

		daeData.scene.traverse(function(n:DaeNode) {
			if (n.name == name) {
				node = n;
				return;
			}
		});

		return node;
	}

	public inline function createNode(node:DaeNode):Object {
		return createCustomNode(node, owner, daeData, daeParams);
	}

	public function createCustomNode(node:DaeNode, owner:Object, daeData:DaeData, daeParams:DaeParams):Object {
		var parentObject = node.parent == null ? owner : (daeParams.nodeObjectMap.exists(node.parent) ? daeParams.nodeObjectMap.get(node.parent) : owner);
		var child = new Object();
		child.name = node.name;
		child.name = StringTools.replace(child.name, ".", "_");

		if (node.type == "joint") {
			child.transform.name = child.name;
			daeParams.jointTransforms.push(child.transform);
			daeParams.jointNodes.push(node);
		}

		child.transform.pos.set(node.position.x, node.position.y, node.position.z);
		child.transform.scale.set(node.scale.x, node.scale.y, node.scale.z);
		child.transform.rot.set(node.rotation.x, node.rotation.y, node.rotation.z, node.rotation.w);

		daeParams.nodeObjectMap.set(node, child);

		for (i in 0...node.instances.length) {
			var renderer:Renderer = null;
			var daeInst:DaeInstance = node.instances[i];
			var daeMat:DaeMaterial = null;				
			var daeGeom:DaeGeometry = null;
			var daeGeomTarget = "";
			var daeContr:DaeController = null;

			if (daeInst.type == "geometry") {
				daeGeomTarget = daeInst.target;
			}
			else if (daeInst.type == "controller") {
				daeContr = daeData.getControllerById(daeInst.target);						
				if (daeContr != null) {
					daeParams.transformControllerMap.set(child.transform, daeContr);
					daeGeomTarget = daeContr.source;
				}	
			}

			if (daeInst.type == "geometry" || daeInst.type == "controller") {
				var daeGeom = daeData.getGeometryById(daeGeomTarget);
				for (i in 0...daeGeom.mesh.primitives.length) {
					var daePrim = daeGeom.mesh.primitives[i];
					renderer = createRenderer(child, daePrim, daeContr, daeData);
					if (daeContr != null && renderer != null) daeParams.skinnedRenderers.push(cast renderer);
				}

				// Create object traits
				createTraits(child, node.instances[i].materials);
			}

			parentObject.addChild(child);
		}

		return child;
	}

	override function onItemAdd() {

		if (daeData.scene == null) return;

		// Scene renderer
		owner.addTrait(new SceneRenderer());
		owner.name = daeData.scene.name;

		// Game data reference
		gameData = Main.gameData;

		// Current session params
		daeParams = new DaeParams();

		createSceneInstance(daeData, daeParams, owner);
	}

	public function addScene(data:String):Object {
		var data = new DaeData(data);
		var o = new Object();
		createSceneInstance(data, new DaeParams(), o);
		owner.addChild(o);
		return o;
	}

	public function createSceneInstance(daeData:DaeData, daeParams:DaeParams, owner:Object) {

		// Create scene nodes
		daeData.scene.traverse(function(node:DaeNode) {
			if (node.name.charAt(0) == "_") { // TODO: use custom tag instead
				return; // Skip hidden objects
			}

			createCustomNode(node, owner, daeData, daeParams);
		});

		for (i in 0...daeParams.skinnedRenderers.length) {
			var skinnedRen = daeParams.skinnedRenderers[i];
			
			var daeContr = daeParams.transformControllerMap.exists(skinnedRen.transform) ? daeParams.transformControllerMap.get(skinnedRen.transform) : null;
			if (daeContr == null) continue;
			
			skinnedRen.joints = [];
			for (j in 0...daeContr.joints.length) {
				for (k in 0...daeParams.jointTransforms.length) {
					if (daeParams.jointTransforms[k].name == daeContr.joints[j]) {
						skinnedRen.joints.push(daeParams.jointTransforms[k]);		
					}
				}
			}
		}

		addAnimations(owner, daeParams.jointTransforms, daeData);
	}

	public function createTraits(obj:Object, mats:Array<String>) {
		for (i in 0...mats.length) {
			var mat = mats[i];

			// Find materials data
			var matData:TGameMaterial = null;
			for (i in 0...gameData.materials.length) {
				var str = StringTools.replace(mat, "_", ".");
				if (str == gameData.materials[i].name) {
					matData = gameData.materials[i];
				}
			}

			// Find traits
			var traitDatas:Array<TGameTrait> = [];
			if (matData != null) {
				for (i in 0...matData.traits.length) {
					if (matData.traits[i].type == "Trait") {
						traitDatas.push(matData.traits[i]);
					}
				}
			}

			// Find inputs
			var classNames:Array<String> = [];
			for (i in 0...traitDatas.length) {
				classNames.push(traitDatas[i].class_name);
			}

			for (className in classNames) {

				var s:Array<String> = className.split(":");
				var traitName = s[0];

				// Parse arguments
				var args:Dynamic = [];
				for (i in 1...s.length) {

					if (s[i] == "true") args.push(true);
					else if (s[i] == "false") args.push(false);
					else if (s[i].charAt(0) != "'") args.push(Std.parseFloat(s[i]));
					else {
						args.push(StringTools.replace(s[i], "'", ""));
					}
				}
				
				obj.addTrait(createClassInstance(traitName, args));
			}
		}
	}

	function createClassInstance(traitName:String, args:Dynamic):Dynamic {
		// Try game package
		var cname = Type.resolveClass(gameData.packageName + "." + traitName);

		// Try fox package
		if (cname == null) cname = Type.resolveClass("fox.trait." + traitName);
		
		return Type.createInstance(cname, args);
	}

	function createRenderer(object:Object, daePrim:DaePrimitive, daeContr:DaeController, daeData:DaeData):Renderer {

		if (daePrim.material == "") return null;
		var mat = daeData.getMaterialById(daePrim.material).name;

		// Find materials data
		var matData:TGameMaterial = null;
		for (i in 0...gameData.materials.length) {
			var str = StringTools.replace(mat, "_", ".");
			if (str == gameData.materials[i].name) {
				matData = gameData.materials[i];
			}
		}

		// Find traits
		var traitData:TGameTrait = null;
		if (matData != null) {
			for (i in 0...matData.traits.length) {

				var traitType = matData.traits[i].type;

				if (traitType == "Mesh Renderer" || traitType == "Custom Renderer") {
					traitData = matData.traits[i];
					break;
				}
			}
		}

		// Mesh renderer
		if (traitData != null && traitData.type == "Mesh Renderer") {
			var isSkinned = daeContr == null ? false : true;
			var va:Array<kha.math.Vector3> = daePrim.getTriangulatedArray("vertex");
			var na:Array<kha.math.Vector3> = daePrim.getTriangulatedArray("normal"); 
			var uva:Array<kha.math.Vector2> = daePrim.getTriangulatedArray("texcoord", 0);
			var ca:Array<kha.Color> = daePrim.getTriangulatedArray("color");
			var wa:Array<kha.math.Vector4> = null;
			var ba:Array<kha.math.Vector4> = null;

			if (isSkinned) {
				if (daeContr != null) {			
					daeContr.generateBonesAndWeights();
					
					wa = daeContr.getTriangulatedWeights(daePrim);
					ba = daeContr.getTriangulatedBones(daePrim);			
					//var bsm:kha.math.Matrix4 = daeContr.getBSM();
					
					//for (i in 0...va.length)  { va[i] = bsm.transform3x4(va[i].clone); }
					//for (i in 0...na.length)  { na[i] = bsm.transform3x3(na[i].clone); }
					//for (i in 0...mbn.length) { mbn[i] = bsm.transform3x3(mbn[i].clone); }
					//for (i in 0...mtg.length) { mtg[i] = bsm.transform3x3(mtg[i].clone); }
				}
			}

			var data:Array<Float> = [];
			var indices:Array<Int> = [];
			for (i in 0...va.length) {
				data.push(va[i].x); // Pos
				data.push(va[i].y);
				data.push(va[i].z);

				if (uva.length > 0) {
					data.push(uva[i].x); // TC
					data.push(uva[i].y);
				}
				else {
					data.push(0);
					data.push(0);
				}

				if (na.length > 0) {
					data.push(na[i].x); // Normal
					data.push(na[i].y);
					data.push(na[i].z);
				}
				else {
					data.push(1);
					data.push(1);
					data.push(1);
				}

				if (ca.length > 0) { // Color
					data.push(ca[i].R); // Vertex colors
					data.push(ca[i].G);
					data.push(ca[i].B);
					data.push(ca[i].A);
				}
				else {
					data.push(traitData.color[0]);	// Material color
					data.push(traitData.color[1]);
					data.push(traitData.color[2]);
					data.push(traitData.color[3]);
				}

				if (isSkinned) { // Bones and weights
					data.push(ba[i].x);
					data.push(ba[i].y);
					data.push(ba[i].z);
					data.push(ba[i].w);

					data.push(wa[i].x);
					data.push(wa[i].y);
					data.push(wa[i].z);
					data.push(wa[i].w);
				}

				indices.push(i);
			}

			var geo = new Geometry(data, indices, va, na);
			
			var tb = traitData.texture == "" ? false : true;
			var texturing = uva.length > 0 ? tb : false; // Make sure UVs are present
			var lighting = traitData.lighting;
			var rim = traitData.rim;
			var castShadow = traitData.cast_shadow;
			var receiveShadow = traitData.receive_shadow;

			var shaderName = "shader";
			if (isSkinned) shaderName = "skinnedshader";

			if (!texturing) {
				Assets.addMaterial(mat, new Material(Assets.getShader(shaderName)));
			}
			else {
				Assets.addMaterial(mat, new TextureMaterial(Assets.getShader(shaderName),
															Assets.getTexture(traitData.texture)));
			}

			var mesh:Mesh = null;
			if (isSkinned) {
				mesh = new SkinnedMesh(geo, Assets.getMaterial(mat));

				if (daeContr != null) {			
					var skinnedMesh:SkinnedMesh = cast mesh;			
					skinnedMesh.weight = daeContr.getTriangulatedWeights(daePrim);
					skinnedMesh.bone = daeContr.getTriangulatedBones(daePrim);
					skinnedMesh.binds = daeContr.getBinds();
				}
			}
			else {
				mesh = new Mesh(geo, Assets.getMaterial(mat));
			}

			var renderer:MeshRenderer = null;
			if (isSkinned) renderer = new SkinnedMeshRenderer(cast mesh);
			else renderer = new MeshRenderer(mesh);
			renderer.texturing = texturing;
			renderer.lighting = lighting;
			renderer.rim = rim;
			renderer.castShadow = castShadow;
			renderer.receiveShadow = receiveShadow;
			renderer.setMat4(renderer.mvpMatrix);
			renderer.setMat4(renderer.shadowMapMatrix);
			renderer.setMat4(renderer.viewMatrix);
			if (isSkinned) {
				var skinnedRenderer:SkinnedMeshRenderer = cast renderer;
				skinnedRenderer.setMat4(skinnedRenderer.projectionMatrix);
			}
			renderer.setBool(texturing);
			renderer.setBool(lighting);
			renderer.setBool(rim);
			renderer.setBool(castShadow);
			renderer.setBool(receiveShadow);
			renderer.setTexture(fox.core.FrameRenderer.shadowMap);
			object.addTrait(renderer);
			return renderer;
		}
		// Custom material TODO: merge
		else if (traitData != null) {
			var va:Array<kha.math.Vector3> = daePrim.getTriangulatedArray("vertex");
			var na:Array<kha.math.Vector3> = daePrim.getTriangulatedArray("normal"); 
			var uva:Array<kha.math.Vector2> = daePrim.getTriangulatedArray("texcoord", 0);
			var ca:Array<kha.Color> = daePrim.getTriangulatedArray("color");

			var data:Array<Float> = [];
			var indices:Array<Int> = [];
			
			for (i in 0...va.length) {
				data.push(va[i].x); // Pos
				data.push(va[i].y);
				data.push(va[i].z);

				if (uva.length > 0) {
					data.push(uva[i].x); // TC
					data.push(uva[i].y);
				}
				else {
					data.push(0);
					data.push(0);
				}

				if (na.length > 0) {
					data.push(na[i].x); // Normal
					data.push(na[i].y);
					data.push(na[i].z);
				}
				else {
					data.push(1);
					data.push(1);
					data.push(1);
				}

				if (ca.length > 0) { // Color
					data.push(ca[i].R); // Vertex colors
					data.push(ca[i].G);
					data.push(ca[i].B);
					data.push(ca[i].A);
				}
				else {
					data.push(traitData.color[0]);	// Material color
					data.push(traitData.color[1]);
					data.push(traitData.color[2]);
					data.push(traitData.color[3]);
				}

				indices.push(i);
			}

			var geo = new Geometry(data, indices, va, na);
			
			var shaderName = traitData.shader;
			var rendererName = traitData.class_name;
			var tb = traitData.texture == "" ? false : true;
			var texturing = uva.length > 0 ? tb : false; // Make sure UVs are present

			if (!texturing) {
				Assets.addMaterial(mat, new Material(Assets.getShader(shaderName)));
			}
			else {
				Assets.addMaterial(mat, new TextureMaterial(Assets.getShader(shaderName),
															Assets.getTexture(traitData.texture)));
			}

			var mesh:Mesh = null;
			mesh = new Mesh(geo, Assets.getMaterial(mat));

			var renderer:Dynamic = createClassInstance(rendererName, [mesh]);
			renderer.texturing = texturing;
			renderer.initConstants();
			object.addTrait(renderer);
			return renderer;
		}

		return null;
	}

	public function addAnimations(root:Object, jointTransforms:Array<Transform>, daeData:DaeData) {

		if (daeData.animations.length <= 0) return;

		//var anim = root.getTrait(Animation);
		//if (anim == null) {
			var anim = new Animation();
			root.addTrait(anim);
		//}
		
		for (i in 0...daeData.animations.length) {

			var daeAnim = daeData.animations[i];
			var clip = new AnimationClip();
			clip.name = daeAnim.name;	
			
			for (j in 0...daeAnim.channels.length) {

				var channel = daeAnim.channels[j];
				var nodeName = channel.target.split("/")[0];
				nodeName = StringTools.replace(nodeName, "node-", "");
				var targetName = channel.target.split("/")[1];

				var transform:Transform = null;
				for (i in 0...jointTransforms.length) {
					if (jointTransforms[i].name == nodeName) {
						transform = jointTransforms[i];
						break;
					}
				}
				if (transform == null) continue;

				if (targetName == "matrix") {
					var positionTrack = clip.add(transform, "pos");							
					var rotationTrack = clip.add(transform, "rot");

					for (k in 0...channel.keyframes.length) {
						var keyframe = channel.keyframes[k];
						var mat = new fox.math.Mat4(keyframe.values);// fox.math.Mat4.FromArray();
						var trans = mat.getTransform();
						positionTrack.add(keyframe.time, trans[0]);
						rotationTrack.add(keyframe.time, trans[1]);
					}		
				}
			}
			
			anim.add(clip);				
		}
	}
}
