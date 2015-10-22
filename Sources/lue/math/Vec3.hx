package lue.math;

// https://github.com/mrdoob/three.js/

class Vec3 {

    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var w:Float;

    static var Vec3_tangents_n = new Vec3();
    static var Vec3_tangents_randVec = new Vec3();

    public function new(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0, w:Float = 1) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    // Vector cross product
    public function cross(v:Vec3, target:Vec3 = null):Vec3 {
        var vx:Float = v.x; var vy:Float = v.y; var vz:Float = v.z; var x:Float = this.x; var y:Float = this.y; var z:Float = this.z;
        if (target == null) target = new Vec3();

        target.x = (y * vz) - (z * vy);
        target.y = (z * vx) - (x * vz);
        target.z = (x * vy) - (y * vx);

        return target;
    }

    public function cross2(v:Vec3):Vec3 {
        x = y * v.z - z * v.y;
        y = z * v.x - x * v.z;
        z = x * v.y - y * v.x;
        return this;
    }

    public function crossVectors(a:Vec3, b:Vec3):Vec3 {
        x = a.y * b.z - a.z * b.y;
        y = a.z * b.x - a.x * b.z;
        z = a.x * b.y - a.y * b.x;
        return this;
    }

    public function equals(v:Vec3):Bool {
        return ((x == v.x) && (y == v.y) && (z == v.z));
    }

    // Set the vectors' 3 elements
    public function set(x:Float, y:Float, z:Float):Vec3{
        this.x = x;
        this.y = y;
        this.z = z;
        return this;
    }

    // Vector addition
    public function vadd(v:Vec3, target:Vec3 = null):Vec3 {
        if(target != null) {
            target.x = v.x + this.x;
            target.y = v.y + this.y;
            target.z = v.z + this.z;
            return target;
        }
        else {
            return new Vec3(this.x + v.x,
                            this.y + v.y,
                            this.z + v.z);
        }
    }

    public function add(v:Vec3):Vec3 {
        x += v.x;
        y += v.y;
        z += v.z;

        return this;
    }

    public function addVectors(a:Vec3, b:Vec3):Vec3 {
        x = a.x + b.x;
        y = a.y + b.y;
        z = a.z + b.z;
        return this;
    } 

    // Vector subtraction
    public function vsub(v:Vec3, target:Vec3 = null):Vec3 {
        if (target != null) {
            target.x = this.x - v.x;
            target.y = this.y - v.y;
            target.z = this.z - v.z;
            return target;
        }
        else {
            return new Vec3(this.x-v.x,
                            this.y-v.y,
                            this.z-v.z);
        }
    }

    public function subVectors(a:Vec3, b:Vec3):Vec3 {
        x = a.x - b.x;
        y = a.y - b.y;
        z = a.z - b.z;
        return this;
    }   

    // Normalize the vector
    // Returns the norm of the vector
    public function normalize():Float {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        var n = std.Math.sqrt(x * x + y * y + z * z);
        if (n > 0.0) {
            var invN:Float = 1 / n;
            this.x *= invN;
            this.y *= invN;
            this.z *= invN;
        }
        else {
            // Make something up
            this.x = 0;
            this.y = 0;
            this.z = 0;
        }
        return n;
    }

    // Get the version of this vector that is of length 1.
    // Returns the unit vector
    public function unit(target:Vec3):Vec3 {
        if (target == null) target = new Vec3();
        var x:Float = this.x; var y:Float = this.y; var z:Float = this.z;
        var ninv:Float = std.Math.sqrt(x*x + y*y + z*z);
        if (ninv > 0.0) {
            ninv = 1.0 / ninv;
            target.x = x * ninv;
            target.y = y * ninv;
            target.z = z * ninv;
        }
        else {
            target.x = 1;
            target.y = 0;
            target.z = 0;
        }
        return target;
    }

    // Get the 2-norm (length) of the vector
    public function norm():Float {
        var x:Float = this.x; var y:Float = this.y; var z:Float = this.z;
        return std.Math.sqrt(x * x + y * y + z * z);
    }

    // Get the squared length of the vector
    public function norm2():Float {
        return this.dot(this);
    }

    public function distanceTo(p:Vec3):Float {
        var x:Float = this.x; var y:Float = this.y; var z:Float = this.z;
        var px:Float = p.x; var py:Float = p.y; var pz:Float = p.z;
        return std.Math.sqrt((px - x) * (px - x) +
                         (py - y) * (py - y) +
                         (pz - z) * (pz - z));
    }

    // Multiply the vector with a scalar
    public function mult(scalar:Float, target:Vec3 = null):Vec3 {
        if (target == null) target = new Vec3();
        var x:Float = this.x;
        var y:Float = this.y;
        var z:Float = this.z;
        target.x = scalar * x;
        target.y = scalar * y;
        target.z = scalar * z;
        return target;
    }

    public function multiplyScalar(scalar:Float):Vec3 {
        x *= scalar;
        y *= scalar;
        z *= scalar;
        return this;
    }

    // Calculate dot product
    public function dot(v:Vec3):Float {
        return this.x * v.x + this.y * v.y + this.z * v.z;
    }

    public function isZero():Bool {
        return this.x == 0 && this.y == 0 && this.z == 0;
    }

    // Make the vector point in the opposite direction.
    public function negate(target:Vec3 = null):Vec3 {
        if (target == null) target = new Vec3();
        target.x = -this.x;
        target.y = -this.y;
        target.z = -this.z;
        return target;
    }

