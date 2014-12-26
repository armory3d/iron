package fox.trait;

import fox.core.Trait;
import fox.Root;
import fox.trait.Transform;

class SceneInstance extends Trait {

    var transform:Transform;

    public function new() {
        super();
    }

    @injectAdd
    function addTransform(trait:Transform) {
    	transform = trait;
    	
    	var o = Root.addScene("Zanim");
        o.transform.x = transform.x;
        o.transform.y = transform.y;
        o.transform.z = transform.z;

        trace(o.transform.x, o.transform.y, o.transform.z);
    }
}
