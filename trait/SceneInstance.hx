package fox.trait;

import fox.core.Trait;
import fox.Root;
import fox.trait.Transform;

class SceneInstance extends Trait {

    var transform:Transform;
    var sceneName:String;

    public function new(sceneName:String) {
        super();

        this.sceneName = sceneName;
    }

    @injectAdd
    function addTransform(trait:Transform) {
    	transform = trait;
    	
    	var o = Root.addScene(sceneName);
        o.transform.x = transform.x;
        o.transform.y = transform.y;
        o.transform.z = transform.z;
    }
}
