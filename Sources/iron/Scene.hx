package iron;

import haxe.ds.Vector;
import iron.Trait;
import iron.object.*;
import iron.data.*;
import iron.data.SceneFormat;

class Scene {

	public static var active:Scene = null;
	public static var global:Object = null;
	static var uidCounter = 0;
	public var uid:Int;
	public var raw:TSceneFormat;
	public var root:Object;
	public var sceneParent:Object;
	public var camera:CameraObject;
	public var world:WorldData;
	// public var greasePencil:GreasePencilData = null;

	public var meshBatch:MeshBatch = null;
	public var sceneStream:SceneStream = null;
	public var meshes:Array<MeshObject>;
	public var lamps:Array<LampObject>;
	public var cameras:Array<CameraObject>;
	public var speakers:Array<SpeakerObject>;
	public var decals:Array<DecalObject>;
	public var empties:Array<Object>;
	public var animations:Array<Animation>;
	public var armatures:Array<Armature>;
	public var groups:Map<String, Array<Object>> = null;

	public var embedded:Map<String, kha.Image>;

	public var ready:Bool; // Async in progress

	public var traitInits:Array<Void->Void> = [];
	public var traitRemoves:Array<Void->Void> = [];

	public function new() {
		uid = uidCounter++;
		#if arm_batch
		meshBatch = new MeshBatch();
		#end
		#if arm_stream
		sceneStream = new SceneStream();
		#end
		meshes = [];
		lamps = [];
		cameras = [];
		speakers = [];
		decals = [];
		empties = [];
		animations = [];
		armatures = [];
		embedded = new Map();
		root = new Object();
		root.name = "Root";
		traitInits = [];
		traitRemoves = [];
		if (global == null) global = new Object();
	}

	public static function create(format:TSceneFormat, done:Object->Void) {
		active = new Scene();
		active.ready = false;
		active.raw = format;

		Data.getWorld(format.name, format.world_ref, function(world:WorldData) {
			active.world = world;

			// Startup scene
			active.addScene(format.name, null, function(sceneObject:Object) {

				if (active.cameras.length == 0) {
					trace('No camera found for scene "' + format.name + '"');
				}

				active.camera = active.getCamera(format.camera_ref);
				active.ready = true;

				for (f in active.traitInits) f();
				active.traitInits = [];

				active.sceneParent = sceneObject;
				done(sceneObject);
			});
		});
	}

	public function remove() {
		for (f in traitRemoves) f();
		if (meshBatch != null) meshBatch.remove();
		for (o in meshes) o.remove();
		for (o in lamps) o.remove();
		for (o in cameras) o.remove();
		for (o in speakers) o.remove();
		for (o in decals) o.remove();
		for (o in empties) o.remove();
		groups = null;
		root.remove();
	}

	static var framePassed = true;
	public static function setActive(sceneName:String, done:Object->Void = null) {
		if (!framePassed) return;
		framePassed = false;
		if (Scene.active != null) Scene.active.remove();
		iron.data.Data.getSceneRaw(sceneName, function(format:TSceneFormat) {
			Scene.create(format, function(o:Object) {
				if (done != null) done(o);
			});
		});
	}

	public function updateFrame() {
		if (!ready) return;
		#if arm_stream
		sceneStream.update(active.camera);
		#end
		for (anim in animations) anim.update(iron.system.Time.delta);
		for (e in empties) if (e != null && e.parent != null) e.transform.update();
	}

