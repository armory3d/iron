package fox.sys.importer;
import haxe.io.StringInput;
using StringTools;

// OpenGEX parser
// http://opengex.org

class Container {

	public var name:String;
	public var children:Array<Node> = [];

	public function new() {}
}

class OgexData extends Container {

	public var metrics:Array<Metric> = [];
	public var geometryObjects:Array<GeometryObject> = [];
	public var lightObjects:Array<LightObject> = [];
	public var cameraObjects:Array<CameraObject> = [];
	public var materials:Array<Material> = [];

	var file:StringInput;

	public function new(data:String) {
		super();

		file = new StringInput(data);
		var s:Array<String>;

		try {
			while (true) {
				s = readLine();
				switch(s[0]) {
					case "Metric":
						metrics.push(parseMetric(s));
					case "Node":
						children.push(parseNode(s, this));
					case "GeometryNode":
						children.push(parseGeometryNode(s, this));
					case "LightNode":
						children.push(parseLightNode(s, this));
					case "CameraNode":
						children.push(parseCameraNode(s, this));
					case "BoneNode":
						children.push(parseBoneNode(s, this));
					case "GeometryObject":
						geometryObjects.push(parseGeometryObject(s));
					case "LightObject":
						lightObjects.push(parseLightObject(s));
					case "CameraObject":
						cameraObjects.push(parseCameraObject(s));
					case "Material":
						materials.push(parseMaterial(s));
				}
			}
		}
		catch(ex:haxe.io.Eof) { }

		file.close();
	}

	public function getNode(name:String):Node { 
		var res:Node = null; 
		traverseNodes(function(it:Node) { 
			if (it.name == name) { res = it; }
		});
		return res; 
	}

	public function traverseNodes(callback:Node->Void) {
		for (i in 0...children.length) {
			traverseNodesStep(children[i], callback);
		}
	}
	
	function traverseNodesStep(node:Node, callback:Node->Void) {
		callback(node);
		for (i in 0...node.children.length) {
			traverseNodesStep(node.children[i], callback);
		}
	}

	public function getGeometryObject(ref:String):GeometryObject {
		for (go in geometryObjects) {
			if (go.ref == ref) return go;
		}
		return null;
	}

	public function getCameraObject(ref:String):CameraObject {
		for (co in cameraObjects) {
			if (co.ref == ref) return co;
		}
		return null;
	}

	public function getLightObject(ref:String):LightObject {
		for (lo in lightObjects) {
			if (lo.ref == ref) return lo;
		}
		return null;
	}

	public function getMaterial(ref:String):Material {
		for (m in materials) {
			if (m.ref == ref) return m;
		}
		return null;
	}

	// Parsing
	function readLine():Array<String> {
		var line = file.readLine();
		line = StringTools.trim(line);
		var str = line.split(" ");
		return str;
	}

	function readLine2():String {
		var line = file.readLine();
		line = StringTools.trim(line);
		return line;
	}

	function parseMetric(s:Array<String>):Metric {
		var metric = new Metric();
		metric.key = s[3].split('"')[1];
		var val = s[5].split("{")[1].split("}")[0];
		if (s[4] == "{float") {
			metric.value = Std.parseFloat(val);
		}
		else {
			metric.value = val.split('"')[1];
		}
		return metric;
	}

