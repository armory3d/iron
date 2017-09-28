package iron;

import haxe.ds.Vector;
import iron.Trait;
import iron.object.Constraint;
import iron.object.Transform;
import iron.object.Object;
import iron.data.MeshBatch;
import iron.data.SceneStream;
import iron.object.MeshObject;
import iron.object.LampObject;
import iron.object.CameraObject;
import iron.object.SpeakerObject;
import iron.object.DecalObject;
import iron.object.Animation;
import iron.data.SceneFormat;
import iron.data.Data;
import iron.data.MeshData;
import iron.data.LampData;
import iron.data.CameraData;
import iron.data.MaterialData;
import iron.data.ShaderData;
import iron.data.WorldData;
import iron.data.GreasePencilData;
import iron.math.Mat4;

class Scene {

	public static var active:Scene = null;
	
	public var raw:TSceneFormat;
	public var root:Object;
	public var camera:CameraObject;
	public var world:WorldData;
	public var greasePencil:GreasePencilData = null;

	public var meshBatch:MeshBatch = null;
	public var sceneStream:SceneStream = null;
	public var meshes:Array<MeshObject>;
	public var lamps:Array<LampObject>;
	public var cameras:Array<CameraObject>;
	public var speakers:Array<SpeakerObject>;
	public var decals:Array<DecalObject>;
	public var empties:Array<Object>;
	public var animations:Array<Animation>;

	public var embedded:Map<String, kha.Image>;

	public var ready:Bool; // Async in progress

	public var traitInits:Array<Void->Void> = [];

	public function new() {
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
		embedded = new Map();
		root = new Object();
		root.name = "Root";
		traitInits = [];
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
					trace('No camera found for scene "' + format.name + '"!');
					done(null);
				}

				active.camera = active.getCamera(format.camera_ref);
				done(sceneObject);

