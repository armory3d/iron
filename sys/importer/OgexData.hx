package fox.sys.importer;
import haxe.io.StringInput;
using StringTools;

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
						geometryNodes.push(parseGeometryNode(s));
					case "LightNode":
						lightNodes.push(parseLightNode(s));
					case "CameraNode":
						cameraNodes.push(parseCameraNode(s));
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

	function parseGeometryNode(s:Array<String>):GeometryNode {
		var n = new GeometryNode();
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
					n.geometryNodes.push(parseGeometryNode(s));
				case "LightNode":
					n.lightNodes.push(parseLightNode(s));
				case "CameraNode":
					n.cameraNodes.push(parseCameraNode(s));
				case "}":
					break;
			}
		}
		return n;
	}

	function parseLightNode(s:Array<String>):LightNode {
		var n = new LightNode();
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
					n.geometryNodes.push(parseGeometryNode(s));
				case "LightNode":
					n.lightNodes.push(parseLightNode(s));
				case "CameraNode":
					n.cameraNodes.push(parseCameraNode(s));
				case "}":
					break;
			}
		}
		return n;
	}

	function parseCameraNode(s:Array<String>):CameraNode {
		var n = new CameraNode();
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
					n.geometryNodes.push(parseGeometryNode(s));
				case "LightNode":
					n.lightNodes.push(parseLightNode(s));
				case "CameraNode":
					n.cameraNodes.push(parseCameraNode(s));
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
		return va;
	}

	function parseIndexArray(s:Array<String>):IndexArray {
		var ia = new IndexArray();
		return ia;
	}

	function parseLightObject(s:Array<String>):LightObject {
		var lo = new LightObject();
		return lo;
	}

	function parseCameraObject(s:Array<String>):CameraObject {
		var co = new CameraObject();
		return co;
	}

	function parseMaterial(s:Array<String>):Material {
		var mat = new Material();
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
		for (i in 0...s.length) t.values.push(Std.parseFloat(s[i]));
		readLine2(); readLine2();
		return t;
	}
}

class Metric {

	public var key:String;
	public var value:Dynamic;

	public function new() {

	}
}

class Container {

	public var geometryNodes:Array<GeometryNode> = [];
	public var lightNodes:Array<LightNode> = [];
	public var cameraNodes:Array<CameraNode> = [];

	public function new() {

	}
}

class Node extends Container {

	public var ref:String;
	public var name:String;
	public var objectRefs:Array<String> = [];
	public var transform:Transform;

	public function new() {
		super();
	}
}

class GeometryNode extends Node {

	public var materialRefs:Array<String> = [];

	public function new() {
		super();
	}
}

class LightNode extends Node {

	public function new() {
		super();
	}
}

class CameraNode extends Node {

	public function new() {
		super();
	}
}

class GeometryObject {

	public var ref:String;
	public var mesh:Mesh;

	public function new() {

	}
}

class LightObject {

	public var ref:String;
	public var type:String;
	public var color:Color;
	public var atten:Atten;

	public function new() {

	}
}

class CameraObject {

	public var ref:String;
	public var params:Array<Param> = [];

	public function new() {

	}
}

class Material {

	public var ref:String;
	public var name:String;
	public var colors:Array<Color> = [];
	public var params:Array<Param> = [];

	public function new() {

	}
}

class Transform {

	public var values:Array<Float> = [];

	public function new() {

	}
}

class Mesh {

	public var primitive:String;
	public var vertexArrays:Array<VertexArray> = [];
	public var indexArray:IndexArray;

	public function new() {

	}
}

class VertexArray {

	public var attrib:String;
	public var values:Array<Array<Float>> = [];

	public function new() {

	}
}

class IndexArray {

	public var values:Array<Array<Int>> = [];

	public function new() {

	}
}

class Color {

	public var attrib:String;
	public var values:Array<Float> = [];

	public function new() {

	}
}

class Atten {

	public var curve:String;
	public var params:Array<Param> = [];

	public function new() {

	}
}

class Param {

	public var attrib:String;
	public var value:Float;

	public function new() {

	}
}