    // Compute two artificial tangents to the vector
    // t1 Vector object to save the first tangent in
    // t2 Vector object to save the second tangent in
    public function tangents(t1:Vec3, t2:Vec3) {
        var norm:Float = this.norm();
        if (norm > 0.0) {
            var n = Vec3_tangents_n;
            var inorm:Float = 1 / norm;
            n.set(this.x * inorm, this.y * inorm, this.z * inorm);
            var randVec = Vec3_tangents_randVec;
            if (std.Math.abs(n.x) < 0.9) {
                randVec.set(1, 0, 0);
                n.cross(randVec, t1);
            }
            else {
                randVec.set(0, 1, 0);
                n.cross(randVec, t1);
            }
            n.cross(t1, t2);
        } else {
            // The normal length is zero, make something up
            t1.set(1, 0, 0).normalize();
            t2.set(0, 1, 0).normalize();
        }
    }

    public function toString():String {
        return this.x + "," + this.y + "," + this.z;
    }

    // Copy the vector.
    public function copy(target:Vec3):Vec3 {
        if (target == null) target = new Vec3();
        target.x = this.x;
        target.y = this.y;
        target.z = this.z;
        return target;
    }

    public function copy2(v:Vec3):Vec3 {
        x = v.x;
        y = v.y;
        z = v.z;
        return this;
    }   

    public function clone():Vec3 {
        return new Vec3(x, y, z);
    }

    // Do a linear interpolation between two vectors
    // t A number between 0 and 1. 0 will make this function return u, and 1 will make it return v. Numbers in between will generate a vector in between them.
    public static function lerp(va:Vec3, vb:Vec3, t:Float) {
        var target = new Vec3();
        target.x = vb.x + (va.x - vb.x) * t;
        target.y = vb.y + (va.y - vb.y) * t;
        target.z = vb.z + (va.z - vb.z) * t;
        return target;
    }

    // Check if a vector equals is almost equal to another one.
    public function almostEquals(v:Vec3, precision:Float = -1.0):Bool {
        if (precision < -0.99) {
            precision = 1e-6;
        }
        if (std.Math.abs(this.x-v.x)>precision ||
            std.Math.abs(this.y-v.y)>precision ||
            std.Math.abs(this.z-v.z)>precision) {
            return false;
        }
        return true;
    }

    // Check if a vector is almost zero
    public function almostZero(v:Vec3):Bool {
        var precision:Float = 1e-6; 
        if (std.Math.abs(this.x)>precision ||
            std.Math.abs(this.y)>precision ||
            std.Math.abs(this.z)>precision){
            return false;
        }
        return true;
    }

    // Extended
    public function applyProjection(m:Mat4):Vec3 {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        var e = m.getFloats();

        // Perspective divide
        var d = 1 / (e[3] * x + e[7] * y + e[11] * z + e[15]);

        this.x = (e[0] * x + e[4] * y + e[8]  * z + e[12]) * d;
        this.y = (e[1] * x + e[5] * y + e[9]  * z + e[13]) * d;
        this.z = (e[2] * x + e[6] * y + e[10] * z + e[14]) * d;

        return this;
    }

    public function applyMat4(m:Mat4):Vec3 {
        var x = this.x;
        var y = this.y;
        var z = this.z;
        var e = m.getFloats();

        this.x = e[0] * x + e[4] * y + e[8]  * z + e[12];
        this.y = e[1] * x + e[5] * y + e[9]  * z + e[13];
        this.z = e[2] * x + e[6] * y + e[10] * z + e[14];

        return this;
    }   

    public function normalize2():Vec3 {
        return this.divideScalar(this.length());
    }

    public function divideScalar(scalar:Float):Vec3 {
        if (scalar != 0) {
            var invScalar = 1 / scalar;

            this.x *= invScalar;
            this.y *= invScalar;
            this.z *= invScalar;

        }
        else {
            this.x = 0;
            this.y = 0;
            this.z = 0;
        }

        return this;
    }

    public function length() {
        return std.Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
    }

    public function lengthSq():Float {
        return x * x + y * y + z * z;
    }


    public function sub(v:Vec3):Vec3 {
        this.x -= v.x;
        this.y -= v.y;
        this.z -= v.z;

        return this;
    }

    public function getXYZ():Vec3 {
        return new Vec3(x, y, z);
    }

    public function min(v:Vec3):Vec3 {
        if (x > v.x) x = v.x;
        if (y > v.y) y = v.y;
        if (z > v.z) z = v.z;
        return this;
    }   
    
    public function max(v:Vec3):Vec3 {
        if (x < v.x) x = v.x;
        if (y < v.y) y = v.y;
        if (z < v.z) z = v.z;
        return this;
    }   
    
    public function clamp(vmin:Vec3, vmax:Vec3):Vec3 {
        // This function assumes min < max, if this assumption isn't true it will not operate correctly
        if (x < vmin.x) x = vmin.x; else if (x > vmax.x) x = vmax.x;
        if (y < vmin.y) y = vmin.y; else if (y > vmax.y) y = vmax.y;
        if (z < vmin.z) z = vmin.z; else if (z > vmax.z) z = vmax.z;
        return this;
    }

    public function addScalar(s:Float):Vec3 {
        x += s;
        y += s;
        z += s;
        return this;
    }

    public function distanceToSquared(v:Vec3):Float {
        var dx = x - v.x;
        var dy = y - v.y;
        var dz = z - v.z;
        return dx * dx + dy * dy + dz * dz;
    }

    public function unproject(P:Mat4, V:Mat4):Vec3 {
        var VPInv = new Mat4();
        var PInv = new Mat4();
        var VInv = new Mat4();

        PInv.getInverse(P);
        VInv.getInverse(V);

        VPInv.multiplyMatrices(VInv, PInv);

        return this.applyProjection(VPInv);
    }
}
