package iron.data;

import haxe.ds.Vector;
import iron.data.SceneFormat;
import iron.data.MaterialData;
import iron.data.MeshData;
import iron.object.Object;
import iron.object.CameraObject;
import iron.math.Vec4;

typedef TMeshHandle = {
	var object_file:String;
	var data_ref:String;
	var sceneName:String;
	var boneObjects:Array<TObj>;
	var materials:Vector<MaterialData>;
	var parent:Object;
	var obj:TObj;
	var object:Object;
	var loading:Bool;
}

class StreamSector {
	public function new() {}
	public var handles:Array<TMeshHandle> = []; // Mesh objects
}

class SceneStream {

	var checkMax = 20; // Objects checked per frame
	var checkPos = 0;
	var loadMax = 2; // Max objects loaded at once
	var loading = 0; // Objects being loaded

	// Assumes view distance 200
	var loadDistance = 210;
	var unloadDistance = 300;
	var sectors:Array<StreamSector>; // 100x100 groups

	public function sceneTotal():Int {
		return sectors[0].handles.length;
	}

	public function new() {
		sectors = [new StreamSector()];
	}

	public function add(object_file:String, data_ref:String, sceneName:String, boneObjects:Array<TObj>, materials:Vector<MaterialData>, parent:Object, obj:TObj) {
		sectors[0].handles.push({object_file: object_file, data_ref: data_ref, sceneName: sceneName, boneObjects: boneObjects, materials: materials, parent: parent, obj: obj, object: null, loading: false});
	}

	public function update(camera:CameraObject) {
		if (loading >= loadMax) return; // Busy loading..

		var sec = sectors[0];
		var to = Std.int(Math.min(checkMax, sec.handles.length)); 
		for (i in 0...to) {

			var h = sec.handles[checkPos];
			checkPos++;
			if (checkPos >= sec.handles.length) checkPos = 0;
			
			// Check radius in sector
			var camX = camera.transform.absx();
			var camY = camera.transform.absy();
			var camZ = camera.transform.absz();
			var hx = h.obj.transform.values[3];
			var hy = h.obj.transform.values[7];
			var hz = h.obj.transform.values[11];
			var cameraDistance = Vec4.distance3df(camX, camY, camZ, hx, hy, hz);
			var dim = h.obj.dimensions;
			if (dim != null) {
				var r = dim[0];
				if (dim[1] > r) r = dim[1];
				if (dim[2] > r) r = dim[2];
				cameraDistance -= r;
				// TODO: handle scale & ror
			}

			// Load mesh
			if (cameraDistance < loadDistance && h.object == null && !h.loading) {
				h.loading = true;
				loading++;
				iron.Scene.active.returnMeshObject(h.object_file, h.data_ref, h.sceneName, h.boneObjects, h.materials, h.parent, h.obj, function(object:Object) {
					h.object = object;
					h.loading = false;
					loading--;
				});
				if (loading >= loadMax) return;
			}
			// Unload mesh
			else if (cameraDistance > unloadDistance && h.object != null) {
				h.object.remove();
				h.object = null;
				iron.data.Data.deleteMesh(h.object_file + h.data_ref);
			}
		}
	}
}
