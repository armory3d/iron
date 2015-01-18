package fox.trait;

import fox.core.IUpdateable;
import fox.core.Trait;
import fox.node.Node;

class NodeExecutor extends Trait implements IUpdateable {

    var node:Node;

    public function new() {
        super();
    }

    public function start(node:Node) {
        this.node = node;
    }

    public function update() {
        node.update();
    }
}
