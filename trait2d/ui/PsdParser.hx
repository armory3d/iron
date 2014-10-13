package fox.trait2d.ui;

import fox.core.Object;
import fox.core.Trait;
import fox.sys.Assets;
import fox.sys.importer.PsdData;
import fox.trait2d.ImageRenderer;
import fox.trait2d.TextRenderer;
import fox.trait2d.util.TapTrait;

class PsdParser extends Trait {

	// Raw data
	public var data:PsdData;
	var layers:Array<TPsdLayer>;
	var strings:Array<String>;

	// Expose elements
	var taps = new Map<String, TapTrait>();
	var texts = new Map<String, TextRenderer>();

	// Options
	var autoAdd:Bool;
	var parseGroups:Bool;

	// Parsed objects
	var objects:Array<Object> = [];
	var textObjects:Array<Object> = [];

	// Parsed groups
	var groups:Array<Array<Object>> = [];

	public function new(data:PsdData, autoAdd:Bool = true, parseGroups:Bool = false) {
		super();

		this.data = data;
		this.autoAdd = autoAdd;
		this.parseGroups = parseGroups;

		layers = data.getLayers();
		strings = data.getStrings();

		// Limit to 5 groups for now
		for (i in 0...5) groups.push([]);
	}


	public function addGroup(id:Int) {
		for (i in 0...groups[id].length) {
			parent.addChild(groups[id][i]);
		}
	}

	public function removeGroup(id:Int) {
		for (i in 0...groups[id].length) {
			groups[id][i].remove();
		}
	}


	public inline function setTap(name:String, tap:Dynamic) {
		taps.get(name).onTap = tap;
	}

	public inline function setText(name:String, text:String) {
		texts.get(name).text = text;
	}

	public inline function getText(name:String):String {
		return texts.get(name).text;
	}

	override function onItemAdd() {
		for (j in 0...layers.length) {
			var i = layers.length - 1 - j;

			var object = new Object();

			// Parse group
			if (parseGroups) {
				groups[layers[i].group].push(object);
			}


			// Skip parsing this node into object
			if (layers[i].autoAdd == 0) {
				continue;
			}
			// Node not exported in atlas
			else if (layers[i].name.charAt(0) == "_") {
				
			}
			// Images
			else if (layers[i].type == "image") {

				createImage(object, layers[i]);
			}
			// Texts
			else if (layers[i].type == "text") {

				createText(object, layers[i]);

				// Display text items last
				textObjects.push(object);
			}
			// Buttons
			else if (layers[i].type == "button") {

				createButton(object, layers[i]);
			}


			// Add object
			if (layers[i].type != "text") {
				if (autoAdd) parent.addChild(object);
				else objects.push(object);
			}
		}

		// Show text items on top
		for (i in 0...textObjects.length) {
			if (autoAdd) {
				parent.addChild(textObjects[i]);
			}
			else {
				objects.push(textObjects[i]);
			}
		}
	}

	public function createImage(object:Object, layer:TPsdLayer) {

		var renderer = new ImageRenderer(data.texture);
		renderer.source.x = layer.packedOrigin.x;
		renderer.source.y = layer.packedOrigin.y;
		renderer.source.w = layer.width;
		renderer.source.h = layer.height;
		object.addTrait(renderer);

		object.transform.w = renderer.source.w;
		object.transform.h = renderer.source.h;

		object.transform.x = layer.left;
		object.transform.y = layer.top;

		object.name = layer.name;
	}

	public function createText(object:Object, layer:TPsdLayer, prefix:Int = 0) {

		var styles = layer.style.split(":");

		var str = styles.length > 3 ? strings[Std.parseInt(styles[3])] : "";
		var fontSize = Std.parseInt(styles[0]);
		var renderer = new TextRenderer(str, Assets.getFont("font", fontSize), TextAlign.Center);
		
		// Expose text
		var name = prefix == 0 ? layer.name : prefix + layer.name;
		/*if (str == "")*/ texts.set(name, renderer); // TODO: add empty texts only
		
		object.addTrait(renderer);

		object.transform.color = kha.Color.fromString(styles[1]);
		object.transform.ax = Std.parseFloat(styles[2]);

		object.transform.x = layer.left + layer.width * object.transform.ax;
		object.transform.y = layer.top - Std.int(fontSize / 6);

		object.name = layer.name;
	}

	public function createButton(object:Object, layer:TPsdLayer, prefix:Int = 0) {

		var renderer = new ImageRenderer(data.texture);
		renderer.source.x = layer.packedOrigin.x;
		renderer.source.y = layer.packedOrigin.y;
		renderer.source.w = layer.width;
		renderer.source.h = layer.height;
		object.addTrait(renderer);

		object.transform.w = renderer.source.w;
		object.transform.h = renderer.source.h;

		// Expose button
		// onTap will pass prefix as argument
		var tap = prefix == 0 ? new TapTrait(null) : new TapTrait(null, prefix);
		object.addTrait(tap);
		// Name will start with prefix value
		var name = prefix == 0 ? layer.name : prefix + layer.name;
		taps.set(name, tap);

		object.transform.x = layer.left;
		object.transform.y = layer.top;

		object.name = layer.name;
	}

	// id of the group specified in psd layer
	// prefix for instance we are currently creating
	public function createGroup(id:Int, prefix:Int = 0):Object {

		var elements = data.getGroup(id);
		return createElements(elements, prefix);
	}

	public function createElements(elements:Array<TPsdLayer>, prefix:Int = 0):Object {
		
		var container = new Object();

		for (i in 0...elements.length) {
			var elem = new Object();

			if (elements[i].type == "image") {
				createImage(elem, elements[i]);
			}
			else if (elements[i].type == "text") {
				createText(elem, elements[i], prefix);
			}
			else if (elements[i].type == "button") {
				createButton(elem, elements[i], prefix);
			}

			// TODO: properly set size
			if (elements[i].width > container.transform.w) {
				container.transform.w = elements[i].width;
			}
			if (elements[i].height > container.transform.h) {
				container.transform.h = elements[i].height;
			}

			container.addChild(elem);
		}

		return container;
	}
}
