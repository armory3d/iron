package iron.data;

import iron.data.SceneFormat;
import iron.math.Mat4;

class Armature {

	public var name:String;
	public var actions:Array<Array<TObj>> = [];
	public var actionNames:Array<String> = [];
	public var actionMats:Map<TObj, Mat4> = null;

	public function new(name:String, actions:Array<TSceneFormat>) {
		this.name = name;
		
		for (a in actions) {
			for (o in a.objects) setParents(o);
			var bones:Array<TObj> = [];
			traverseBones(a.objects, function(object:TObj) { bones.push(object); });
			this.actions.push(bones);
			this.actionNames.push(a.name);
		}
	}

	public function initMats() {
		if (actionMats != null) return;
		actionMats = new Map();
		for (b in actions[0]) {
			// trace(b.name);
			actionMats.set(b, Mat4.fromFloat32Array(b.transform.values));
		}
	}

	public function getAction(name:String):Array<TObj> {
		for (i in 0...actions.length) if (actionNames[i] == name) return actions[i];
		return null;
	}

	static function setParents(object:TObj) {
		if (object.children == null) return;
		for (o in object.children) {
			o.parent = object;
			setParents(o);
		}
	}
	
	static function traverseBones(objects:Array<TObj>, callback:TObj->Void) {
		for (i in 0...objects.length) {
			traverseBonesStep(objects[i], callback);
		}
	}
	
	static function traverseBonesStep(object:TObj, callback:TObj->Void) {
		if (object.type == "bone_object") callback(object);
		if (object.children == null) return;
		for (i in 0...object.children.length) {
			traverseBonesStep(object.children[i], callback);
		}
	}
}
