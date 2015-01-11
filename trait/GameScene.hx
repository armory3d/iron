package fox.trait;

import fox.math.Mat4;
import fox.core.Object;
import fox.core.Trait;
import fox.sys.importer.OgexData;
import fox.sys.material.Material;
import fox.sys.material.TextureMaterial;
import fox.sys.mesh.SkinnedMesh;
import fox.sys.Assets;
import fox.sys.mesh.Geometry;
import fox.sys.mesh.Mesh;
import fox.trait.Transform;

typedef TGameData = {
	collections:Array<TGameCollection>,
	objects:Array<TGameObject>,
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

typedef TGameCollection = {
	name:String,
	traits:Array<TGameTrait>,
}

typedef TGameObject = {
	name:String,
	collections:Array<String>,
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

class GameParams {

	public var nodeObjectMap = new Map<Node, Object>();

	public function new() { }
}

class GameScene extends Trait {

	var ogexData:OgexData;
	var gameData:TGameData;
	var gameParams:GameParams;
	var traitInits:Array<Void->Void> = []; // TODO: scene nesting

	@inject({desc:true,sibl:true})
	public var camera:Camera;

	public var light:Light;

	public function new(data:String) {
		super();

		ogexData = new OgexData(data);
	}

	public function registerInit(cb:Void->Void) {
		traitInits.push(cb);
	}

	public inline function getNode(name:String):Node {
		return ogexData.getNode(name);
	}

	public inline function createNode(node:Node):Object {
		return createCustomNode(node, owner, ogexData, gameParams);
	}

	override function onItemAdd() {

		// Physics
		owner.addTrait(new PhysicsScene());

		// Game data reference
		gameData = Main.gameData;

		// Current session params
		gameParams = new GameParams();

		createSceneInstance(ogexData, gameParams, owner);

		// TODO: scene instancing
		for (cb in traitInits) {
			cb();
		}
		traitInits = [];
	}

	@injectAdd({desc:true,sibl:true})
	function addLight(trait:Light) {
		light = trait;

		// TODO: inject into camera
		if (camera != null) camera.registerLight(light);
	}

	public function addScene(data:String):Object {
		var ogexData = new OgexData(data);
		var o = new Object();
		createSceneInstance(ogexData, new GameParams(), o);
		owner.addChild(o);
		return o;
	}

	public function createSceneInstance(ogexData:OgexData, gameParams:GameParams, owner:Object) {
		// Create scene nodes
		ogexData.traverseNodes(function(node:Node) {
			if (node.name.charAt(0) == "_") { // TODO: use custom tag instead
				return; // Skip hidden objects
			}
			createCustomNode(node, owner, ogexData, gameParams);
		});
	}

	public function createCustomNode(node:Node, owner:Object, ogexData:OgexData, gameParams:GameParams):Object {
		var parentObject = node.parent == null ? owner : (gameParams.nodeObjectMap.exists(cast node.parent) ? gameParams.nodeObjectMap.get(cast node.parent) : owner);
		var child = new Object();
		child.name = node.name;
		child.name = StringTools.replace(child.name, ".", "_");

		generateTranform(node, child.transform);

		gameParams.nodeObjectMap.set(node, child);

		// Find collections
		var colls:Array<String> = [];
		for (o in gameData.objects) {
			if (o.name == node.name) {
				colls = o.collections;
				break;
			}
		}

		// Renderer for geometry nodes
		if (Std.is(node, GeometryNode)) {

			var go = cast(node, GeometryNode);
			var geoObj = ogexData.getGeometryObject(go.objectRefs[0]);

			if (geoObj != null) {
				var renderer = createRenderer(child, geoObj, ogexData, go, colls);

				// Get mesh size if renderer is not present
				if (renderer == null) {
					var pa = geoObj.mesh.getArray("position").values;
					calcSize(pa, child.transform);
				}
			}
		}

		// Create object traits
		createTraits(child, colls);

		//for (ref in go.materialRefs) {
		//	mats.push(ogexData.getMaterial(ref).name);
		//}

		parentObject.addChild(child);

		return child;
	}

	function generateTranform(node:Node, transform:Transform) {
		var mat = new Mat4(node.transform.values);
		transform.pos.x = mat._14;
		transform.pos.y = mat._24;
		transform.pos.z = mat._34;
		var rotation = mat.getQuat();
		transform.rot.set(rotation.x, rotation.y, rotation.z, rotation.w);
		var ms = mat.getScale();
		transform.scale.x = ms._11;
		transform.scale.y = ms._22;
		transform.scale.z = ms._33;
	}

	public function createTraits(obj:Object, colls:Array<String>) {
		for (i in 0...colls.length) {
			var coll = colls[i];

			// Find collection data
			var collData:TGameCollection = null;
			var str = StringTools.replace(coll, "_", ".");
			for (i in 0...gameData.collections.length) {
				if (str == gameData.collections[i].name) {
					collData = gameData.collections[i];
				}
			}

			// Find traits
			var traitDatas:Array<TGameTrait> = [];
			if (collData != null) {
				for (i in 0...collData.traits.length) {
					if (collData.traits[i].type == "Trait") {
						traitDatas.push(collData.traits[i]);
					}
				}
			}

			// Create classes
			for (t in traitDatas) {
				var s:Array<String> = t.class_name.split(":");
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

	// TODO: call from createTraits
	function createRenderer(object:Object, geoObj:GeometryObject, ogexData:OgexData, geoNode:GeometryNode, colls:Array<String>):Renderer {

		if (geoNode.materialRefs.length == 0) return null;
		var mat = ogexData.getMaterial(geoNode.materialRefs[0]).name;

		// TODO: check all collections
		var coll = colls[0];

		// Find collection data
		var collData:TGameCollection = null;
		var str = StringTools.replace(coll, "_", ".");
		for (i in 0...gameData.collections.length) {
			if (str == gameData.collections[i].name) {
				collData = gameData.collections[i];
			}
		}

		// Find traits
		var traitData:TGameTrait = null;
		if (collData != null) {
			for (i in 0...collData.traits.length) {

				var traitType = collData.traits[i].type;

				if (traitType == "Mesh Renderer" || traitType == "Custom Renderer") {
					traitData = collData.traits[i];
					break;
				}
			}
		}

		// No rendrer trait present
		if (traitData == null) return null;
	
		// Mesh data
		var data:Array<Float> = [];
		var indices:Array<Int> = geoObj.mesh.indexArray.values;

		var paVA = geoObj.mesh.getArray("position");
		var pa = paVA != null ? paVA.values : null;
		
		var naVA = geoObj.mesh.getArray("normal");
		var na = naVA != null ? naVA.values : null; 
		
		var uvaVA = geoObj.mesh.getArray("texcoord");
		var uva = uvaVA != null ? uvaVA.values : null;

		var isSkinned = false;
		buildData(traitData, data, pa, na, uva, geoObj, isSkinned);

		var geo = new Geometry(data, indices, pa, na);

		var tb = traitData.texture == "" ? false : true;
		var texturing = uva != null ? tb : false; // Make sure UVs are present

		// Mesh renderer
		if (traitData.type == "Mesh Renderer") {
			
			var lighting = traitData.lighting;
			var rim = traitData.rim;
			var castShadow = gameData.shadowMapping == 1 ? traitData.cast_shadow : false;
			var receiveShadow = gameData.shadowMapping == 1 ? traitData.receive_shadow : false;

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

				//if (daeContr != null) {			
				//	var skinnedMesh:SkinnedMesh = cast mesh;			
				//	skinnedMesh.weight = daeContr.getTriangulatedWeights(daePrim);
				//	skinnedMesh.bone = daeContr.getTriangulatedBones(daePrim);
				//	skinnedMesh.binds = daeContr.getBinds();
				//}
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
			renderer.initConstants();
			object.addTrait(renderer);
			return renderer;
		}
		// Custom material
		else {
			var shaderName = traitData.shader;
			var rendererName = traitData.class_name;

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
	}

	function buildData(traitData:TGameTrait,
					   data:Array<Float>,
					   pa:Array<Float>, na:Array<Float>, uva:Array<Float>,
					   geoObj:GeometryObject, isSkinned:Bool) {

		var caVA = geoObj.mesh.getArray("color");
		var ca:Array<Float> = caVA != null ? caVA.values : null;
		var ba:Array<Float> = [];
		var wa:Array<Float> = [];

		for (i in 0...Std.int(pa.length / 3)) {
			data.push(pa[i * 3]); // Pos
			data.push(pa[i * 3 + 1]);
			data.push(pa[i * 3 + 2]);

			if (uva != null) {
				data.push(uva[i * 2]); // TC
				data.push(1 - uva[i * 2 + 1]);
			}
			else {
				data.push(0);
				data.push(0);
			}

			if (na != null) {
				data.push(na[i * 3]); // Normal
				data.push(na[i * 3 + 1]);
				data.push(na[i * 3 + 2]);
			}
			else {
				data.push(1);
				data.push(1);
				data.push(1);
			}

			if (ca != null) { // Color
				data.push(ca[i * 3]); // Vertex colors
				data.push(ca[i * 3 + 1]);
				data.push(ca[i * 3 + 2]);
				data.push(1.0);
			}
			else {
				data.push(traitData.color[0]);	// Material color
				data.push(traitData.color[1]);
				data.push(traitData.color[2]);
				data.push(traitData.color[3]);
			}

			if (isSkinned) { // Bones and weights
				data.push(ba[i * 4]);
				data.push(ba[i * 4 + 1]);
				data.push(ba[i * 4 + 2]);
				data.push(ba[i * 4 + 3]);

				data.push(wa[i * 4]);
				data.push(wa[i * 4 + 1]);
				data.push(wa[i * 4 + 2]);
				data.push(wa[i * 4 + 3]);
			}
		}
	}

	function calcSize(pa:Array<Float>, transform:Transform) {
		// Gets mesh size when mesh renderer is not present
		var aabbMin = new fox.math.Vec3(-0.1, -0.1, -0.1);
		var aabbMax = new fox.math.Vec3(0.1, 0.1, 0.1);

		var i:Int = 0;
		while (i < Std.int(pa.length / 3)) {

			if (pa[i * 3] > aabbMax.x) aabbMax.x = pa[i * 3];
			if (pa[i * 3 + 1] > aabbMax.y) aabbMax.y = pa[i * 3 + 1];
			if (pa[i * 3 + 2] > aabbMax.z) aabbMax.z = pa[i * 3 + 2];

			if (pa[i * 3] < aabbMin.x) aabbMin.x = pa[i * 3];
			if (pa[i * 3 + 1] < aabbMin.y) aabbMin.y = pa[i * 3 + 1];
			if (pa[i * 3 + 2] < aabbMin.z) aabbMin.z = pa[i * 3 + 2];

			i++;
		}

		// TODO: dont store scale in size
		transform.size.x = (Math.abs(aabbMin.x) + Math.abs(aabbMax.x)) * transform.scale.x;
		transform.size.y = (Math.abs(aabbMin.y) + Math.abs(aabbMax.y)) * transform.scale.y;
		transform.size.z = (Math.abs(aabbMin.z) + Math.abs(aabbMax.z)) * transform.scale.z;
	}
}