	public function renderFrame(g:kha.graphics4.Graphics) {
		if (!ready || RenderPath.active == null) return;
		framePassed = true;

		var activeCamera = camera;
		// Render probes
		for (cam in cameras) {
			if (cam.data.renderTarget != null) {

				// Reflection probe
				// var mo = cast(iron.Scene.active.getChild("CameraPlane"), MeshObject);
				// var nors = mo.data.geom.normals;
				// var nor = new iron.math.Vec4(nors[0], nors[1], nors[2]);
				// // nor.applyproj(mo.transform.world);
				// var a = mo.transform.world.getLoc();
				// var plane = new iron.math.Ray.Plane();
				// plane.set(nor, a);
				// var start = activeCamera.transform.world.getLoc();
				// nor.mult(-1);
				// var end = nor;
				// var ray = new iron.math.Ray(start, end);
				// var hit = ray.intersectPlane(plane);
				// if (hit != null) {
				// 	cam.transform.loc.setFrom(hit);
				// 	nor.mult(-1);
				// 	cam.transform.rot = hit.reflect(nor);
				// }

				camera = cam;
				camera.renderFrame(g);
			}
		}
		// Render active camera
		camera = activeCamera;
		camera != null ? camera.renderFrame(g) : RenderPath.active.renderFrame(g);
	}

