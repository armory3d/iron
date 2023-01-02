package iron.object.tilesheet;

import haxe.xml.Access;
import iron.data.SceneFormat.TTilesheetAction;
import iron.object.tilesheet.TilesheetFrameData.TilesheetFrame;

class TilesheetActionData {
    private var parent:TilesheetFrameData;

    private var actionMap:Map<String, TilesheetAction> = new Map<String, TilesheetAction>();

    public function new() {}

    public function getAction(name:String):TilesheetAction {
        return actionMap.get(name);
    }

    public function addAction(action:TilesheetAction):Void {
        if (action == null) return;

        actionMap.set(action.name, action);
    }

    public static function fromGrid(frameData:TilesheetFrameData, rawActions:Array<TTilesheetAction>) {
        var actionData:TilesheetActionData = new TilesheetActionData();

        for (rawAction in rawActions) {
            var action:TilesheetAction = {
                name: rawAction.name,
                loop: rawAction.loop,
                raw: rawAction,
                frames: []
            };

            if (rawAction.start < rawAction.end) {
                for (i in rawAction.start...(rawAction.end + 1)) {
                    action.frames.push(frameData.getFrameByIndex(i));
                }
            }

            actionData.addAction(action);
        }

        return actionData;
    }

    public static function fromSparrow(frameData:TilesheetFrameData, rawActions:Array<TTilesheetAction>) {
        var actionData:TilesheetActionData = new TilesheetActionData();

        for (rawAction in rawActions) {
            var action:TilesheetAction = {
                name: rawAction.name,
                loop: rawAction.loop,
                raw: rawAction,
                frames: frameData.getFramesByPrefix(rawAction.prefix)
            };

            if (action.frames.length == 0) {
                trace('[WARNING] No frames found for action (${action.name}). Did you specify the correct prefix?');
                continue;
            }

            actionData.addAction(action);
        }

        return actionData;
    }
}

typedef TilesheetAction = {
    /**
     * The name of the action.
     */
    public var name:String;

    /**
     * An array of frames from the TilesheetFrameData, which the action should reference, in order.
     */
     public var frames:Array<TilesheetFrame>;

    /**
     * Whether the action should loop continuously on completion,
     * or stop on the last frame.
     */
    public var loop:Bool;

    public var raw:TTilesheetAction;
}