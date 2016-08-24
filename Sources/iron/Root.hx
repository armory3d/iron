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
import iron.math.Mat4;

class Root {

	public static var root:Object;
	public static var meshes:Array<MeshObject>;
	public static var lamps:Array<LampObject>;
	public static var cameras:Array<CameraObject>;
	public static var speakers:Array<SpeakerObject>;
	public static var decals:Array<DecalObject>;

	public function new() {
		meshes = [];
		lamps = [];
		cameras = [];
		speakers = [];
		decals = [];
		root = new Object();
	}

	// Objects
	public static function addObject(parent:Object = null):Object {
		var object = new Object();
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	public static function getObject(name:String):Object {
		return root.getChild(name);
	}

	public static function addMeshObject(data:MeshData, materials:Array<MaterialData>, parent:Object = null):MeshObject {
		var object = new MeshObject(data, materials);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	public static function addLampObject(data:LampData, parent:Object = null):LampObject {
		var object = new LampObject(data);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	public static function addCameraObject(data:CameraData, parent:Object = null):CameraObject {
		var object = new CameraObject(data);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	public static function addSpeakerObject(data:TSpeakerData, parent:Object = null):SpeakerObject {
		var object = new SpeakerObject(data);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}
	
	public static function addDecalObject(material:MaterialData, parent:Object = null):DecalObject {
		var object = new DecalObject(material);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	public static function addScene(name:String, parent:Object = null):Object {
		if (parent == null) parent = addObject();
		var data:TSceneFormat = Data.getSceneRaw(name);
		traverseObjects(data, name, parent, data.objects, null);
		return parent;
	}

	static function traverseObjects(data:TSceneFormat, name:String, parent:Object, objects:Array<TObj>, parentObject:TObj) {
		for (o in objects) {
			if (o.spawn != null && o.spawn == false) continue; // Do not auto-create this object
			
			var object = createObject(o, data, name, parent, parentObject);
			if (object != null) {
				traverseObjects(data, name, object, o.objects, o);
			}
		}
	}
	
	public static function parseObject(sceneName:String, objectName:String, parent:Object = null):Object {
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
		return Root.createObject(o, raw, sceneName, parent, null);
	}
	
	public static function createObject(o:TObj, raw:TSceneFormat, name:String, parent:Object, parentObject:TObj):Object {
		var object:Object = null;
			
		if (o.type == "camera_object") {
			object = Root.addCameraObject(Data.getCamera(name, o.data_ref), parent);
		}
		else if (o.type == "lamp_object") {
			object = Root.addLampObject(Data.getLamp(name, o.data_ref), parent);	
		}
		else if (o.type == "mesh_object") {
			if (o.material_refs.length == 0) {
				// No material, create empty object
				object = Root.addObject(parent);
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

				object = Root.addMeshObject(Data.getMesh(object_file, data_ref, boneObjects), materials, parent);
				
				// Attach particle system
				if (o.particle_refs != null && o.particle_refs.length > 0) {
					cast(object, MeshObject).setupParticleSystem(name, o.particle_refs[0]);
				}
			}
			object.transform.size.set(o.dimensions[0], o.dimensions[1], o.dimensions[2]);
			object.transform.computeRadius();
		}
		else if (o.type == "speaker_object") {
			object = Root.addSpeakerObject(Data.getSpeakerRawByName(raw.speaker_datas, o.data_ref), parent);	
		}
		else if (o.type == "decal_object") {
			var material:MaterialData = null;
			if (o.material_refs != null && o.material_refs.length > 0) {
				material = Data.getMaterial(name, o.material_refs[0]);
			}
			object = Root.addDecalObject(material, parent);	
		}
		else if (o.type == "object") {
			object = Root.addObject(parent);
		}

		if (object != null) {
			object.raw = o;
			object.name = o.name;
			if (o.visible != null) object.visible = o.visible;
			createTraits(o, object);
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

	static function createTraits(o:TObj, object:Object) {
		for (t in o.traits) {
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