				// Hooks
				for (f in active.traitInits) f();
				active.traitInits = [];
			});
		});
	}

	// Reload scene for now
	public static function patch() {
		#if arm_sceneload
		var cameraTransform = Scene.active.camera.transform;
		Data.clearSceneData();
		Scene.setActive(Scene.active.raw.name, function(o:Object) {
			Scene.active.camera.transform = cameraTransform;
			Scene.active.root.addTrait(new armory.trait.internal.SpaceArmory());
		});
		#end
	}

	public static function patchTrait(traitName:String) {
		#if arm_sceneload
		// Reinstantiate modified traits
		var cname:Class<iron.Trait> = cast Type.resolveClass(traitName);
		if (cname == null) return;
		for (o in active.meshes) { // Check meshes only for now
			var t = o.getTrait(cname);
			if (t != null) {
				t.remove();
				o.addTrait(Type.createInstance(cname, []));
			}
		}
		#end
	}

	public function remove() {
		if (meshBatch != null) meshBatch.remove();
		for (o in meshes) o.remove();
		for (o in lamps) o.remove();
		for (o in cameras) o.remove();
		for (o in speakers) o.remove();
		for (o in decals) o.remove();
		for (o in empties) o.remove();
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
				Scene.active.ready = true;
			});
		});
	}

	public function updateFrame() {
		if (!ready) return;
		#if arm_stream
		sceneStream.update(active.camera);
		#end
		for (anim in animations) anim.update(iron.system.Time.delta);
	}

	public function renderFrame(g:kha.graphics4.Graphics) {
		if (!ready) return;
		framePassed = true;

		for (e in empties) if (e != null && e.parent != null) e.transform.update();

		var activeCamera = camera;
		// Render active mirrors
		for (cam in cameras) {
			if (cam.data.mirror != null) {
				camera = cam;
				camera.renderFrame(g, root, lamps);
			}
		}
		// Render active camera
		camera = activeCamera;
		camera.renderFrame(g, root, lamps);
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

	public function addScene(sceneName:String, parent:Object, done:Object->Void) {
		if (parent == null) {
			parent = addObject();
			parent.name = sceneName;
		}
		Data.getSceneRaw(sceneName, function(format:TSceneFormat) {
			createTraits(format.traits, parent); // Scene traits
			loadEmbeddedData(format.embedded_datas, function() { // Additional scene assets

				// GP
				if (format.grease_pencil_ref != null) {
					var ref = format.grease_pencil_ref.split('/');
					var object_file = '';
					var data_ref = '';
					if (ref.length == 2) { // File reference
						object_file = ref[0];
						data_ref = ref[1];
					}
					else { // Local GP data
						object_file = sceneName;
						data_ref = format.grease_pencil_ref;
					}
					Data.getGreasePencil(object_file, data_ref, function(gp:GreasePencilData) {
						greasePencil = gp;
					});
				}

				objectsTraversed = 0;
				traverseObjects(format, parent, format.objects, null, function() { // Scene objects
					done(parent);
				}, getObjectsCount(format.objects));
			});
		});
	}

	function getObjectsCount(objects:Array<TObj>, discardNoSpawn = true):Int {
		var result = objects.length;
		for (o in objects) {
			if (discardNoSpawn && o.spawn != null && o.spawn == false) continue; // Do not count children of non-spawned objects
			if (o.children != null) result += getObjectsCount(o.children);
		}
		return result;
	}

	var objectsTraversed:Int;
	function traverseObjects(format:TSceneFormat, parent:Object, objects:Array<TObj>, parentObject:TObj, done:Void->Void, objectsCount:Int) {
		if (objects == null) return;
		for (i in 0...objects.length) {
			var o = objects[i];
			if (o.spawn != null && o.spawn == false) {
				if (++objectsTraversed == objectsCount) done();
				continue; // Do not auto-create this object
			}
			
			createObject(o, format, parent, parentObject, function(object:Object) {
				if (object != null) traverseObjects(format, object, o.children, o, done, objectsCount);
				if (++objectsTraversed == objectsCount) done();
			});
		}
	}
	
	var objectsTraversed2:Int;
	public function spawnObject(name:String, parent:Object, done:Object->Void, spawnChildren = true) {
		objectsTraversed2 = 0;
		var obj = getObj(raw, name);
		var objectsCount = spawnChildren ? getObjectsCount([obj], false) : 1;
		spawnObjectTree(obj, parent, done, spawnChildren, objectsCount);
	}

	public function parseObject(sceneName:String, objectName:String, parent:Object, done:Object->Void) {
		Data.getSceneRaw(sceneName, function(format:TSceneFormat) {
			var o:TObj = getObj(format, objectName);
			if (o == null) done(null);
			createObject(o, format, parent, null, done);
		});
	}

	function spawnObjectTree(obj:TObj, parent:Object, done:Object->Void, spawnChildren:Bool, objectsCount:Int) {
		createObject(obj, raw, parent, null, function(object:Object) {
			if (spawnChildren && obj.children != null) {
				for (child in obj.children) spawnObjectTree(child, object, done, spawnChildren, objectsCount);
			}
			if (++objectsTraversed2 == objectsCount) done(object);
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
				if (o.dimensions != null) object.transform.setDimensions(o.dimensions[0], o.dimensions[1], o.dimensions[2]);
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
							if (parentObject != null && parentObject.action_refs != null) {
								var actions:Array<TSceneFormat> = [];
								for (ref in parentObject.action_refs) {
									Data.getSceneRaw(ref, function(action:TSceneFormat) {
										actions.push(action);
										if (actions.length == parentObject.action_refs.length) {
											#if arm_stream
											streamMeshObject(
											#else
											returnMeshObject(
											#end
												object_file, data_ref, sceneName, actions, materials, parent, o, done);
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
					for (s in object_refs) {
						spawnObject(s, ro, function(so:Object) {
							if (++spawned == object_refs.length) done(ro);
						});
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
	function streamMeshObject(object_file:String, data_ref:String, sceneName:String, actions:Array<TSceneFormat>, materials:Vector<MaterialData>, parent:Object, o:TObj, done:Object->Void) {
		sceneStream.add(object_file, data_ref, sceneName, actions, materials, parent, o);
		// TODO: Increase objectsTraversed by full children count
		if (o.children != null) objectsTraversed += o.children.length;
		// Return immediately and stream progressively
		returnObject(null, null, done);
	}
#end

	public function returnMeshObject(object_file:String, data_ref:String, sceneName:String, actions:Array<TSceneFormat>, materials:Vector<MaterialData>, parent:Object, o:TObj, done:Object->Void) {
		Data.getMesh(object_file, data_ref, actions, function(mesh:MeshData) {
			var object = addMeshObject(mesh, materials, parent);
		
			// Attach particle systems
			if (o.particle_refs != null) {
				for (ref in o.particle_refs) cast(object, MeshObject).setupParticleSystem(sceneName, ref);
			}
			// Attach tilesheet
			if (o.tilesheet_ref != null) {
				cast(object, MeshObject).setupTilesheet(sceneName, o.tilesheet_ref, o.tilesheet_action_ref);
			}

			if (o.dimensions != null) object.transform.setDimensions(o.dimensions[0], o.dimensions[1], o.dimensions[2]);
			returnObject(object, o, done);
		});
	}

	function returnObject(object:Object, o:TObj, done:Object->Void) {
		if (object != null) {
			object.raw = o;
			object.name = o.name;
			if (o.visible != null) object.visible = o.visible;
			if (o.visible_mesh != null) object.visibleMesh = o.visible_mesh;
			if (o.visible_shadow != null) object.visibleShadow = o.visible_shadow;
			createConstraints(o.constraints, object);
			generateTranform(o, object.transform);
			object.setupAnimation();
			if (o.dimensions == null) { // Assume 2x2x2 dimensions
				var sc = object.transform.scale;
				object.transform.setDimensions(2.0 * sc.x, 2.0 * sc.y, 2.0 * sc.z);
			}
			createTraits(o.traits, object);
		}
		done(object);
	}

	static function generateTranform(object:TObj, transform:Transform) {
		transform.world = Mat4.fromFloat32Array(object.transform.values);
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
						if (pval != "") Reflect.setProperty(traitInst, pname, parseArg(pval));
					}
				}
				object.addTrait(traitInst);
			}
		}
	}

 	static function parseArg(str:String):Dynamic {
		if (str == "true") return true;
		else if (str == "false") return false;
		else if (str.charAt(0) == "'") return StringTools.replace(str, "'", "");
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

	public function toString():String {
		return "Scene " + raw.name;
	}
}
