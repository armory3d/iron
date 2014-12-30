package fox.math;

import fox.Root;
import fox.trait.Camera;
import fox.trait.Transform;

class Helper {

    public static function perspective(fovY:Float, aspectRatio:Float, zNear:Float, zFar:Float):Mat4 {
        var f = 1.0 / Math.tan(fovY / 2);
        var t = 1.0 / (zNear - zFar);

        return new Mat4([f / aspectRatio, 0.0,      0.0,                   0.0,
                         0.0,             f,        0.0,                   0.0,
                         0.0,             0.0,      (zFar + zNear) * t,   -1.0,
                         0.0,             0.0,      2 * zFar * zNear * t , 0.0]);
    }

    public static function orthogonal(left: Float, right: Float, bottom: Float, top: Float, zn: Float, zf: Float): Mat4 {
        var tx: Float = -(right + left) / (right - left);
        var ty: Float = -(top + bottom) / (top - bottom);
        var tz: Float = -(zf + zn) / (zf - zn);
        //var tz : Float = -zn / (zf - zn);
        return new Mat4([
            2 / (right - left), 0,                  0,              0,
            0,                  2 / (top - bottom), 0,              0,
            0,                  0,                  -2 / (zf - zn), 0,
            tx,                 ty,                 tz,             1
        ]);
    }
    
    public static function lookAt(_eye:Vec3, _centre:Vec3, _up:Null<Vec3> = null):Mat4 {
        var eye = _eye;
        var centre = _centre;
        var up = _up;

        var e0 = eye.x;
        var e1 = eye.y;
        var e2 = eye.z;

        var u0 = (up == null ? 0 : up.x);
        var u1 = (up == null ? 1 : up.y);
        var u2 = (up == null ? 0 : up.z);

        var f0 = centre.x - e0;
        var f1 = centre.y - e1;
        var f2 = centre.z - e2;
        var n = 1 / Math.sqrt(f0 * f0 + f1 * f1 + f2 * f2);
        f0 *= n;
        f1 *= n;
        f2 *= n;

        var s0 = f1 * u2 - f2 * u1;
        var s1 = f2 * u0 - f0 * u2;
        var s2 = f0 * u1 - f1 * u0;
        n = 1 / Math.sqrt(s0 * s0 + s1 * s1 + s2 * s2);
        s0 *= n;
        s1 *= n;
        s2 *= n;

        u0 = s1 * f2 - s2 * f1;
        u1 = s2 * f0 - s0 * f2;
        u2 = s0 * f1 - s1 * f0;

        var d0 = -e0 * s0 - e1 * s1 - e2 * s2;
        var d1 = -e0 * u0 - e1 * u1 - e2 * u2;
        var d2 =  e0 * f0 + e1 * f1 + e2 * f2;

        return new Mat4([s0, u0,-f0, 0.0,
                         s1, u1,-f1, 0.0,
                         s2, u2,-f2, 0.0,
                         d0, d1, d2, 1.0]);
    }




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

        projectionMatrixInverse.getInverse(camera.projectionMatrix);
        viewMatrixInverse.getInverse(camera.viewMatrix);

        _viewProjectionMatrix.multiplyMatrices(viewMatrixInverse, projectionMatrixInverse);

        return vector.applyProjection(_viewProjectionMatrix);
    }

    static function pickingRay(vector:Vec3, camera:Camera):Ray {

        // set two vectors with opposing z values
        vector.z = -1.0;
        var end = new Vec3(vector.x, vector.y, 1.0);

        unprojectVector(vector, camera);
        unprojectVector(end, camera);

        // find direction from vector to end
        end.sub(vector);
        end.normalize2();

        // TODO: use kha vec
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
