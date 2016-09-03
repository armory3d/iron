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

	public function new() {
		meshes = [];
		lamps = [];
		cameras = [];
		speakers = [];
		decals = [];
		root = new Object();
	}

#if WITH_LIVEPATCH
	static var first = true;
	static var patchTime = 0.0;
	static var lastMtime:Dynamic;
	static var lastSize:Dynamic;
#end
	public static function create(raw:TSceneFormat):Object {
		active = new Scene();
		active.raw = raw;

		// Startup scene
		var sceneObject = active.addScene(raw.name);

		if (active.cameras.length == 0) {
			trace('No camera found for scene "$raw.name"!');
			return null;
		}

		active.camera = active.getCamera(raw.camera_ref);
		active.world = Data.getWorld(raw.name, raw.world_ref);

#if WITH_LIVEPATCH
		if (first) {
			first = false;
			untyped __js__('var fs = require("fs");');
			// Experimental scene patching
			App.notifyOnUpdate(function() {
				patchTime += iron.sys.Time.delta;
				if (patchTime > 0.1) {
					patchTime = 0;
					var repatch = false;
					// Compare mtime and size of scene file
					untyped __js__('fs.stat(__dirname + "/" + {0} + ".arm", function(err, stats) {', active.raw.name);
					untyped __js__('	if ({0} > stats.mtime || {0} < stats.mtime || {1} !== stats.size) { if ({0} !== undefined) { {2} = true; } {0} = stats.mtime; {1} = stats.size; }', lastMtime, lastSize, repatch);
						if (repatch) {
							var cameraTransform = active.camera.transform;
							iron.App.reloadAssets(function() {
								Data.clearSceneData();
								Scene.setActive(Scene.active.raw.name);
								active.camera.transform = cameraTransform;
							});
						}
					untyped __js__('});');
				}
			});
		}
#end

		return sceneObject;
	}

	public function remove() {
		for (o in meshes) o.remove();
		for (o in lamps) o.remove();
		for (o in cameras) o.remove();
		for (o in speakers) o.remove();
		for (o in decals) o.remove();
		root.remove();
	}

	public static function setActive(sceneName:String):Object {
		if (Scene.active != null) Scene.active.remove();
		var raw = iron.data.Data.getSceneRaw(sceneName);
        return Scene.create(raw);
	}

	public function renderFrame(g:kha.graphics4.Graphics) {
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

	public function addScene(name:String, parent:Object = null):Object {
		if (parent == null) parent = addObject();
		var data:TSceneFormat = Data.getSceneRaw(name);
		// Scene traits
		if (data.traits != null) createTraits(data.traits, parent);
		// Scene objects
		traverseObjects(data, name, parent, data.objects, null);
		return parent;
	}

	function traverseObjects(data:TSceneFormat, name:String, parent:Object, objects:Array<TObj>, parentObject:TObj) {
		for (o in objects) {
			if (o.spawn != null && o.spawn == false) continue; // Do not auto-create this object
			
			var object = createObject(o, data, name, parent, parentObject);
			if (object != null) {
				traverseObjects(data, name, object, o.objects, o);
			}
		}
	}
	
	public function parseObject(sceneName:String, objectName:String, parent:Object = null):Object {
		var raw:TSceneFormat = Data.getSceneRaw(sceneName);
		// TODO: traverse to find deeper objects
		var o:TObj = null;
		for (object in raw.objects) {
			if (object.name == objectName) {
				o = object;
				break;
			}
		}
		if (o == null) return null;
		return createObject(o, raw, sceneName, parent, null);
	}
	
	public function createObject(o:TObj, raw:TSceneFormat, name:String, parent:Object, parentObject:TObj):Object {
		var object:Object = null;
			
		if (o.type == "camera_object") {
			object = addCameraObject(Data.getCamera(name, o.data_ref), parent);
		}
		else if (o.type == "lamp_object") {
			object = addLampObject(Data.getLamp(name, o.data_ref), parent);	
		}
		else if (o.type == "mesh_object") {
			if (o.material_refs.length == 0) {
				// No material, create empty object
				object = addObject(parent);
			}
			else {
				// Materials
				var materials:Array<MaterialData> = [];
				for (ref in o.material_refs) {
					materials.push(Data.getMaterial(name, ref));
				}

				// Mesh reference
				var ref = o.data_ref.split("/");
				var object_file = "";
				var data_ref = "";
				if (ref.length == 2) { // File reference
					object_file = ref[0];
					data_ref = ref[1];
				}
				else { // Local mesh data
					object_file = name;
					data_ref = o.data_ref;
				}

				// Bone objects are stored in armature parent
				var boneObjects:Array<TObj> = null;
				if (parentObject != null && parentObject.bones_ref != null) {
					boneObjects = Data.getSceneRaw(parentObject.bones_ref).objects;
				}

				object = addMeshObject(Data.getMesh(object_file, data_ref, boneObjects), materials, parent);
				
				// Attach particle system
				if (o.particle_refs != null && o.particle_refs.length > 0) {
					cast(object, MeshObject).setupParticleSystem(name, o.particle_refs[0]);
				}
			}
			object.transform.size.set(o.dimensions[0], o.dimensions[1], o.dimensions[2]);
			object.transform.computeRadius();
		}
		// else if (o.type == "armature_object") {}
		else if (o.type == "speaker_object") {
			object = addSpeakerObject(Data.getSpeakerRawByName(raw.speaker_datas, o.data_ref), parent);	
		}
		else if (o.type == "decal_object") {
			var material:MaterialData = null;
			if (o.material_refs != null && o.material_refs.length > 0) {
				material = Data.getMaterial(name, o.material_refs[0]);
			}
			object = addDecalObject(material, parent);	
		}
		else if (o.type == "object") {
			object = addObject(parent);
		}

		if (object != null) {
			object.raw = o;
			object.name = o.name;
			if (o.visible != null) object.visible = o.visible;
			createTraits(o.traits, object);
			generateTranform(o, object.transform);
		}
		
		return object;
	}

	static function generateTranform(object:TObj, transform:Transform) {
		transform.matrix = Mat4.fromArray(object.transform.values);
		transform.matrix.decompose(transform.loc, transform.rot, transform.scale);
		// Whether to apply parent matrix
		if (object.local_transform_only != null) transform.localOnly = object.local_transform_only;
	}

	static function createTraits(traits:Array<TTrait>, object:Object) {
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
}