	function parseNode(s:Array<String>, parent:Container):Node {
		var n = new Node();
		n.parent = parent;
		n.ref = s[1];

		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Name":
					n.name = parseName(s);
				case "Transform":
					n.transform = parseTransform(s);
				case "Node":
					n.children.push(parseNode(s, n));
				case "GeometryNode":
					n.children.push(parseGeometryNode(s, n));
				case "LightNode":
					n.children.push(parseLightNode(s, n));
				case "CameraNode":
					n.children.push(parseCameraNode(s, n));
				case "BoneNode":
					n.children.push(parseBoneNode(s, n));
				case "}":
					break;
			}
		}
		return n;
	}

	function parseGeometryNode(s:Array<String>, parent:Container):GeometryNode {
		var n = new GeometryNode();
		n.parent = parent;
		n.ref = s[1];

		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Name":
					n.name = parseName(s);
				case "ObjectRef":
					n.objectRefs.push(parseObjectRef(s));
				case "MaterialRef":
					n.materialRefs.push(parseMaterialRef(s));
				case "Transform":
					n.transform = parseTransform(s);
				case "Node":
					n.children.push(parseNode(s, n));
				case "GeometryNode":
					n.children.push(parseGeometryNode(s, n));
				case "LightNode":
					n.children.push(parseLightNode(s, n));
				case "CameraNode":
					n.children.push(parseCameraNode(s, n));
				case "BoneNode":
					n.children.push(parseBoneNode(s, n));
				case "}":
					break;
			}
		}
		return n;
	}

	function parseLightNode(s:Array<String>, parent:Container):LightNode {
		var n = new LightNode();
		n.parent = parent;
		n.ref = s[1];

		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Name":
					n.name = parseName(s);
				case "ObjectRef":
					n.objectRefs.push(parseObjectRef(s));
				case "Transform":
					n.transform = parseTransform(s);
				case "Node":
					n.children.push(parseNode(s, n));
				case "GeometryNode":
					n.children.push(parseGeometryNode(s, n));
				case "LightNode":
					n.children.push(parseLightNode(s, n));
				case "CameraNode":
					n.children.push(parseCameraNode(s, n));
				case "BoneNode":
					n.children.push(parseBoneNode(s, n));
				case "}":
					break;
			}
		}
		return n;
	}

	function parseCameraNode(s:Array<String>, parent:Container):CameraNode {
		var n = new CameraNode();
		n.parent = parent;
		n.ref = s[1];

		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Name":
					n.name = parseName(s);
				case "ObjectRef":
					n.objectRefs.push(parseObjectRef(s));
				case "Transform":
					n.transform = parseTransform(s);
				case "Node":
					n.children.push(parseNode(s, n));
				case "GeometryNode":
					n.children.push(parseGeometryNode(s, n));
				case "LightNode":
					n.children.push(parseLightNode(s, n));
				case "CameraNode":
					n.children.push(parseCameraNode(s, n));
				case "BoneNode":
					n.children.push(parseBoneNode(s, n));
				case "}":
					break;
			}
		}
		return n;
	}

	function parseBoneNode(s:Array<String>, parent:Container):BoneNode {
		var n = new BoneNode();
		n.parent = parent;
		n.ref = s[1];

		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Name":
					n.name = parseName(s);
				case "Transform":
					n.transform = parseTransform(s);
				case "BoneNode":
					n.children.push(parseBoneNode(s, n));
				case "Animation":
					n.animation = parseAnimation(s);
				case "}":
					break;
			}
		}
		return n;
	}

	function parseGeometryObject(s:Array<String>):GeometryObject {
		var go = new GeometryObject();
		go.ref = s[1].split("\t")[0];
		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Mesh":
					go.mesh = parseMesh(s);
				case "}":
					break;
			}
		}
		return go;
	}

	function parseMesh(s:Array<String>):Mesh {
		var m = new Mesh();
		m.primitive = s[3].split('"')[1];
		while (true) {
			s = readLine();

			switch(s[0]) {
				case "VertexArray":
					m.vertexArrays.push(parseVertexArray(s));
				case "IndexArray":
					m.indexArray = parseIndexArray(s);
				case "Skin":
					m.skin = parseSkin(s);
				case "}":
					break;
			}
		}
		return m;
	}

	function parseSkin(s:Array<String>):Skin {
		var skin = new Skin();
		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Transform":
					skin.transform = parseTransform(s);
				case "Skeleton":
					skin.skeleton = parseSkeleton(s);
				case "BoneCountArray":
					skin.boneCountArray = parseBoneCountArray(s);
				case "BoneIndexArray":
					skin.boneIndexArray = parseBoneIndexArray(s);
				case "BoneWeightArray":
					skin.boneWeightArray = parseBoneWeightArray(s);
				case "}":
					break;
			}
		}
		return skin;
	}

	function parseSkeleton(s:Array<String>):Skeleton {
		var skel = new Skeleton();
		while (true) {
			s = readLine();

			switch(s[0]) {
				case "BoneRefArray":
					skel.boneRefArray = parseBoneRefArray(s);
				case "Transform":
					skel.transform = parseTransform(s);
				case "}":
					break;
			}
		}
		return skel;
	}

	function parseBoneRefArray(s:Array<String>):BoneRefArray {
		var bra = new BoneRefArray();
		readLine2(); readLine2(); readLine2();
		var ss = readLine2();
		ss = StringTools.replace(ss, " ", "");
		bra.refs = ss.split(",");
		readLine2(); readLine2();
		return bra;
	}

	function parseBoneCountArray(s:Array<String>):BoneCountArray {
		var bca = new BoneCountArray();
		readLine2(); readLine2(); readLine2();
		while (true) {
			var ss = readLine2();
			ss = StringTools.replace(ss, " ", "");
			s = ss.split(",");
			var offset = s[s.length - 1] == "" ? 1 : 0;
			for (i in 0...s.length - offset) bca.values.push(Std.parseInt(s[i]));
			if (offset == 0) break;
		}
		readLine2(); readLine2();
		return bca;
	}

	function parseBoneIndexArray(s:Array<String>):BoneIndexArray {
		var bia = new BoneIndexArray();
		readLine2(); readLine2(); readLine2();
		while (true) {
			var ss = readLine2();
			ss = StringTools.replace(ss, " ", "");
			s = ss.split(",");
			var offset = s[s.length - 1] == "" ? 1 : 0;
			for (i in 0...s.length - offset) bia.values.push(Std.parseInt(s[i]));
			if (offset == 0) break;
		}
		readLine2(); readLine2();
		return bia;
	}

	function parseBoneWeightArray(s:Array<String>):BoneWeightArray {
		var bwa = new BoneWeightArray();
		readLine2(); readLine2(); readLine2();
		while (true) {
			var ss = readLine2();
			ss = StringTools.replace(ss, " ", "");
			s = ss.split(",");
			var offset = s[s.length - 1] == "" ? 1 : 0;
			for (i in 0...s.length - offset) bwa.values.push(Std.parseFloat(s[i]));
			if (offset == 0) break;
		}
		readLine2(); readLine2();
		return bwa;
	}

	function parseVertexArray(s:Array<String>):VertexArray {
		var va = new VertexArray();
		va.attrib = s[3].split('"')[1];
		readLine2();
		var ss = readLine2();
		va.size = Std.parseInt(ss.split("[")[1].split("]")[0]);
		readLine2();
		
		while (true) {
			// TODO: unify float[] {} parsing
			ss = readLine2();
			ss = StringTools.replace(ss, "{", "");
			ss = StringTools.replace(ss, "}", "");
			s = ss.split(",");
			var offset = s[s.length - 1] == "" ? 1 : 0;
			for (i in 0...s.length - offset) va.values.push(Std.parseFloat(s[i]));
			if (offset == 0) break;
		}
		readLine2(); readLine2();
		return va;
	}

	function parseIndexArray(s:Array<String>):IndexArray {
		var ia = new IndexArray();
		readLine2();
		var ss = readLine2();
		ia.size = Std.parseInt(ss.split("[")[1].split("]")[0]);
		readLine2();
		
		while (true) {
			ss = readLine2();
			ss = StringTools.replace(ss, "{", "");
			ss = StringTools.replace(ss, "}", "");
			s = ss.split(",");
			var offset = s[s.length - 1] == "" ? 1 : 0;
			for (i in 0...s.length - offset) ia.values.push(Std.parseInt(s[i]));
			if (offset == 0) break;
		}
		readLine2(); readLine2();
		return ia;
	}

	function parseLightObject(s:Array<String>):LightObject {
		var lo = new LightObject();
		lo.ref = s[1];
		lo.type = s[4].split('"')[1];
		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Color":
					lo.color = parseColor(s);
				case "Atten":
					lo.atten = parseAtten(s);
				case "}":
					break;
			}
		}
		return lo;
	}

	function parseColor(s:Array<String>):Color {
		var col = new Color();
		col.attrib = s[3].split('"')[1];
		for (i in 5...s.length) {
			var ss = s[i];
			ss = StringTools.replace(ss, "{", "");
			ss = StringTools.replace(ss, "}", "");
			ss = StringTools.replace(ss, ",", "");
			col.values.push(Std.parseFloat(ss));
		}
		return col;
	}

	function parseAtten(s:Array<String>):Atten {
		var a = new Atten();
		a.curve = s[3].split('"')[1];
		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Param":
					a.params.push(parseParam(s));
				case "}":
					break;
			}
		}
		return a;
	}

	function parseParam(s:Array<String>):Param {
		var p = new Param();
		p.attrib = s[3].split('"')[1];
		var ss = s[5];
		ss = StringTools.replace(ss, "{", "");
		ss = StringTools.replace(ss, "}", "");
		p.value = Std.parseFloat(ss);
		return p;
	}

	function parseCameraObject(s:Array<String>):CameraObject {
		var co = new CameraObject();
		co.ref = s[1].split("\t")[0];
		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Param":
					co.params.push(parseParam(s));
				case "}":
					break;
			}
		}
		return co;
	}

	function parseMaterial(s:Array<String>):Material {
		var mat = new Material();
		mat.ref = s[1];
		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Name":
					mat.name = parseName(s);
				case "Color":
					mat.colors.push(parseColor(s));
				case "Param":
					mat.params.push(parseParam(s));
				case "}":
					break;
			}
		}
		return mat;
	}

	function parseName(s:Array<String>):String {
		return s[2].split('"')[1];
	}

	function parseObjectRef(s:Array<String>):String {
		return s[2].split("}")[0].substr(1);
	}

	function parseMaterialRef(s:Array<String>):String {
		return s[5].split("}")[0].substr(1);
	}

	function parseTransform(s:Array<String>):Transform {
		// TODO: Correct value parsing
		var t = new Transform();
		if (s.length > 1) t.ref = s[1];
		readLine2(); readLine2(); readLine2();
		var ss = readLine2().substr(1);
		ss += readLine2();
		ss += readLine2();
		var sss = readLine2();
		ss += sss.substr(0, sss.length - 2);
		s = ss.split(",");
		for (i in 0...s.length) {
			var j = Std.int(i / 4);
			var k = i % 4;
			t.values.push(Std.parseFloat(s[j + k * 4]));
		}
		readLine2(); readLine2();
		return t;
	}

	function parseAnimation(s:Array<String>):Animation {
		var a = new Animation();
		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Track":
					a.track = parseTrack(s);
				case "}":
					break;
			}
		}
		return a;
	}

	function parseTrack(s:Array<String>):Track {
		var t = new Track();
		t.target = s[3].substr(0, s[3].length - 2);
		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Time":
					t.time = parseTime(s);
				case "Value":
					t.value = parseValue(s);
				case "}":
					break;
			}
		}
		return t;
	}

	function parseTime(s:Array<String>):Time {
		var t = new Time();
		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Key":
					t.key = parseKey(s);
				case "}":
					break;
			}
		}
		return t;
	}

	function parseValue(s:Array<String>):Value {
		var v = new Value();
		while (true) {
			s = readLine();

			switch(s[0]) {
				case "Key":
					v.key = parseKey(s);
				case "}":
					break;
			}
		}
		return v;
	}

	function parseKey(s:Array<String>):Key {
		var k = new Key();
		if (s.length > 2) { // One line
			k.values.push(Std.parseFloat(s[2].substr(1)));
			for (i in 3...s.length - 2) {
				k.values.push(Std.parseFloat(s[i]));
			}
			k.values.push(Std.parseFloat(s[s.length - 1].substr(0, s[s.length - 1].length - 3)));
		}
		else { // Multi line
			readLine2(); readLine2(); readLine2();
			while (true) {
				var ss = readLine2();
				ss = StringTools.replace(ss, "{", "");
				ss = StringTools.replace(ss, "}", "");
				s = ss.split(",");
				var offset = s[s.length - 1] == "" ? 1 : 0;
				for (i in 0...s.length - offset) k.values.push(Std.parseFloat(s[i]));
				if (offset == 0) break;
			}
			readLine2();readLine2();
		}
		return k;
	}
}

