package iron.object.tilesheet;

import haxe.xml.Access;

class TilesheetFrameData {
    public var textureWidth:Int = 1;
    public var textureHeight:Int = 1;

    /**
     * A list of the tilesheets frames, in order by index.
     */
    private var frames:Array<TilesheetFrame> = [];

    /**
     * A map of the tilesheets frames, keyed by name.
     */
    private var framesByName:Map<String, TilesheetFrame> = new Map<String, TilesheetFrame>();

    private function new(textureWidth:Int, textureHeight:Int) {
        this.textureWidth = textureWidth;
        this.textureHeight = textureHeight;
    }

    public function addFrame(frame:TilesheetFrame):Void {
        if (frame.name != null) {
            if (framesByName.exists(frame.name)) {
                return;
            } else {
                framesByName.set(frame.name, frame);
            }
        }

        frames.push(frame);
    }

    /**
     * Retrieves a specific frame by its name.
     */
    public inline function getFrameByName(name:String):TilesheetFrame {
        return framesByName.get(name);
    }

    /**
     * Retrieves a specific frame by its index.
     */
    public inline function getFrameByIndex(index:Int):TilesheetFrame {
        return frames[index];
    }

    /**
     * Gets the index of a given frame in the list.
     * @return The index of the frame, or -1 if it doesn't exist.
     */
    public function getIndexOfFrame(frame:TilesheetFrame):Int {
        return frames.indexOf(frame);
    }

    /**
     * Gets the index of a frame by its name.
     * @return The index of the frame, or -1 if it doesn't exist.
     */
    public function getIndexByName(name:String):Int {
        return frames.indexOf(framesByName.get(name));
    }

    /**
     * Gets the indices of a list of frames.
     * @return An array of indices, with the same length and order as the frames.
     *         If a frame doesn't exist, its index will be -1.
     */
    public function getIndicesOfFrames(frames:Array<TilesheetFrame>):Array<Int> {
        var result:Array<Int> = [];
        for (frame in frames) {
            result.push(getIndexOfFrame(frame));
        }
        return result;
    }

    /**
     * Gets an ordered list of frames whose names start with a given prefix.
     */
    public function getFramesByPrefix(prefix:String):Array<TilesheetFrame> {
        var result:Array<TilesheetFrame> = [];
        for (frame in frames) {
            if (StringTools.startsWith(frame.name, prefix)) {
                result.push(frame);
            }
        }
        return result;
    }

    public static function fromSparrow(textData:String):TilesheetFrameData {
        var xmlData:Access = new Access(Xml.parse(textData).firstElement());

        var textureWidth:Int = Std.parseInt(xmlData.att.width);
        var textureHeight:Int = Std.parseInt(xmlData.att.height);
        
        var result:TilesheetFrameData = new TilesheetFrameData(textureWidth, textureHeight);

        for (frame in xmlData.nodes.SubTexture) {
            var frameData:TilesheetFrame = {
                name: frame.att.name,
                x: Std.parseInt(frame.att.x),
                y: Std.parseInt(frame.att.y),
                width: Std.parseInt(frame.att.width),
                height: Std.parseInt(frame.att.height),
                frameX: 0,
                frameY: 0,
                frameWidth: 0,
                frameHeight: 0,
                flipX: false,
                flipY: false,
                angle: 0
            };

            if (frame.has.frameX) {
                frameData.frameX = Std.parseInt(frame.att.frameX);
                frameData.frameY = Std.parseInt(frame.att.frameY);
                frameData.frameWidth = Std.parseInt(frame.att.frameWidth);
                frameData.frameHeight = Std.parseInt(frame.att.frameHeight);
            } else {
                frameData.frameX = 0;
                frameData.frameY = 0;
                frameData.frameWidth = frameData.width;
                frameData.frameHeight = frameData.height;
            }
            
            if (frame.has.flipX) {
                frameData.flipX = Std.parseInt(frame.att.flipX) == 1;
            }
            
            if (frame.has.flipY) {
                frameData.flipY = Std.parseInt(frame.att.flipY) == 1;
            }

            if (frame.has.rotated && frame.att.rotated == "true") {
                frameData.angle = -90;
            }

            result.addFrame(frameData);
        }

        return result;
    }

    public static function fromGrid(width:Int, height:Int):TilesheetFrameData {
        // We don't know the actual texture width and height, so we make some up.
        var textureWidth:Int = width * 100;
        var textureHeight:Int = height * 100;

        var result:TilesheetFrameData = new TilesheetFrameData(textureWidth, textureHeight);

        for (i in 0...width) {
            for (j in 0...height) {
                var frame:TilesheetFrame = {
                    name: "frame_" + i + "_" + j,
                    x: i * 100,
                    y: j * 100,
                    width: 100,
                    height: 100,
                    frameX: 0,
                    frameY: 0,
                    frameWidth: 100,
                    frameHeight: 100,
                    angle: 0,
                    flipX: false,
                    flipY: false
                };
            
                result.addFrame(frame);
            }
        }

        return result;
    }
}

typedef TilesheetFrame = {
    /**
     * The name of the frame.
     */
    public var name:String;

    // The position and size of the frame to crop from the original image.

    /**
     * The x position where the source frame starts.
     */
    public var x:Int;
    /**
     * The y position where the source frame starts.
     */
    public var y:Int;
    /**
     * The width of the source frame.
     */
    public var width:Int;
    /**
     * The height of the source frame.
     */
    public var height:Int;

    // If the frame was cropped from the original image, these values will provide
    // the info needed to restore the original image.

    /**
     * The coordinate relative to x=0 where the image should start.
     * If the final image should show 10px of padding on the left, `frameX` will be -10.
     */
    public var frameX:Int;
    /**
     * The coordinate relative to y=0 where the image should start.
     * If the final image should show 10px of padding on the top, `frameY` will be -10.
     */
    public var frameY:Int;
    /**
     * The width of the final image.
     * If the final image should show 10px of padding on the right, `frameWidth` will be 10 higher than the width.
     */
    public var frameWidth:Int;
    /**
     * The height of the final image.
     * If the final image should show 10px of padding on the bottom, `frameHeight` will be 10 higher than the height.
     */
    public var frameHeight:Int;

    /**
     * Whether the frame should be flipped horizontally.
     */
    public var flipX:Bool;
    /**
     * Whether the frame should be flipped vertically.
     */
    public var flipY:Bool;

    /**
     * Rotation of the packed image.
     * Can be `0`, `90`, or `-90`.
     */
    public var angle:Float;
}