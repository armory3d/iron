package iron;

import iron.Trait;
import iron.object.Transform;
import iron.object.Object;
import iron.object.MeshObject;
import iron.object.LampObject;
import iron.object.CameraObject;
import iron.object.SpeakerObject;
import iron.object.DecalObject;
import iron.data.Data;
import iron.data.MeshData;
import iron.data.LampData;
import iron.data.CameraData;
import iron.data.MaterialData;
import iron.data.ShaderData;
import iron.data.SceneFormat;
import iron.data.WorldData;
import iron.math.Mat4;

class Scene {

	public static var active:Scene = null;
	
	public var raw:TSceneFormat;
	public var root:Object;
	public var camera:CameraObject;
	public var world:WorldData;

	public var meshes:Array<MeshObject>;
	public var lamps:Array<LampObject>;
	public var cameras:Array<CameraObject>;
	public var speakers:Array<SpeakerObject>;
	public var decals:Array<DecalObject>;

	public var embedded:Map<String, kha.Image>;

	public var waiting:Bool; // Async in progress

	public var traitInits:Array<Void->Void> = [];

	public function new() {
		meshes = [];
		lamps = [];
		cameras = [];
		speakers = [];
		decals = [];
		embedded = new Map();
		root = new Object();
		traitInits = [];
	}

// #if (js && WITH_PATCH_ELECTRON)
	// static var first = true;
	// static var patchTime = 0.0;
	// static var lastMtime:Dynamic;
	// static var lastSize:Dynamic;
// #end
	public static function create(format:TSceneFormat, done:Object->Void) {
		active = new Scene();
		active.waiting = true;
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

// #if (js && WITH_PATCH_ELECTRON)
// 				if (first) {
// 					first = false;
// 					var electron = untyped __js__('window && window.process && window.process.versions["electron"]');
// 					if (electron) {
// 						untyped __js__('var fs = require("fs");');
// 						App.notifyOnUpdate(function() {
// 							patchTime += iron.system.Time.delta;
// 							if (patchTime > 0.1) {
// 								patchTime = 0;
// 								var repatch = false;
// 								// Compare mtime and size of scene file
// 								untyped __js__('fs.stat(__dirname + "/" + {0} + ".arm", function(err, stats) {', active.raw.name);
// 								untyped __js__('	if ({0} > stats.mtime || {0} < stats.mtime || {1} !== stats.size) { if ({0} !== undefined) { {2} = true; } {0} = stats.mtime; {1} = stats.size; }', lastMtime, lastSize, repatch);
// 								if (repatch) patch();
// 								untyped __js__('});');
// 							}
// 						});
// 					}
// 				}
// #end
				done(sceneObject);

				// Hooks
				for (f in active.traitInits) f();
				active.traitInits = [];
			});
		});
	}

	// Reload scene for now
	public static function patch() {
		// TODO: Pause render?
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

	public static function setActive(sceneName:String, done:Object->Void) {
		if (Scene.active != null) Scene.active.remove();
		iron.data.Data.getSceneRaw(sceneName, function(format:TSceneFormat) {
			Scene.create(format, function(o:Object) {
				done(o);
				Scene.active.waiting = false;
			});
		});
	}

	public function renderFrame(g:kha.graphics4.Graphics) {
		if (waiting) return;

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

	public function getObject(name:String):Object {
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

	public function addMeshObject(data:MeshData, materials:Array<MaterialData>, parent:Object = null):MeshObject {
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

	public function addScene(name:String, parent:Object, done:Object->Void) {
		if (parent == null) parent = addObject();
		Data.getSceneRaw(name, function(format:TSceneFormat) {
			createTraits(format.traits, parent); // Scene traits
			loadEmbeddedData(format.embedded_datas, function() { // Additional scene assets
				objectsTraversed = 0;
				traverseObjects(format, name, parent, format.objects, null, function() { // Scene objects
					done(parent);
				}, getObjectsCount(format.objects));
			});
		});
	}

	function getObjectsCount(objects:Array<TObj>):Int {
		var result = objects.length;
		for (o in objects) {
			result += getObjectsCount(o.children);
		}
		return result;
	}

	var objectsTraversed:Int;
	function traverseObjects(format:TSceneFormat, name:String, parent:Object, objects:Array<TObj>, parentObject:TObj, done:Void->Void, objectsCount:Int) {
		for (i in 0...objects.length) {
			var o = objects[i];
			if (o.spawn != null && o.spawn == false) {
				objectsTraversed++;
				if (objectsTraversed == objectsCount) done();
				continue; // Do not auto-create this object
			}
			
			createObject(o, format, name, parent, parentObject, function(object:Object) {
				if (object != null) traverseObjects(format, name, object, o.children, o, done, objectsCount);

				objectsTraversed++;
				if (objectsTraversed == objectsCount) done();
			});
		}
	}
	
	public function parseObject(sceneName:String, objectName:String, parent:Object, done:Object->Void) {
		Data.getSceneRaw(sceneName, function(format:TSceneFormat) {
			// TODO: traverse to find deeper objects
			var o:TObj = null;
			for (object in format.objects) {
				if (object.name == objectName) { o = object; break; }
			}
			if (o == null) done(null);
			createObject(o, format, sceneName, parent, null, done);
		});
	}
	
	public function createObject(o:TObj, format:TSceneFormat, name:String, parent:Object, parentObject:TObj, done:Object->Void) {

		if (o.type == "camera_object") {
			Data.getCamera(name, o.data_ref, function(b:CameraData) {
				var object = addCameraObject(b, parent);
				returnObject(object, o, done);
			});
		}
		else if (o.type == "lamp_object") {
			Data.getLamp(name, o.data_ref, function(b:LampData) {
				var object = addLampObject(b, parent);	
				returnObject(object, o, done);
			});
		}
		else if (o.type == "mesh_object") {
			if (o.material_refs.length == 0) {
				// No material, create empty object
				var object = addObject(parent);
				setTransformDimensions(object.transform, o.dimensions);
				returnObject(object, o, done);
			}
			else {
				// Materials
				var materials:Array<MaterialData> = [];
				while (materials.length < o.material_refs.length) materials.push(null);
				var materialsLoaded = 0;

				for (i in 0...o.material_refs.length) {
					var ref = o.material_refs[i];
					Data.getMaterial(name, ref, function(mat:MaterialData) {
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
								object_file = name;
								data_ref = o.data_ref;
							}

							// Bone objects are stored in armature parent
							if (parentObject != null && parentObject.bones_ref != null) {
								Data.getSceneRaw(parentObject.bones_ref, function(boneformat:TSceneFormat) {
									var boneObjects:Array<TObj> = boneformat.objects;
									returnMeshObject(object_file, data_ref, name, boneObjects, materials, parent, o, done);
								});
							}
							else returnMeshObject(object_file, data_ref, name, null, materials, parent, o, done);
						}
					});
				}
			}
		}
		// else if (o.type == "armature_object") {}
		else if (o.type == "speaker_object") {
			var object = addSpeakerObject(Data.getSpeakerRawByName(format.speaker_datas, o.data_ref), parent);	
			returnObject(object, o, done);
		}
		else if (o.type == "decal_object") {
			if (o.material_refs != null && o.material_refs.length > 0) {
				Data.getMaterial(name, o.material_refs[0], function(material:MaterialData) {
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

	function returnMeshObject(object_file:String, data_ref:String, name:String, boneObjects:Array<TObj>, materials:Array<MaterialData>, parent:Object, o:TObj, done:Object->Void) {
		Data.getMesh(object_file, data_ref, boneObjects, function(mesh:MeshData) {
			var object = addMeshObject(mesh, materials, parent);
		
			// Attach particle system
			if (o.particle_refs != null && o.particle_refs.length > 0) {
				cast(object, MeshObject).setupParticleSystem(name, o.particle_refs[0]);
			}

			setTransformDimensions(object.transform, o.dimensions);
			returnObject(object, o, done);
		});
	}

	function setTransformDimensions(transform:Transform, dimensions:Array<Float>) {
		transform.size.set(dimensions[0], dimensions[1], dimensions[2]);
		transform.computeRadius();
	}

	function returnObject(object:Object, o:TObj, done:Object->Void) {
		if (object != null) {
			object.raw = o;
			object.name = o.name;
			if (o.visible != null) object.visible = o.visible;
			createTraits(o.traits, object);
			generateTranform(o, object.transform);
		}
		done(object);
	}

	static function generateTranform(object:TObj, transform:Transform) {
		transform.matrix = Mat4.fromArray(object.transform.values);
		transform.matrix.decompose(transform.loc, transform.rot, transform.scale);
		// Whether to apply parent matrix
		if (object.local_transform_only != null) transform.localOnly = object.local_transform_only;
	}

	static function createTraits(traits:Array<TTrait>, object:Object) {
		if (traits == null) return;
		for (t in traits) {
			if (t.type == "Script") {
				// Assign arguments if any
				var args:Dynamic = [];
				if (t.parameters != null) args = t.parameters;
				object.addTrait(createTraitClassInstance(t.class_name, args));
			}
		}
	}

	static function createTraitClassInstance(traitName:String, args:Dynamic):Dynamic {
		var cname = Type.resolveClass(traitName);
		if (cname == null) throw "Trait " + traitName + "not found.";
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
    	if (!waiting) f(); // Scene already running
        else traitInits.push(f);
    }

    public function removeInit(f:Void->Void) {
        traitInits.remove(f);
    }
}