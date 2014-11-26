package fox.math;

import fox.Root;
import fox.trait.Camera;

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
        var v1 = new Vector3(vector.x, vector.y, vector.z);
        var v2 = new Vector3(end.x, end.y, end.z);
        return new Ray(v1, v2);
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

/*
    static var out_origin:Vector3D; // Ouput : Origin of the ray. /!\ Starts at the near plane, so if you want the ray to start at the camera's position instead, ignore this.
    static var out_direction:Vector3D; // Ouput : Direction, in world space, of the ray that goes "through" the mouse.
    public static function screenPosToWorldRay(
        mouseX:Int, mouseY:Int,             // Mouse position, in pixels, from bottom-left corner of the window
        screenWidth:Int, screenHeight:Int,  // Window size, in pixels
        ViewMatrix:Matrix3D,               // Camera position and orientation
        ProjectionMatrix:Matrix3D         // Camera parameters (ratio, field of view, near and far planes)       
    ){

        // The ray Start and End positions, in Normalized Device Coordinates (Have you read Tutorial 4 ?)
        var lRayStart_NDC:Vector3D = new Vector3D(
            (mouseX / screenWidth  - 0.5) * 2.0, // [0,1024] -> [-1,1]
            (mouseY / screenHeight - 0.5) * 2.0, // [0, 768] -> [-1,1]
            -1.0, // The near plane maps to Z=-1 in Normalized Device Coordinates
            1.0
        );

        var lRayEnd_NDC:Vector3D = new Vector3D(
            (mouseX / screenWidth  - 0.5) * 2.0,
            (mouseY / screenHeight - 0.5) * 2.0,
            0.0,
            1.0
        );

        //lRayStart_NDC.y *= -1;
        //lRayEnd_NDC.y *= -1;
        //trace("ray start: " + lRayStart_NDC);
        //trace("ray end: " + lRayEnd_NDC);

        // The Projection matrix goes from Camera Space to NDC.
        // So inverse(ProjectionMatrix) goes from NDC to Camera Space.
        var InverseProjectionMatrix:Matrix3D = ProjectionMatrix.clone();
        InverseProjectionMatrix.invert();
        
        // The View Matrix goes from World Space to Camera Space.
        // So inverse(ViewMatrix) goes from Camera Space to World Space.
        // var InverseViewMatrix:Matrix3D = ViewMatrix.clone();
        // InverseViewMatrix.invert();
        
        // var lRayStart_camera:Vector3D = InverseProjectionMatrix.multiplyByVector(lRayStart_NDC);
        // lRayStart_camera.divideBy(lRayStart_camera.w);

        // var lRayStart_world:Vector3D = InverseViewMatrix.multiplyByVector(lRayStart_camera);
        // lRayStart_world.divideBy(lRayStart_world.w);

        // var lRayEnd_camera:Vector3D = InverseProjectionMatrix.multiplyByVector(lRayEnd_NDC);
        // lRayEnd_camera.divideBy(lRayEnd_camera.w);

        // var lRayEnd_world:Vector3D = InverseViewMatrix.multiplyByVector(lRayEnd_camera);
        // lRayEnd_world.divideBy(lRayEnd_world.w);


        // Faster way (just one inverse)
        var M:Matrix3D = ProjectionMatrix.clone();
        M.append(ViewMatrix);
        M.invert();

        var lRayStart_world:Vector3D = M.multiplyByVector(lRayStart_NDC);
        lRayStart_world.divideBy(lRayStart_world.w);

        var lRayEnd_world:Vector3D = M.multiplyByVector(lRayEnd_NDC);
        lRayEnd_world.divideBy(lRayEnd_world.w);
        //glm::mat4 M = glm::inverse(ProjectionMatrix * ViewMatrix);
        //glm::vec4 lRayStart_world = M * lRayStart_NDC; lRayStart_world/=lRayStart_world.w;
        //glm::vec4 lRayEnd_world   = M * lRayEnd_NDC  ; lRayEnd_world  /=lRayEnd_world.w;


        var lRayDir_world:Vector3D = lRayEnd_world.clone();
        lRayDir_world.decrementBy(lRayStart_world);
        lRayDir_world.normalize();


        out_origin = lRayStart_world;

        lRayDir_world.normalize();
        out_direction = lRayDir_world;
    }

    
    public static function pick(camera:Camera, model:Model):Bool {
        screenPosToWorldRay(Std.int(Input.x), Std.int(Input.y), Root.w, Root.h,
                            camera.viewMatrix, camera.projectionMatrix);

        //trace("dir: " + out_direction);
        //trace("origin: " + out_origin);

        return testRayOBBIntersection(model.mesh.aabbMin, model.mesh.aabbMax,
                                      model.modelMatrix);
    }








    static var intersection_distance:Float;
    public static function testRayOBBIntersection(
        // Ray origin, in world space
        // Ray direction (NOT target position!), in world space. Must be normalize()'d.
        aabb_min:Vector3D,          // Minimum X,Y,Z coords of the mesh when not transformed at all.
        aabb_max:Vector3D,          // Maximum X,Y,Z coords. Often aabb_min*-1 if your mesh is centered, but it's not always the case.
        ModelMatrix:Matrix3D       // Transformation applied to the mesh (which will thus be also applied to its bounding box)
        // Output : distance between ray_origin and the intersection with the OBB
    ):Bool {
        
        // Intersection method from Real-Time Rendering and Essential Mathematics for Games
        
        var tMin:Float = 0.0;
        var tMax:Float = 100000.0;

        var OBBposition_worldspace:Vector3D = new Vector3D(ModelMatrix.rawData[12], ModelMatrix.rawData[13], ModelMatrix.rawData[14]);

        var delta:Vector3D = OBBposition_worldspace.clone();
        //delta.decrementBy(out_origin);

        // Test intersection with the 2 planes perpendicular to the OBB's X axis
        {
            var xaxis:Vector3D = new Vector3D(ModelMatrix.rawData[0], ModelMatrix.rawData[1], ModelMatrix.rawData[2]);
            //var xaxis:Vector3D = new Vector3D(ModelMatrix.rawData[0], ModelMatrix.rawData[4], ModelMatrix.rawData[8]);
            var e:Float = xaxis.dotProduct(delta);
            var f:Float = out_direction.dotProduct(xaxis);

            trace(xaxis + "," + e + "," + f);

            if (Math.abs(f) > 0.001) { // Standard case

                var t1:Float = (e + aabb_min.x) / f; // Intersection with the "left" plane
                var t2:Float = (e + aabb_max.x) / f; // Intersection with the "right" plane
                // t1 and t2 now contain distances betwen ray origin and ray-plane intersections

                // We want t1 to represent the nearest intersection, 
                // so if it's not the case, invert t1 and t2
                if (t1 > t2) { var w:Float = t1; t1 = t2; t2 = w; } // swap t1 and t2

                // tMax is the nearest "far" intersection (amongst the X,Y and Z planes pairs)
                if (t2 < tMax)
                    tMax = t2;
                // tMin is the farthest "near" intersection (amongst the X,Y and Z planes pairs)
                if (t1 > tMin)
                    tMin = t1;

                // And here's the trick :
                // If "far" is closer than "near", then there is NO intersection.
                // See the images in the tutorials for the visual explanation.
                if (tMax < tMin)
                    return false;

            }
            else { // Rare case : the ray is almost parallel to the planes, so they don't have any "intersection"
                if (-e + aabb_min.x > 0.0 || -e + aabb_max.x < 0.0)
                    return false;
            }
        }


        // Test intersection with the 2 planes perpendicular to the OBB's Y axis
        // Exactly the same thing than above.
        {
            var yaxis:Vector3D = new Vector3D(ModelMatrix.rawData[4], ModelMatrix.rawData[5], ModelMatrix.rawData[6]);
            //var yaxis:Vector3D = new Vector3D(ModelMatrix.rawData[1], ModelMatrix.rawData[5], ModelMatrix.rawData[9]);
            var e:Float = yaxis.dotProduct(delta);
            var f:Float = out_direction.dotProduct(yaxis);

            trace(yaxis + "," + e + "," + f);

            if (Math.abs(f) > 0.001) {

                var t1:Float = (e + aabb_min.y) / f;
                var t2:Float = (e + aabb_max.y) / f;

                if (t1 > t2) { var w:Float = t1; t1 = t2; t2 = w; }

                if (t2 < tMax)
                    tMax = t2;
                if (t1 > tMin)
                    tMin = t1;
                if (tMin > tMax)
                    return false;

            }
            else {
                if (-e + aabb_min.y > 0.0 || -e + aabb_max.y < 0.0)
                    return false;
            }
        }


        // Test intersection with the 2 planes perpendicular to the OBB's Z axis
        // Exactly the same thing than above.
        {
            var zaxis:Vector3D = new Vector3D(ModelMatrix.rawData[8], ModelMatrix.rawData[9], ModelMatrix.rawData[10]);
            //var zaxis:Vector3D = new Vector3D(ModelMatrix.rawData[2], ModelMatrix.rawData[6], ModelMatrix.rawData[10]);
            var e:Float = zaxis.dotProduct(delta);
            var f:Float = out_direction.dotProduct(zaxis);

            trace(zaxis + "," + e + "," + f);

            if (Math.abs(f) > 0.001) {

                var t1:Float = (e + aabb_min.z) / f;
                var t2:Float = (e + aabb_max.z) / f;

                if (t1 > t2) { var w:Float = t1; t1 = t2; t2 = w; }

                if (t2 < tMax)
                    tMax = t2;
                if (t1 > tMin)
                    tMin = t1;
                if (tMin > tMax)
                    return false;

            }
            else {
                if (-e + aabb_min.z > 0.0 || -e + aabb_max.z < 0.0)
                    return false;
            }
        }

        intersection_distance = tMin;
        return true;
    }
    */
}
