package iron;

import haxe.ds.Vector;
import kha.graphics4.TextureFormat;
import iron.Trait;
import iron.object.Transform;
import iron.object.Constraint;
import iron.object.Animation;
import iron.object.Object;
import iron.object.CameraObject;
import iron.object.MeshObject;
import iron.object.LightObject;
import iron.object.SpeakerObject;
import iron.object.DecalObject;
import iron.object.ProbeObject;
import iron.data.CameraData;
import iron.data.MeshData;
import iron.data.LightData;
import iron.data.ProbeData;
import iron.data.WorldData;
import iron.data.MaterialData;
import iron.data.Armature;
import iron.data.Data;
import iron.data.SceneFormat;
import iron.data.TerrainStream;
import iron.data.SceneStream;
import iron.data.MeshBatch;
import iron.system.Time;
using StringTools;

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

	#if arm_batch
	public var meshBatch:MeshBatch = null;
	#end
	#if arm_stream
	public var sceneStream:SceneStream = null;
	#end
	#if arm_terrain
	public var terrainStream:TerrainStream = null;
	#end
	#if rp_decals
	public var decals:Array<DecalObject>;
	#end
	#if rp_probes
	public var probes:Array<ProbeObject>;
	#end
	public var meshes:Array<MeshObject>;
	public var lights:Array<LightObject>;
	public var cameras:Array<CameraObject>;
	#if arm_audio
	public var speakers:Array<SpeakerObject>;
	#end
	public var empties:Array<Object>;
	public var animations:Array<Animation>;
	public var armatures:Array<Armature>;
	var groups:Map<String, Array<Object>> = null;

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
		#if rp_decals
		decals = [];
		#end
		#if rp_probes
		probes = [];
		#end
		meshes = [];
		lights = [];
		cameras = [];
		#if arm_audio
		speakers = [];
		#end
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

				#if arm_terrain
				if (format.terrain_ref != null)  {
					active.terrainStream = new TerrainStream(format.terrain_datas[0]);
				}
				#end

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

	#if arm_patch
	public static var getRenderPath:Void->RenderPath;
	public static function patch() {
		Data.deleteAll();
		var cameraTransform = Scene.active.camera.transform;
		Scene.setActive(Scene.active.raw.name, function(o:Object) {
			RenderPath.setActive(getRenderPath());
			Scene.active.camera.transform = cameraTransform;
		});
	}
	#end

	public function remove() {
		for (f in traitRemoves) f();
		#if arm_batch
		if (meshBatch != null) meshBatch.remove();
		#end
		#if arm_stream
		if (sceneStream != null) sceneStream.remove();
		#end
		#if arm_terrain
		if (terrainStream != null) terrainStream.remove();
		#end
		#if rp_decals
		for (o in decals) o.remove();
		#end
		#if rp_probes
		for (o in probes) o.remove();
		#end
		for (o in meshes) o.remove();
		for (o in lights) o.remove();
		for (o in cameras) o.remove();
		#if arm_audio
		for (o in speakers) o.remove();
		#end
		for (o in empties) o.remove();
		groups = null;
		root.remove();
	}

	static var framePassed = true;
	public static function setActive(sceneName:String, done:Object->Void = null) {
		if (!framePassed) return;
		framePassed = false;
		if (Scene.active != null) Scene.active.remove();
		Data.getSceneRaw(sceneName, function(format:TSceneFormat) {
			Scene.create(format, function(o:Object) {
				if (done != null) done(o);
				#if rp_voxelao // Revoxelize
				RenderPath.active.voxelized = 0;
				#end
			});
		});
	}

	public function updateFrame() {
		if (!ready) return;
		#if arm_stream
		sceneStream.update(active.camera);
		#end
		#if arm_terrain
		if (terrainStream != null) terrainStream.update(active.camera);
		#end
		for (anim in animations) anim.update(Time.delta);
		for (e in empties) if (e != null && e.parent != null) e.transform.update();
	}

	public function renderFrame(g:kha.graphics4.Graphics) {
		if (!ready || RenderPath.active == null) return;
		framePassed = true;

		// Render probes
		#if rp_probes
		var activeCamera = camera;
		for (probe in probes) {
			camera = probe.camera;
			probe.render(g, activeCamera);
		}
		camera = activeCamera;
		#end

		// Render active camera
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

	public function getLight(name:String):LightObject {
		for (l in lights) if (l.name == name) return l;
		return null;
	}

	public function getCamera(name:String):CameraObject {
		for (c in cameras) if (c.name == name) return c;
		return null;
	}

	#if arm_audio
	public function getSpeaker(name:String):SpeakerObject {
		for (s in speakers) if (s.name == name) return s;
		return null;
	}
	#end

	public function getEmpty(name:String):Object {
		for (e in empties) if (e.name == name) return e;
		return null;
	}

	public function getGroup(name:String):Array<Object> {
		if (groups == null) groups = new Map();
		var g = groups.get(name);
		if (g == null) {
			g = [];
			groups.set(name, g);
			var refs = getGroupObjectRefs(name);
			if (refs == null) return g;
			for (ref in refs) {
				var c = getChild(ref);
				if (c != null) g.push(c);
			}
		}
		return g;
	}

	public function addMeshObject(data:MeshData, materials:Vector<MaterialData>, parent:Object = null):MeshObject {
		var object = new MeshObject(data, materials);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	public function addLightObject(data:LightData, parent:Object = null):LightObject {
		var object = new LightObject(data);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	#if rp_probes
	public function addProbeObject(data:ProbeData, parent:Object = null):ProbeObject {
		var object = new ProbeObject(data);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}
	#end

	public function addCameraObject(data:CameraData, parent:Object = null):CameraObject {
		var object = new CameraObject(data);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}

	#if arm_audio
	public function addSpeakerObject(data:TSpeakerData, parent:Object = null):SpeakerObject {
		var object = new SpeakerObject(data);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}
	#end
	
	#if rp_decals
	public function addDecalObject(material:MaterialData, parent:Object = null):DecalObject {
		var object = new DecalObject(material);
		parent != null ? parent.addChild(object) : root.addChild(object);
		return object;
	}
	#end

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
	
	/**
	 * Spawn a new object instance in the Scene.
	 *
	 * @param	name The String name of the Object as defined in blender. 
	 * @param	parent The parent object this new object should be attached to. (Optional use null to just add to the Scene without a parent).
	 * @param	done A completion handler function to run after the spawn is complete. Example might want to change properties of the object after spawning.
	 * @param	spawnChildren Also spawn the children of the newly spawned object. (Optional default is true).
	 */
	public function spawnObject(name:String, parent:Object, done:Object->Void, spawnChildren = true) {
		var objectsTraversed = 0;
		var obj = getObj(raw, name);
		var objectsCount = spawnChildren ? getObjectsCount([obj], false) : 1;
		function spawnObjectTree(obj:TObj, parent:Object, parentObject:TObj, done:Object->Void) {
			createObject(obj, raw, parent, parentObject, function(object:Object) {
				if (spawnChildren && obj.children != null) {
					for (child in obj.children) spawnObjectTree(child, object, obj, done);
				}
				if (++objectsTraversed == objectsCount && done != null) done(object);
			});
		}
		spawnObjectTree(obj, parent, null, done);
	}

	public function parseObject(sceneName:String, objectName:String, parent:Object, done:Object->Void) {
		Data.getSceneRaw(sceneName, function(format:TSceneFormat) {
			var o:TObj = getObj(format, objectName);
			if (o == null) done(null);
			createObject(o, format, parent, null, done);
		});
	}

	public static function getObj(format:TSceneFormat, name:String):TObj {
		return traverseObjs(format.objects, name);
	}

	static function traverseObjs(children:Array<TObj>, name:String):TObj {
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
		else if (o.type == "light_object") {
			Data.getLight(sceneName, o.data_ref, function(b:LightData) {
				var object = addLightObject(b, parent);	
				returnObject(object, o, done);
			});
		}
		#if rp_probes
		else if (o.type == "probe_object") {
			Data.getProbe(sceneName, o.data_ref, function(b:ProbeData) {
				var object = addProbeObject(b, parent);	
				returnObject(object, o, done);
			});
		}
		#end
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
											var armature:Armature = null;
											// Check if armature exists
											for (a in armatures) if (a.uid == parent.uid) { armature = a; break; }
											// Create new one
											if (armature == null) {
												// Unique name if armature was already instantiated for different object
												for (a in armatures) if (a.name == parent.name) { parent.name += '.' + parent.uid; break; }
												armature = new Armature(parent.uid, parent.name, bactions);
												armatures.push(armature);
											}
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
		#if arm_audio
		else if (o.type == "speaker_object") {
			var object = addSpeakerObject(Data.getSpeakerRawByName(format.speaker_datas, o.data_ref), parent);	
			returnObject(object, o, done);
		}
		#end
		#if rp_decals
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
		#end
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

	function isLod(raw:TObj):Bool {
		return raw != null && raw.lods != null && raw.lods.length > 0;
	}

	public function returnMeshObject(object_file:String, data_ref:String, sceneName:String, armature:Armature, materials:Vector<MaterialData>, parent:Object, o:TObj, done:Object->Void) {
		Data.getMesh(object_file, data_ref, function(mesh:MeshData) {
			if (mesh.isSkinned) {
				var g = mesh.geom;
				armature != null ? g.addArmature(armature) : g.addAction(mesh.format.objects, 'none');
			}
			var object = addMeshObject(mesh, materials, parent);
			#if arm_batch
			var lod = isLod(o) || (parent != null && isLod(parent.raw));
			object.batch(lod);
			#end

			// Attach particle systems
			#if arm_particles
			if (o.particle_refs != null) {
				for (ref in o.particle_refs) cast(object, MeshObject).setupParticleSystem(sceneName, ref);
			}
			#end
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
			if (o.properties != null) {
				object.properties = new Map();
				for (p in o.properties) object.properties.set(p.name, p.value);
			}
			createTraits(o.traits, object);
		}
		done(object);
	}

	static function generateTransform(object:TObj, transform:Transform) {
		transform.world = object.transform != null ? iron.math.Mat4.fromFloat32Array(object.transform.values) : iron.math.Mat4.identity();
		transform.world.decompose(transform.loc, transform.rot, transform.scale);
		// Whether to apply parent matrix
		if (object.local_only != null) transform.localOnly = object.local_only;
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
						if (pval != "") {
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
		else if (str.charAt(0) == "'") return str.replace("'", "");
		else if (str.charAt(0) == '"') return str.replace('"', "");
		else if (str.charAt(0) == "[") { // Array
			// Remove [] and recursively parse into array, then append into parent
			str = str.replace("[", "");
			str = str.replace("]", "");
			str = str.replace(" ", "");
			var ar:Dynamic = [];
			var vals = str.split(",");
			for (v in vals) ar.push(parseArg(v));
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
			embedData(file, function() {
				loaded++;
				if (loaded == datas.length) done();
			});
		}
	}

	public function embedData(file:String, done:Void->Void) {
		if (file.endsWith('.raw')) {
			Data.getBlob(file, function(blob:kha.Blob) {
				// Raw 3D texture bytes
				var b = blob.toBytes();
				var w = Std.int(Math.pow(b.length, 1 / 3)) + 1;
				var image = kha.Image.fromBytes3D(b, w, w, w, TextureFormat.L8);
				embedded.set(file, image);
				done();
			});
		}
		else {
			Data.getImage(file, function(image:kha.Image) {
				embedded.set(file, image);
				done();
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
}
