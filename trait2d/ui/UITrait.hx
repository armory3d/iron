package fox.trait2d.ui;

import fox.core.IRenderable2D;
import fox.core.IUpdateable;
import fox.core.Trait;
import fox.trait.Input;
import fox.trait.Transform;
import fox.sys.importer.PsdData;

class Item {

	public var x:Float;
	public var y:Float;
	public var w:Float;
	public var h:Float;
	public var cb:Dynamic;
	public var args:Array<Dynamic>;
	public var layer:TPsdLayer;
	public var a:Float = 1;

	public function new() {}
}

class Text {

	public var x:Float;
	public var y:Float;
	public var text:String;

	public function new() {}
}

class UITrait extends Trait implements IUpdateable implements IRenderable2D {

	var transform:Transform;

	@inject
	var input:Input;

	var skin:PsdData;
	var font:kha.Font;

    var texture:kha.Image;
    var layerBg:TPsdLayer;
    var layerTitle:TPsdLayer;
    var layerClose:TPsdLayer;
    var layerArrow0:TPsdLayer;
    var layerArrow1:TPsdLayer;
    var layerButton:TPsdLayer;
    var layerCheck0:TPsdLayer;
    var layerCheck1:TPsdLayer;
    var layerRadio0:TPsdLayer;
    var layerRadio1:TPsdLayer;

    var items:Array<Item> = [];
    var texts:Array<Text> = [];

	public function new(skin:PsdData, font:kha.Font) {
		super();

        this.skin = skin;
        this.font = font;

        texture = skin.texture;
        layerBg = skin.getLayer("bg");
        layerTitle = skin.getLayer("title");
        layerClose = skin.getLayer("close");
        layerArrow0 = skin.getLayer("arrow0");
        layerArrow1 = skin.getLayer("arrow1");
        layerButton = skin.getLayer("button");
        layerCheck0 = skin.getLayer("check0");
        layerCheck1 = skin.getLayer("check1");
        layerRadio0 = skin.getLayer("radio0");
        layerRadio1 = skin.getLayer("radio1");
	}

	@injectAdd
    public function addTransform(trait:Transform) {
    	transform = trait;
        transform.w = 300;
        transform.h = 22;
    }

    public function update() {

    	var x = input.x;
    	var y = input.y;

    	// Drag title
    	if (input.touch && x >= transform.x && x <= transform.x + transform.w &&
    					   y >= transform.y && y <= transform.y + layerTitle.height) {
    		transform.x += input.deltaX;
    		transform.y += input.deltaY;
    	}

    	// Close
        var closeX = transform.x + transform.w - layerClose.width;
        if (x >= closeX && x <= closeX + layerClose.width &&
        	y >= transform.y && y <= transform.y + layerClose.height) {
        	
        	if (input.released) {

        	}
        }

    	// Items
    	for (i in items) {

    		if (x >= transform.x + i.x && x <= transform.x + i.x + i.w &&
    			y >= transform.y + i.y && y <= transform.y + i.y + i.h) {
    			i.a = 0.8;

    			if (input.released) {
    				if (i.args == null) i.cb();
    				else {
    					// Check
    					if (i.layer.name == "check0" || i.layer.name == "check1") {
    						i.args[0] = !i.args[0];
    						if (i.layer.name == "check0") i.layer = layerCheck1;
    						else i.layer = layerCheck0;
    					}
    					// Radio
    					else if (i.layer.name == "radio0" || i.layer.name == "radio1") {
    						if (i.layer.name == "radio0") i.layer = layerRadio1;
    						else i.layer = layerRadio0;
    					}

    					i.cb(i.args[0]);
    				}
    			}
    		}
    		else {
    			i.a = 1;
    		}
    	}
    }

    public function render(g:kha.graphics2.Graphics) {

        g.color = kha.Color.White;
        g.opacity = 1;

        // Bg
        g.drawScaledSubImage(texture,
                            layerBg.packedOrigin.x, layerBg.packedOrigin.y,
                            layerBg.width, layerBg.height,
                            transform.absx, transform.absy,
                            transform.w, transform.h);

        // Title
        g.drawScaledSubImage(texture,
                            layerTitle.packedOrigin.x, layerTitle.packedOrigin.y,
                            layerTitle.width, layerTitle.height,
                            transform.absx, transform.absy,
                            transform.w, layerTitle.height);

        // Close
        g.drawScaledSubImage(texture,
                            layerClose.packedOrigin.x, layerClose.packedOrigin.y,
                            layerClose.width, layerClose.height,
                            transform.absx + transform.w - layerClose.width, transform.absy,
                            layerClose.width, layerClose.height);

        // Title arrow
        g.drawScaledSubImage(texture,
                            layerArrow1.packedOrigin.x, layerArrow1.packedOrigin.y,
                            layerArrow1.width, layerArrow1.height,
                            transform.absx, transform.absy,
                            layerArrow1.width, layerArrow1.height);

        // Title text
        // TODO: strings on top
        g.font = font;
        g.drawString("WUI", transform.absx + 20, transform.absy + 0);

        // Items
        for (i in items) {

        	painter.opacity = i.a;

	        g.drawScaledSubImage(texture,
	                           i.layer.packedOrigin.x, i.layer.packedOrigin.y,
	                           i.layer.width, i.layer.height,
	                           transform.absx + i.x, transform.absy + i.y,
	                           i.w, i.h);
        }

        // Texts
        g.font = font;

        for (t in texts) {
        	g.drawString(t.text, transform.absx + t.x, transform.absy + t.y);
        }
    }

    public function addSection(title:String) {

    }

    public function addButton(title:String, onTap:Dynamic, args:Array<Dynamic> = null) {

		var item = new Item();
		item.x = 0;
		item.y = transform.h;
		item.w = 100;
		item.h = layerButton.height;
		item.cb = onTap;
		item.layer = layerButton;
		items.push(item);

		var text = new Text();
		text.text = title;
		text.x = item.x;
		text.y = item.y;
		texts.push(text);

		transform.h += layerButton.height;
    }

    public function addLabel(title:String) {
		var text = new Text();
		text.text = title;
		text.x = 0;
		text.y = transform.h;
		texts.push(text);

		transform.h += 20;
    }

    public function addCheck(title:String, onTap:Dynamic) {
    	var item = new Item();
		item.x = 0;
		item.y = transform.h;
		item.w = layerCheck0.width;
		item.h = layerCheck0.height;
		item.cb = onTap;
		item.args = [false];
		item.layer = layerCheck0;
		items.push(item);

		var text = new Text();
		text.text = title;
		text.x = item.x + item.w;
		text.y = item.y;
		texts.push(text);

		transform.h += layerCheck0.height;
    }

    public function addRadio(titles:Array<String>, onTap:Int->Void) {
    	for (i in 0...titles.length) {
    		var item = new Item();
			item.x = 0;
			item.y = transform.h;
			item.w = layerRadio0.width;
			item.h = layerRadio0.height;
			item.cb = onTap;
			item.args = [0];
			item.layer = layerRadio0;
			items.push(item);

			var text = new Text();
			text.text = titles[i];
			text.x = item.x + item.w;
			text.y = item.y;
			texts.push(text);

			transform.h += layerRadio0.height;
    	}
    }
}
