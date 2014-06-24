package wings.trait2d.ui;

import wings.core.Object;
import wings.core.Trait;
import wings.sys.Assets;
import wings.sys.importer.PsdData;
import wings.trait2d.ImageRenderer;
import wings.trait2d.TextRenderer;
import wings.trait2d.util.TapTrait;

class PsdParser extends Trait {

	var data:PsdData;
	var layers:Array<TPsdLayer>;
	var strings:Array<String>;

	var taps = new Map<String, TapTrait>();
	var texts = new Map<String, TextRenderer>();

	public function new(data:PsdData) {
		super();

		this.data = data;
		layers = data.getLayers();
		strings = data.getStrings();
	}

	public inline function setTap(name:String, tap:Void->Void) {
		taps.get(name).onTap = tap;
	}

	public inline function setText(name:String, text:String) {
		texts.get(name).text = text;
	}

	override function onItemAdd() {
		for (j in 0...layers.length) {
			var i = j;

			var captions = layers[i].name.split(":");

			var object = new Object();

			if (captions[1] == "image") {
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
			else if (captions[1] == "text") {
				var str = captions.length > 5 ? strings[Std.parseInt(captions[5])] : "";
				var renderer = new TextRenderer(str, Assets.getFont("avenir", Std.parseInt(captions[2])), TextAlign.Center);
				if (str == "") texts.set(captions[0], renderer);
				object.addTrait(renderer);
				object.transform.color = kha.Color.fromString(captions[3]);
				object.transform.ax = Std.parseFloat(StringTools.replace(captions[4], ",", "."));

				object.transform.x = layers[i].left + layers[i].width * object.transform.ax;
				object.transform.y = layers[i].top - 3;

			}
			else if (captions[1] == "button") {
				var renderer = new ImageRenderer(data.texture);
				renderer.source.x = layers[i].packedOrigin.x;
				renderer.source.y = layers[i].packedOrigin.y;
				renderer.source.w = layers[i].width;
				renderer.source.h = layers[i].height;
				object.addTrait(renderer);
				object.transform.w = renderer.source.w;
				object.transform.h = renderer.source.h;

				var tap = new TapTrait(null);
				object.addTrait(tap);
				taps.set(captions[0], tap);

				object.transform.x = layers[i].left;
				object.transform.y = layers[i].top;
			}

			parent.addChild(object);
		}
	}
}
