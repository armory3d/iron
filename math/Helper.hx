package fox.math;

import fox.Root;
import fox.trait.Camera;
import fox.trait.Transform;

using Math;

class Helper {

    public static function getRay(touchX:Float, touchY:Float, camera:Camera):Ray {
        var mouse3D = new Vec3();

        // Get 3D point form the client x y
        mouse3D.x = (touchX / Root.w) * 2 - 1;
        mouse3D.y = -(touchY / Root.h) * 2 + 1;
        mouse3D.z = 0.5;

        return pickingRay(mouse3D, camera);
    }


    static function unprojectVector(vector:Vec3, camera:Camera):Vec3 {
        var _viewProjectionMatrix = new Mat4();
        var projectionMatrixInverse = new Mat4();
        var viewMatrixInverse = new Mat4();

        projectionMatrixInverse.getInverse(camera.P);
        viewMatrixInverse.getInverse(camera.V);

        _viewProjectionMatrix.multiplyMatrices(viewMatrixInverse, projectionMatrixInverse);

        return vector.applyProjection(_viewProjectionMatrix);
    }


    static function pickingRay(vector:Vec3, camera:Camera):Ray {

        // Set two vectors with opposing z values
        vector.z = -1.0;
        var end = new Vec3(vector.x, vector.y, 1.0);

        unprojectVector(vector, camera);
        unprojectVector(end, camera);

        // Find direction from vector to end
        end.sub(vector);
        end.normalize2();

        var v1 = new Vec3(vector.x, vector.y, vector.z);
        var v2 = new Vec3(end.x, end.y, end.z);
        return new Ray(v1, v2);
    }

    public static function getIntersect(transform:Transform, inputX:Float, inputY:Float, camera:Camera):Vec3 {
        var ray = getRay(inputX, inputY, camera);

        var t = transform;
        var c = new Vec3(t.absx, t.absy, t.absz);
        var s = new Vec3(t.size.x, t.size.y, t.size.z);

        var box = new Box3();
        box.setFromCenterAndSize(c, s);

        return ray.intersectBox(box);
    }

    public static inline function distance1d(x1:Float, x2:Float) {
        return Math.abs(x2 - x1);
    }

    public static function distance2d(x1:Float, y1:Float, x2:Float, y2:Float):Float {
        return Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
    }

    public static function distance3d(v1:Vec3, v2:Vec3):Float {
        var vx = v1.x - v2.x;
        var vy = v1.y - v2.y;
        var vz = v1.z - v2.z;
        return Math.sqrt(vx * vx + vy * vy + vz * vz);
    }

    public static function planeDotCoord(planeNormal:Vec3, point:Vec3, planeDistance:Float):Float {
        // Point is in front of plane if > 0
        return planeNormal.dot(point) + planeDistance;
    }
}