	// Objects
	public function addObject(parent:Object = null):Object {
		var object = new Object();
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	public function getChild(name:String):Object {
		return root.getChild(name);
	}

	public function getTrait(c:Class<Trait>):Dynamic {
		return root.children.length > 0 ? root.children[0].getTrait(c) : null;
	}

	public function getMesh(name:String):MeshObject {
		for (m in meshes) if (m.name == name) return m;
		return null;
	}

	public function getLamp(name:String):LampObject {
		for (l in lamps) if (l.name == name) return l;
		return null;
	}

	public function getCamera(name:String):CameraObject {
		for (c in cameras) if (c.name == name) return c;
		return null;
	}

	public function getSpeaker(name:String):SpeakerObject {
		for (s in speakers) if (s.name == name) return s;
		return null;
	}

	public function getEmpty(name:String):Object {
		for (e in empties) if (e.name == name) return e;
		return null;
	}

	public function addMeshObject(data:MeshData, materials:Vector<MaterialData>, parent:Object = null):MeshObject {
		var object = new MeshObject(data, materials);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	public function addLampObject(data:LampData, parent:Object = null):LampObject {
		var object = new LampObject(data);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	public function addCameraObject(data:CameraData, parent:Object = null):CameraObject {
		var object = new CameraObject(data);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	public function addSpeakerObject(data:TSpeakerData, parent:Object = null):SpeakerObject {
		var object = new SpeakerObject(data);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}
	
	public function addDecalObject(material:MaterialData, parent:Object = null):DecalObject {
		var object = new DecalObject(material);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	#if arm_stream
	var objectsTraversed = 0;
	#end
	public function addScene(sceneName:String, parent:Object, done:Object->Void) {
		if (parent == null) {
			parent = addObject();
			parent.name = sceneName;
		}
		Data.getSceneRaw(sceneName, function(format:TSceneFormat) {
			createTraits(format.traits, parent); // Scene traits
			loadEmbeddedData(format.embedded_datas, function() { // Additional scene assets

				// if (format.grease_pencil_ref != null) {
				// 	var ref = format.grease_pencil_ref.split('/');
				// 	var object_file = '';
				// 	var data_ref = '';
				// 	if (ref.length == 2) { // File reference
				// 		object_file = ref[0];
				// 		data_ref = ref[1];
				// 	}
				// 	else { // Local GP data
				// 		object_file = sceneName;
				// 		data_ref = format.grease_pencil_ref;
				// 	}
				// 	Data.getGreasePencil(object_file, data_ref, function(gp:GreasePencilData) {
				// 		greasePencil = gp;
				// 	});
				// }

				#if arm_stream
				objectsTraversed = 0;
				#else
				var objectsTraversed = 0;
				#end
				var objectsCount = getObjectsCount(format.objects);
				function traverseObjects(parent:Object, objects:Array<TObj>, parentObject:TObj, done:Void->Void) {
					if (objects == null) return;
					for (i in 0...objects.length) {
						var o = objects[i];
						if (o.spawn != null && o.spawn == false) {
							if (++objectsTraversed == objectsCount) done();
							continue; // Do not auto-create this object
						}
						
						createObject(o, format, parent, parentObject, function(object:Object) {
							if (object != null) traverseObjects(object, o.children, o, done);
							if (++objectsTraversed == objectsCount) done();
						});
					}
				}

				if (format.objects == null || format.objects.length == 0) {
					done(parent);
				}
				else {
					traverseObjects(parent, format.objects, null, function() { // Scene objects
						done(parent);
					});
				}
			});
		});
	}

	function getObjectsCount(objects:Array<TObj>, discardNoSpawn = true):Int {
		if (objects == null) return 0;
		var result = objects.length;
		for (o in objects) {
			if (discardNoSpawn && o.spawn != null && o.spawn == false) continue; // Do not count children of non-spawned objects
			if (o.children != null) result += getObjectsCount(o.children);
		}
		return result;
	}
	
	public function spawnObject(name:String, parent:Object, done:Object->Void, spawnChildren = true) {
		var objectsTraversed = 0;
		var obj = getObj(raw, name);
		var objectsCount = spawnChildren ? getObjectsCount([obj], false) : 1;
		function spawnObjectTree(obj:TObj, parent:Object, done:Object->Void) {
			createObject(obj, raw, parent, null, function(object:Object) {
				if (spawnChildren && obj.children != null) {
					for (child in obj.children) spawnObjectTree(child, object, done);
				}
				if (++objectsTraversed == objectsCount && done != null) done(object);
			});
		}
		spawnObjectTree(obj, parent, done);
	}

	public function parseObject(sceneName:String, objectName:String, parent:Object, done:Object->Void) {
		Data.getSceneRaw(sceneName, function(format:TSceneFormat) {
			var o:TObj = getObj(format, objectName);
			if (o == null) done(null);
			createObject(o, format, parent, null, done);
		});
	}

	function getObj(format:TSceneFormat, name:String):TObj {
		return traverseObjs(format.objects, name);
	}

	function traverseObjs(children:Array<TObj>, name:String):TObj {
		for (o in children) {
			if (o.name == name) return o;
			if (o.children != null) {
				var res = traverseObjs(o.children, name);
				if (res != null) return res;
			}
		}
		return null;
	}
	
	public function createObject(o:TObj, format:TSceneFormat, parent:Object, parentObject:TObj, done:Object->Void) {

		var sceneName = format.name;
		if (o.type == "camera_object") {
			Data.getCamera(sceneName, o.data_ref, function(b:CameraData) {
				var object = addCameraObject(b, parent);
				returnObject(object, o, done);
			});
		}
		else if (o.type == "lamp_object") {
			Data.getLamp(sceneName, o.data_ref, function(b:LampData) {
				var object = addLampObject(b, parent);	
				returnObject(object, o, done);
			});
		}
		else if (o.type == "mesh_object") {
			if (o.material_refs == null || o.material_refs.length == 0) {
				// No material, create empty object
				var object = addObject(parent);
				returnObject(object, o, done);
			}
			else {
				// Materials
				var materials = new Vector<MaterialData>(o.material_refs.length);
				var materialsLoaded = 0;

				for (i in 0...o.material_refs.length) {
					var ref = o.material_refs[i];
					Data.getMaterial(sceneName, ref, function(mat:MaterialData) {
						materials[i] = mat;
						materialsLoaded++;

						if (materialsLoaded == o.material_refs.length) {

							// Mesh reference
							var ref = o.data_ref.split('/');
							var object_file = '';
							var data_ref = '';
							if (ref.length == 2) { // File reference
								object_file = ref[0];
								data_ref = ref[1];
							}
							else { // Local mesh data
								object_file = sceneName;
								data_ref = o.data_ref;
							}

							// Bone objects are stored in armature parent
							if (parentObject != null && parentObject.bone_actions != null) {
								var bactions:Array<TSceneFormat> = [];
								for (ref in parentObject.bone_actions) {
									Data.getSceneRaw(ref, function(action:TSceneFormat) {
										bactions.push(action);
										if (bactions.length == parentObject.bone_actions.length) {
											var armature = new Armature(parentObject.name, bactions);
											armatures.push(armature);
											#if arm_stream
											streamMeshObject(
											#else
											returnMeshObject(
											#end
												object_file, data_ref, sceneName, armature, materials, parent, o, done);
										}
									});
								}
							}
							else {
								#if arm_stream
								streamMeshObject(
								#else
								returnMeshObject(
								#end
									object_file, data_ref, sceneName, null, materials, parent, o, done);
							}
						}
					});
				}
			}
		}
		else if (o.type == "speaker_object") {
			var object = addSpeakerObject(Data.getSpeakerRawByName(format.speaker_datas, o.data_ref), parent);	
			returnObject(object, o, done);
		}
		else if (o.type == "decal_object") {
			if (o.material_refs != null && o.material_refs.length > 0) {
				Data.getMaterial(sceneName, o.material_refs[0], function(material:MaterialData) {
					var object = addDecalObject(material, parent);	
					returnObject(object, o, done);
				});
			}
			else {
				var object = addDecalObject(null, parent);	
				returnObject(object, o, done);
			}
		}
		else if (o.type == "object") {
			var object = addObject(parent);
			returnObject(object, o, function(ro:Object){
				if (o.group_ref != null) { // Instantiate group objects
					var spawned = 0;
					var object_refs = getGroupObjectRefs(o.group_ref);
					if (object_refs.length == 0) done(ro);
					else {
						for (s in object_refs) {
							spawnObject(s, ro, function(so:Object) {
								if (++spawned == object_refs.length) done(ro);
							});
						}
					}
				}
				else done(ro);
			});
		}
		else done(null);
	}

	function getGroupObjectRefs(group_ref:String):Array<String> {
		for (g in raw.groups) if (g.name == group_ref) return g.object_refs;
		return null;
	}

#if arm_stream
	function childCount(o:TObj):Int {
		var i = o.children.length;
		if (o.children != null) for (c in o.children) i += childCount(c);
		return i;
	}

	function streamMeshObject(object_file:String, data_ref:String, sceneName:String, armature:Armature, materials:Vector<MaterialData>, parent:Object, o:TObj, done:Object->Void) {
		sceneStream.add(object_file, data_ref, sceneName, armature, materials, parent, o);
		// TODO: Increase objectsTraversed by full children count
		if (o.children != null) objectsTraversed += o.children.length;
		// Return immediately and stream progressively
		returnObject(null, null, done);
	}
#end

	public function returnMeshObject(object_file:String, data_ref:String, sceneName:String, armature:Armature, materials:Vector<MaterialData>, parent:Object, o:TObj, done:Object->Void) {
		Data.getMesh(object_file, data_ref, function(mesh:MeshData) {
			if (mesh.isSkinned) {
				var g = mesh.geom;
				armature != null ? g.addArmature(armature) : g.addAction(mesh.format.objects, 'none');
			}
			var object = addMeshObject(mesh, materials, parent);
		
			// Attach particle systems
			if (o.particle_refs != null) {
				for (ref in o.particle_refs) cast(object, MeshObject).setupParticleSystem(sceneName, ref);
			}
			// Attach tilesheet
			if (o.tilesheet_ref != null) {
				cast(object, MeshObject).setupTilesheet(sceneName, o.tilesheet_ref, o.tilesheet_action_ref);
			}
			returnObject(object, o, done);
		});
	}

	function returnObject(object:Object, o:TObj, done:Object->Void) {
		// Load object actions
		if (object != null && o.object_actions != null) {
			var oactions:Array<TSceneFormat> = [];
			while (oactions.length < o.object_actions.length) oactions.push(null);
			var actionsLoaded = 0;
			for (i in 0...o.object_actions.length) {
				var ref = o.object_actions[i];
				if (ref == "null") { actionsLoaded++; continue; } // No startup action set
				Data.getSceneRaw(ref, function(action:TSceneFormat) {
					oactions[i] = action;
					actionsLoaded++;
					if (actionsLoaded == o.object_actions.length) {
						returnObjectLoaded(object, o, oactions, done);
					}
				});
			}
		}
		else returnObjectLoaded(object, o, null, done);
	}

	function returnObjectLoaded(object:Object, o:TObj, oactions:Array<TSceneFormat>, done:Object->Void) {
		if (object != null) {
			object.raw = o;
			object.name = o.name;
			if (o.visible != null) object.visible = o.visible;
			if (o.visible_mesh != null) object.visibleMesh = o.visible_mesh;
			if (o.visible_shadow != null) object.visibleShadow = o.visible_shadow;
			createConstraints(o.constraints, object);
			generateTransform(o, object.transform);
			object.setupAnimation(oactions);
			if (o.groups != null) {
				if (groups == null) groups = new Map();
				for (gname in o.groups) {
					var g = groups.get(gname);
					if (g == null) { g = []; groups.set(gname, g); }
					g.push(object);
				}
			}
			createTraits(o.traits, object);
		}
		done(object);
	}

	static function generateTransform(object:TObj, transform:Transform) {
		transform.world = object.transform != null ? iron.math.Mat4.fromFloat32Array(object.transform.values) : iron.math.Mat4.identity();
		transform.world.decompose(transform.loc, transform.rot, transform.scale);
		// Whether to apply parent matrix
		if (object.local_transform_only != null) transform.localOnly = object.local_transform_only;
		if (transform.object.parent != null) transform.update();
	}

	static function createTraits(traits:Array<TTrait>, object:Object) {
		if (traits == null) return;
		for (t in traits) {
			if (t.type == "Script") {
				// Assign arguments if any
				var args:Array<Dynamic> = [];
				if (t.parameters != null) {
					for (param in t.parameters) {
						args.push(parseArg(param));
					}
				}
				var traitInst = createTraitClassInstance(t.class_name, args);
				if (traitInst == null) {
					trace("Error: Trait '" + t.class_name + "' referenced in object '" + object.name + "' not found");
					continue;
				}
				if (t.props != null) {
					for (i in 0...Std.int(t.props.length / 2)) {
						var pname = t.props[i * 2];
						var pval = t.props[i * 2 + 1];
						if (pval != "" && Reflect.field(traitInst, pname) != null) { // c/cpp no field?
							Reflect.setProperty(traitInst, pname, parseArg(pval));
						}
					}
				}
				object.addTrait(traitInst);
			}
		}
	}

 	static function parseArg(str:String):Dynamic {
		if (str == "true") return true;
		else if (str == "false") return false;
		else if (str == "null") return null;
		else if (str.charAt(0) == "'") return StringTools.replace(str, "'", "");
		else if (str.charAt(0) == '"') return StringTools.replace(str, '"', "");
		else if (str.charAt(0) == "[") { // Array
			// Remove [] and recursively parse into array,
			// then append into parent
			str = StringTools.replace(str, "[", "");
			str = StringTools.replace(str, "]", "");
			str = StringTools.replace(str, " ", "");
			var ar:Dynamic = [];
			var s = str.split(",");
			for (childStr in s) {
				ar.push(parseArg(childStr));
			}
			return ar;
		}
		else {
			var f = Std.parseFloat(str);
			var i = Std.parseInt(str);
			return f == i ? i : f;
		}
	}

	static function createConstraints(constraints:Array<TConstraint>, object:Object) {
		if (constraints == null) return;
		object.constraints = [];
		for (c in constraints) {
			var constr = new Constraint(c);
			object.constraints.push(constr);
		}
	}

	static function createTraitClassInstance(traitName:String, args:Array<Dynamic>):Dynamic {
		var cname = Type.resolveClass(traitName);
		if (cname == null) return null;
		return Type.createInstance(cname, args);
	}

	function loadEmbeddedData(datas:Array<String>, done:Void->Void) {
		if (datas == null) { done(); return; }
		var loaded = 0;
		for (file in datas) {
			iron.data.Data.getImage(file, function(image:kha.Image) {
				embedded.set(file, image);
				loaded++;
				if (loaded == datas.length) done();
			});
		}
	}

	// Hooks
	public function notifyOnInit(f:Void->Void) {
		if (ready) f(); // Scene already running
		else traitInits.push(f);
	}

	public function removeInit(f:Void->Void) {
		traitInits.remove(f);
	}

	public function notifyOnRemove(f:Void->Void) {
		traitRemoves.push(f);
	}

	public function toString():String {
		return "Scene " + raw.name;
	}
}
