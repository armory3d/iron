package fox.trait;

import fox.math.Mat4;
import fox.math.Vec3;
import fox.Root;
import fox.sys.Time;
import fox.core.Trait;
import fox.core.IUpdateable;
import fox.trait.Input;
import fox.trait.Transform;
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

    var moveForward = false;
    var moveBackward = false;
    var moveLeft = false;
    var moveRight = false;
    var jump = false;

    public function new() {
        super();

        kha.input.Keyboard.get().notify(onDown, onUp);
    }

    function onDown(key: kha.Key, char: String) {
        if (char == "w") moveForward = true;
        else if (char == "d") moveRight = true;
        else if (char == "s") moveBackward = true;
        else if (char == "a") moveLeft = true;
        else if (char == "x") jump = true;
    }

    function onUp(key: kha.Key, char: String) {
        if (char == "w") moveForward = false;
        else if (char == "d") moveRight = false;
        else if (char == "s") moveBackward = false;
        else if (char == "a") moveLeft = false;
        else if (char == "x") jump = false;
    }

    var locked = true;

    public function update() {

        // Unlock
        if (locked &&
            input.x > Root.w / 2 - 20 && input.x < Root.w / 2 + 20 &&
            input.y > Root.h / 2 - 20 && input.y < Root.h / 2 +20) {
            locked = false;
        }

        // Look
        if (!locked) {
            camera.pitch(-input.deltaY / 100);

            transform.rotateZ(-input.deltaX / 100);
            //body.body.orientation.x = transform.rot.x;
            //body.body.orientation.y = transform.rot.y;
            //body.body.orientation.z = transform.rot.z;
            //body.body.orientation.s = transform.rot.w;
        }

        // Move
        if (moveForward) {
            var mat = new Mat4();
            transform.rot.saveToMatrix(mat);

            var forward = new Vec3(0, 1, 0);
            forward.applyProjection(mat);
            forward = forward.mult(fox.sys.Time.delta * 350);

            var force = new oimo.math.Vec3(forward.x, forward.y, forward.z);
            //body.body.applyImpulse(body.body.position, force);
        }

        if (moveBackward) {
            var mat = new Mat4();
            transform.rot.saveToMatrix(mat);

            var forward = new Vec3(0, -1, 0);
            forward.applyProjection(mat);
            forward = forward.mult(fox.sys.Time.delta * 350);

            var force = new oimo.math.Vec3(forward.x, forward.y, forward.z);
            //body.body.applyImpulse(body.body.position, force);
        }

        if (moveLeft) {
            var mat = new Mat4();
            transform.rot.saveToMatrix(mat);

            var forward = new Vec3(-1, 0, 0);
            forward.applyProjection(mat);
            forward = forward.mult(fox.sys.Time.delta * 350);

            var force = new oimo.math.Vec3(forward.x, forward.y, forward.z);
            //body.body.applyImpulse(body.body.position, force);
        }

        if (moveRight) {
            var mat = new Mat4();
            transform.rot.saveToMatrix(mat);

            var forward = new Vec3(1, 0, 0);
            forward.applyProjection(mat);
            forward = forward.mult(fox.sys.Time.delta * 350);

            var force = new oimo.math.Vec3(forward.x, forward.y, forward.z);
            //body.body.applyImpulse(body.body.position, force);
        }

        if (jump) {
            var mat = new Mat4();
            transform.rot.saveToMatrix(mat);

            var forward = new Vec3(0, 0, 1);
            forward.applyProjection(mat);
            forward = forward.mult(fox.sys.Time.delta * 350);

            var force = new oimo.math.Vec3(forward.x, forward.y, forward.z);
            //body.body.applyImpulse(body.body.position, force);
        }

        if (!moveForward && !moveBackward && !moveLeft && !moveRight && !jump) {
            var mat = new Mat4();
            transform.rot.saveToMatrix(mat);

            var forward = new Vec3(0, 0, -1);
            forward.applyProjection(mat);
            forward = forward.mult(fox.sys.Time.delta * 3000);

            var force = new oimo.math.Vec3(forward.x, forward.y, forward.z);
            //body.body.applyImpulse(body.body.position, force);
        }


        /*if (input.touch) {

            // Look
            camera.pitch(-input.deltaY / 100);

            transform.rotateZ(-input.deltaX / 100);
            body.body.orientation.x = transform.rot.x;
            body.body.orientation.y = transform.rot.y;
            body.body.orientation.z = transform.rot.z;
            body.body.orientation.s = transform.rot.w;

            // Move
            var mat = new Mat4();
            transform.rot.saveToMatrix(mat);

            var forward = new Vector3(0, 1, 0);
            forward.applyProjection(mat);
            forward = forward.mult(fox.sys.Time.delta * 200);

            var force = new oimo.math.Vec3(forward.x, forward.y, forward.z);
            body.body.applyImpulse(body.body.position, force);
        }*/

        camera.updateMatrix();
    }
}
