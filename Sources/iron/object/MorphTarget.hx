package iron.object;

import kha.Image;
import kha.arrays.Float32Array;
import kha.FastFloat;
import iron.data.Data;
import iron.data.SceneFormat;

class MorphTarget{

    public var data: TMorphTarget;
    public var scaling: FastFloat;
    public var offset: FastFloat;
    public var morphWeights: Float32Array;
    public var morphDataPos: Image;
    public var morphDataNor: Image;
    public var morphMap: Map<String, Int> = null;

    public function new(data: TMorphTarget){
        trace('new Morph Target called');
        morphWeights = data.morph_target_defaults;
        scaling = data.morph_scale;
        offset = data.morph_offset;
        Data.getImage(data.morph_target_data_file + "_pos.png", function(img: Image){
            if(img != null) morphDataPos = img;
        });
        Data.getImage(data.morph_target_data_file + "_nor.png", function(img: Image){
            if(img != null) morphDataNor = img;
        });
        morphMap = new Map();

        var i = 0;
        for(name in data.morph_target_ref){
            morphMap.set(name, i);
            i++;
        }

    }

    public function setMorphValue(name: String, value: Float){
        var i = morphMap.get(name);
        if(i != null){
            morphWeights.set(i, value);
        }

    }

}