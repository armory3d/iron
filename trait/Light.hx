package fox.trait;

import fox.core.Trait;

class Light extends Trait {

    @inject
    var transform:Transform;

    public function new() {
        super();
    }
}
