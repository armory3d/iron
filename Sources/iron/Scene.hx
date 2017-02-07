package iron;

import haxe.ds.Vector;
import iron.Trait;
import iron.object.Constraint;
import iron.object.Transform;
import iron.object.Object;
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

	public var meshes:Array<MeshObject>;
	public var lamps:Array<LampObject>;
	public var cameras:Array<CameraObject>;
	public var speakers:Array<SpeakerObject>;
	public var decals:Array<DecalObject>;
	public var animations:Array<Animation>;

	public var embedded:Map<String, kha.Image>;

	public var ready:Bool; // Async in progress

	public var traitInits:Array<Void->Void> = [];

	public function new() {
		meshes = [];
		lamps = [];
		cameras = [];
		speakers = [];
		decals = [];
		animations = [];
		embedded = new Map();
		root = new Object();
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
					trace('No camera found for scene "$format.name"!');
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
		var cameraTransform = Scene.active.camera.transform;
		Data.clearSceneData();
		Scene.setActive(Scene.active.raw.name, function(o:Object) {
			Scene.active.camera.transform = cameraTransform;
		});
	}

	public function remove() {
		for (o in meshes) o.remove();
		for (o in lamps) o.remove();
		for (o in cameras) o.remove();
		for (o in speakers) o.remove();
		for (o in decals) o.remove();
		root.remove();
	}

	public static function setActive(sceneName:String, done:Object->Void = null) {
		if (Scene.active != null) Scene.active.remove();
		iron.data.Data.getSceneRaw(sceneName, function(format:TSceneFormat) {
			Scene.create(format, function(o:Object) {
				if (done != null) done(o);
				Scene.active.ready = true;
			});
		});
	}

	public function updateFrame() {
		for (anim in animations) anim.update(iron.system.Time.delta);
	}

	public function renderFrame(g:kha.graphics4.Graphics) {
		if (!ready) return;

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
		if (parent == null) parent = addObject();
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
				var withGroup:Array<Object> = [];
				traverseObjects(format, sceneName, parent, format.objects, null, withGroup, function() { // Scene objects
					for (object in withGroup) setupGroup(object, format);
					done(parent);
				}, getObjectsCount(format.objects));
			});
		});
	}

	function getObjectsCount(objects:Array<TObj>):Int {
		var result = objects.length;
		for (o in objects) {
			if (o.spawn != null && o.spawn == false) continue; // Do not count children of non-spawned objects
			if (o.children != null) result += getObjectsCount(o.children);
		}
		return result;
	}

	var objectsTraversed:Int;
	function traverseObjects(format:TSceneFormat, sceneName:String, parent:Object, objects:Array<TObj>, parentObject:TObj, withGroup:Array<Object>, done:Void->Void, objectsCount:Int) {
		if (objects == null) return;
		for (i in 0...objects.length) {
			var o = objects[i];
			if (o.spawn != null && o.spawn == false) {
				objectsTraversed++;
				if (objectsTraversed == objectsCount) done();
				continue; // Do not auto-create this object
			}
			
			createObject(o, format, sceneName, parent, parentObject, function(object:Object) {
				if (o.group_ref != null) withGroup.push(object);
				if (object != null) traverseObjects(format, sceneName, object, o.children, o, withGroup, done, objectsCount);

				objectsTraversed++;
				if (objectsTraversed == objectsCount) done();
			});
		}
	}
	
	public function spawnObject(name:String, parent:Object, done:Object->Void) {
		createObject(getObj(raw, name), raw, raw.name, parent, null, done); // Get rid of scene name passing
	}

	public function parseObject(sceneName:String, objectName:String, parent:Object, done:Object->Void) {
		Data.getSceneRaw(sceneName, function(format:TSceneFormat) {
			var o:TObj = getObj(format, sceneName);
			if (o == null) done(null);
			createObject(o, format, sceneName, parent, null, done);
		});
	}

	function getObj(format:TSceneFormat, name:String) {
		// TODO: traverse to find deeper objects
		for (o in format.objects) if (o.name == name) return o;
		return null;
	}
	
	public function createObject(o:TObj, format:TSceneFormat, sceneName:String, parent:Object, parentObject:TObj, done:Object->Void) {

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
			if (o.material_refs.length == 0) {
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
							if (parentObject != null && parentObject.bones_ref != null) {
								Data.getSceneRaw(parentObject.bones_ref, function(boneformat:TSceneFormat) {
									var boneObjects:Array<TObj> = boneformat.objects;
									returnMeshObject(object_file, data_ref, sceneName, boneObjects, materials, parent, o, done);
								});
							}
							else returnMeshObject(object_file, data_ref, sceneName, null, materials, parent, o, done);
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
			returnObject(object, o, done);
		}
		else done(null);
	}

	function returnMeshObject(object_file:String, data_ref:String, sceneName:String, boneObjects:Array<TObj>, materials:Vector<MaterialData>, parent:Object, o:TObj, done:Object->Void) {
		Data.getMesh(object_file, data_ref, boneObjects, function(mesh:MeshData) {
			var object = addMeshObject(mesh, materials, parent);
		
			// Attach particle system
			if (o.particle_refs != null && o.particle_refs.length > 0) {
				cast(object, MeshObject).setupParticleSystem(sceneName, o.particle_refs[0]);
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
			createTraits(o.traits, object);
			createConstraints(o.constraints, object);
			generateTranform(o, object.transform);
			setupAnimation(o.animation_setup, object);
		}
		done(object);
	}

	static function generateTranform(object:TObj, transform:Transform) {
		transform.matrix = Mat4.fromArray(object.transform.values);
		transform.matrix.decompose(transform.loc, transform.rot, transform.scale);
		// Whether to apply parent matrix
		if (object.local_transform_only != null) transform.localOnly = object.local_transform_only;
		// Build matrix now if parent is invisible
		if (transform.object.parent != null && !transform.object.parent.visible) transform.update();
	}

	function setupGroup(object:Object, raw:TSceneFormat) {
		var o = object.raw;
		if (o.group_ref == null) return;
		for (g in raw.groups) {
			// Store referenced group objects
			if (g.name == o.group_ref) {
				object.group = [];
				for (s in g.object_refs) object.group.push(getChild(s));
				break;
			}
		}
	}

	static function setupAnimation(setup:TAnimationSetup, object:Object) {
		if (setup == null) return;
		object.setupAnimation(setup.start_track, setup.names, setup.starts, setup.ends, setup.speeds, setup.loops, setup.reflects, setup.max_bones);
	}

	static function createTraits(traits:Array<TTrait>, object:Object) {
		if (traits == null) return;
		for (t in traits) {
			if (t.type == "Script") {
				// Assign arguments if any
				var args:Dynamic = [];
				if (t.parameters != null) args = t.parameters;
				var traitInst = createTraitClassInstance(t.class_name, args);
				if (traitInst == null) {
					trace("Error: Trait '" + t.class_name + "' referenced in object '" + object.name + "' not found");
					continue;
				}
				object.addTrait(traitInst);
			}
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

	static function createTraitClassInstance(traitName:String, args:Dynamic):Dynamic {
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
}
