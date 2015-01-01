package fox.sys.importer;
import haxe.io.StringInput;
using StringTools;

// OpenGEX parser
// http://opengex.org

class Container {

	public var name:String;
	public var geometryNodes:Array<GeometryNode> = [];
	public var lightNodes:Array<LightNode> = [];
	public var cameraNodes:Array<CameraNode> = [];

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
					case "GeometryNode":
						geometryNodes.push(parseGeometryNode(s, this));
					case "LightNode":
						lightNodes.push(parseLightNode(s, this));
					case "CameraNode":
						cameraNodes.push(parseCameraNode(s, this));
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

	public function getGeometryNode(name:String):GeometryNode { 
		var res:GeometryNode = null; 
		traverseGeometryNodes(function(it:GeometryNode) { 
			if (it.name == name) { res = it; }
		});
		return res; 
	}

	public function traverseGeometryNodes(callback:GeometryNode->Void) {
		for (i in 0...geometryNodes.length) {
			traverseGeometryNodesStep(geometryNodes[i], callback);
		}
	}
	
	function traverseGeometryNodesStep(node:GeometryNode, callback:GeometryNode->Void) {
		callback(node);
		for (i in 0...node.geometryNodes.length) {
			traverseGeometryNodesStep(node.geometryNodes[i], callback);
		}
	}

	public function getGeometryObject(ref:String):GeometryObject {
		for (go in geometryObjects) {
			if (go.ref == ref) return go;
		}
		return null;
	}

	public function getMaterial(ref:String):Material {
		for (m in materials) {
			if (m.ref == ref) return m;
		}
		return null;
	}

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
				case "GeometryNode":
					n.geometryNodes.push(parseGeometryNode(s, n));
				case "LightNode":
					n.lightNodes.push(parseLightNode(s, n));
				case "CameraNode":
					n.cameraNodes.push(parseCameraNode(s, n));
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
				case "GeometryNode":
					n.geometryNodes.push(parseGeometryNode(s, n));
				case "LightNode":
					n.lightNodes.push(parseLightNode(s, n));
				case "CameraNode":
					n.cameraNodes.push(parseCameraNode(s, n));
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
				case "GeometryNode":
					n.geometryNodes.push(parseGeometryNode(s, n));
				case "LightNode":
					n.lightNodes.push(parseLightNode(s, n));
				case "CameraNode":
					n.cameraNodes.push(parseCameraNode(s, n));
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
				case "}":
					break;
			}
		}
		return m;
	}

	function parseVertexArray(s:Array<String>):VertexArray {
		var va = new VertexArray();
		va.attrib = s[3].split('"')[1];
		readLine2();
		var ss = readLine2();
		va.size = Std.parseInt(ss.split("[")[1].split("]")[0]);
		readLine2();
		
		while (true) {
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
		var t = new Transform();
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

	public var values:Array<Float> = [];

	public function new() {}
}

class Mesh {

	public var primitive:String;
	public var vertexArrays:Array<VertexArray> = [];
	public var indexArray:IndexArray;

	public function new() {}

	public function getArray(attrib:String):VertexArray {
		for (va in vertexArrays) {
			if (va.attrib == attrib) return va;
		}
		return null;
	}
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
