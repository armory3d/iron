package fox.trait;

import kha.math.Matrix4;
import kha.math.Vector3;
import fox.Root;
import fox.sys.Time;
import fox.core.Trait;
import fox.core.IUpdateable;
import fox.trait.Input;
import fox.trait.Transform;
import fox.trait.SceneRenderer;
import fox.trait.RigidBody;
import fox.trait.Camera;

class FirstPersonController extends Trait implements IUpdateable {

    @inject
    var transform:Transform;

    @inject
    var body:RigidBody;

    @inject({desc:true,sibl:false})
    var camera:Camera;

    @inject
    var input:Input;

    public function new() {
        super();
    }

    public function update() {

        if (input.touch) {

            // Look
            camera.pitch(-input.deltaY / 100);

            transform.rotateZ(-input.deltaX / 100);
            body.body.orientation.x = transform.rot.x;
            body.body.orientation.y = transform.rot.y;
            body.body.orientation.z = transform.rot.z;
            body.body.orientation.s = transform.rot.w;

            // Move
            var mat = Matrix4.identity();
            transform.rot.saveToMatrix2(mat);

            var forward = new Vector3(0, 1, 0);
            forward.applyProjection(mat);
            forward = forward.mult(fox.sys.Time.delta * 200);

            var force = new oimo.math.Vec3(forward.x, forward.y, forward.z);
            body.body.applyImpulse(body.body.position, force);
        }

        camera.updateMatrix();
    }
}
