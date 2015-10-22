package lue.math;

import lue.App;
import lue.node.CameraNode;
import lue.node.Transform;

class RayCaster {

    public static function getRay(inputX:Float, inputY:Float, camera:CameraNode):Ray {

        var start = new Vec3();
        var end = new Vec3();

        getDirection(start, end, inputX, inputY, camera);

        return new Ray(start, end);
    }


    public static function getDirection(start:Vec3, end:Vec3, inputX:Float, inputY:Float, camera:CameraNode) {
        // TODO: return end only
        // TODO: speed up using http://halogenica.net/ray-casting-and-picking-using-bullet-physics/

        // Get 3D point form screen coords
        start.x =  (inputX / App.w) * 2 - 1;
        start.y = -(inputY / App.h) * 2 + 1;

        // Set two vectors with opposing z values
        start.z = -1.0;
        end.x = start.x;
        end.y = start.y;
        end.z = 0.0;

        start.unproject(camera.P, camera.V);
        end.unproject(camera.P, camera.V);

        // Find direction from start to end
        end.sub(start);
        end.normalize2();

        end.x *= camera.resource.resource.far_plane;
        end.y *= camera.resource.resource.far_plane;
        end.z *= camera.resource.resource.far_plane;
    }


    public static function getIntersect(transform:Transform, inputX:Float, inputY:Float, camera:CameraNode):Vec3 {
        var ray = getRay(inputX, inputY, camera);

        var t = transform;
        var c = new Vec3(t.absx(), t.absy(), t.absz());
        var s = new Vec3(t.size.x, t.size.y, t.size.z);

        var box = new Box3();
        box.setFromCenterAndSize(c, s);

        return ray.intersectBox(box);
    }

    public static function getClosestIntersect(transforms:Array<Transform>, inputX:Float, inputY:Float, camera:CameraNode):Transform {
        var intersects:Array<Transform> = [];

        // Get intersects
        for (t in transforms) {
            var intersect = getIntersect(t, inputX, inputY, camera);
            if (intersect != null) intersects.push(t);
        }

        // No intersects
        if (intersects.length == 0) return null;

        // Get closest intersect
        var closest:Transform = null;
        var minDist:Float = std.Math.POSITIVE_INFINITY;
        for (t in intersects) {
            var dist = lue.math.Math.distance3d(t.pos, camera.transform.pos);
            if (dist < minDist) {
                minDist = dist;
                closest = t;
            }
        }

        return closest;
    }

    public static function getIntersectPlane(normal:Vec3, a:Vec3, inputX:Float, inputY:Float, camera:CameraNode):Vec3 {
        var ray = getRay(inputX, inputY, camera);

        var plane = new Plane();
        plane.setFromNormalAndCoplanarPoint(normal, a);

        return ray.intersectPlane(plane);
    }
}