class Metric {

	public var key:String;
	public var value:Dynamic;

	public function new() {}
}

class Node extends Container {

	public var parent:Container;
	public var ref:String;
	public var objectRefs:Array<String> = [];
	public var transform:Transform;

	public function new() { super(); }
}

class GeometryNode extends Node {

	public var materialRefs:Array<String> = [];

	public function new() { super(); }
}

class LightNode extends Node {

	public function new() { super(); }
}

class CameraNode extends Node {

	public function new() { super(); }
}

class BoneNode extends Node {

	public var animation:Animation;

	public function new() { super(); }
}

class GeometryObject {

	public var ref:String;
	public var mesh:Mesh;

	public function new() {}
}

class LightObject {

	public var ref:String;
	public var type:String;
	public var color:Color;
	public var atten:Atten;

	public function new() {}
}

class CameraObject {

	public var ref:String;
	public var params:Array<Param> = [];

	public function new() {}
}

class Material {

	public var ref:String;
	public var name:String;
	public var colors:Array<Color> = [];
	public var params:Array<Param> = [];

	public function new() {}
}

class Transform {

	public var ref:String = "";
	public var values:Array<Float> = [];

	public function new() {}
}

class Mesh {

	public var primitive:String;
	public var vertexArrays:Array<VertexArray> = [];
	public var indexArray:IndexArray;
	public var skin:Skin;

