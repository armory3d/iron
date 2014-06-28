package wings.trait2d.ui;

import wings.core.Object;
import wings.core.Trait;
import wings.sys.Assets;
import wings.sys.importer.PsdData;
import wings.trait2d.ImageRenderer;
import wings.trait2d.TextRenderer;
import wings.trait2d.util.TapTrait;

class PsdParser extends Trait {

	// Raw data
	var data:PsdData;
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


	public inline function setTap(name:String, tap:Void->Void) {
		taps.get(name).onTap = tap;
	}

	public inline function setText(name:String, text:String) {
		texts.get(name).text = text;
	}


	override function onItemAdd() {
		for (j in 0...layers.length) {
			var i = layers.length - 1 - j;

			var captions = layers[i].name.split(":");

			var object = new Object();

			// Parse group
			if (parseGroups) {
				groups[layers[i].group].push(object);
			}

			// Skip parsing this node into object
			if (captions[0].charAt(0) == "!") {
				//captions[0] = captions[0].substring(1, captions[0].length);
				continue;
			}
			// Node not exported in atlas
			else if (captions[0].charAt(0) == "_") {
				
			}
			// Images
			else if (captions[1] == "image") {

				var renderer = new ImageRenderer(data.texture);
				renderer.source.x = layers[i].packedOrigin.x;
				renderer.source.y = layers[i].packedOrigin.y;
				renderer.source.w = layers[i].width;
				renderer.source.h = layers[i].height;
				object.addTrait(renderer);

				object.transform.w = renderer.source.w;
				object.transform.h = renderer.source.h;

				object.transform.x = layers[i].left;
				object.transform.y = layers[i].top;
			}
			// Texts
			else if (captions[1] == "text") {

				var str = captions.length > 5 ? strings[Std.parseInt(captions[5])] : "";
				var fontSize = Std.parseInt(captions[2]);
				var renderer = new TextRenderer(str, Assets.getFont("avenir", fontSize), TextAlign.Center);
				
				// Expose text
				/*if (str == "")*/ texts.set(captions[0], renderer); // TODO: add empty texts only
				
				object.addTrait(renderer);

				object.transform.color = kha.Color.fromString(captions[3]);
				object.transform.ax = Std.parseFloat(StringTools.replace(captions[4], ",", "."));

				object.transform.x = layers[i].left + layers[i].width * object.transform.ax;
				object.transform.y = layers[i].top - Std.int(fontSize / 6);

			}
			// Buttons
			else if (captions[1] == "button") {

				var renderer = new ImageRenderer(data.texture);
				renderer.source.x = layers[i].packedOrigin.x;
				renderer.source.y = layers[i].packedOrigin.y;
				renderer.source.w = layers[i].width;
				renderer.source.h = layers[i].height;
				object.addTrait(renderer);

				object.transform.w = renderer.source.w;
				object.transform.h = renderer.source.h;

				// Expose button
				var tap = new TapTrait(null);
				object.addTrait(tap);
				taps.set(captions[0], tap);

				object.transform.x = layers[i].left;
				object.transform.y = layers[i].top;
			}

			// Add object
			if (captions[1] == "text") {
				// Display text items last
				textObjects.push(object);
			}
			else {
				if (autoAdd) parent.addChild(object);
				else objects.push(object);
			}

			// Set name
			object.name = captions[0];
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
}