	public function new() {}

	public function getArray(attrib:String):VertexArray {
		for (va in vertexArrays) {
			if (va.attrib == attrib) return va;
		}
		return null;
	}
}

class Skin {

	public var transform:Transform;
	public var skeleton:Skeleton;
	public var boneCountArray:BoneCountArray;
	public var boneIndexArray:BoneIndexArray;
	public var boneWeightArray:BoneWeightArray;

	public function new() {}
}

class Skeleton {

	public var boneRefArray:BoneRefArray;
	public var transform:Transform;

	public function new() {}
}

class BoneRefArray {

	public var refs:Array<String> = [];

	public function new() {}
}

class BoneCountArray {

	public var values:Array<Int> = [];

	public function new() {}
}

class BoneIndexArray {

	public var values:Array<Int> = [];

	public function new() {}
}

class BoneWeightArray {

	public var values:Array<Float> = [];

	public function new() {}
}

class VertexArray {

	public var attrib:String;
	public var size:Int;
	public var values:Array<Float> = [];

	public function new() {}
}

class IndexArray {

	public var size:Int;
	public var values:Array<Int> = [];

	public function new() {}
}

class Color {

	public var attrib:String;
	public var values:Array<Float> = [];

	public function new() {}
}

class Atten {

	public var curve:String;
	public var params:Array<Param> = [];

	public function new() {}
}

class Param {

	public var attrib:String;
	public var value:Float;

	public function new() {}
}

class Animation {

	public var track:Track;
	public var target:String;

	public function new() {}
}

class Track {

	public var target:String;
	public var time:Time;
	public var value:Value;

	public function new() {}
}

class Time {

	public var key:Key;

	public function new() {}
}

class Value {

	public var key:Key;

	public function new() {}
}

class Key {

	public var size = 0;
	public var values:Array<Float> = [];

	public function new() {}
}
