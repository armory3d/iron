package iron.math;

// #if WITH_EXPOSE
@:expose
// #end
class Vec4 {

    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var w:Float;

    public function new(x:Float = 0.0, y:Float = 0.0, z:Float = 0.0, w:Float = 1) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    public function cross(v:Vec4, target:Vec4 = null):Vec4 {
        var vx:Float = v.x; var vy:Float = v.y; var vz:Float = v.z; var x:Float = this.x; var y:Float = this.y; var z:Float = this.z;
        if (target == null) target = new Vec4();

        target.x = (y * vz) - (z * vy);
        target.y = (z * vx) - (x * vz);
        target.z = (x * vy) - (y * vx);

        return target;
    }

    public function cross2(v:Vec4):Vec4 {
        var _x = y * v.z - z * v.y;
        var _y = z * v.x - x * v.z;
        var _z = x * v.y - y * v.x;
		x = _x;
		y = _y;
		z = _z;
        return this;
    }

    public function crossVectors(a:Vec4, b:Vec4):Vec4 {
        x = a.y * b.z - a.z * b.y;
        y = a.z * b.x - a.x * b.z;
        z = a.x * b.y - a.y * b.x;
        return this;
    }

    public function equals(v:Vec4):Bool {
        return ((x == v.x) && (y == v.y) && (z == v.z));
    }

    public function set(x:Float, y:Float, z:Float):Vec4{
        this.x = x;
        this.y = y;
        this.z = z;
        return this;
    }

    public function vadd(v:Vec4, target:Vec4 = null):Vec4 {
        if(target != null) {
            target.x = v.x + this.x;
            target.y = v.y + this.y;
            target.z = v.z + this.z;
            return target;
        }
        else {
            return new Vec4(this.x + v.x,
                            this.y + v.y,
                            this.z + v.z);
        }
    }

    public function add(v:Vec4):Vec4 {
        x += v.x;
        y += v.y;
        z += v.z;

        return this;
    }

    public function addVectors(a:Vec4, b:Vec4):Vec4 {
        x = a.x + b.x;
        y = a.y + b.y;
        z = a.z + b.z;
        return this;
    } 

    public function vsub(v:Vec4, target:Vec4 = null):Vec4 {
        if (target != null) {
            target.x = this.x - v.x;
            target.y = this.y - v.y;
            target.z = this.z - v.z;
            return target;
        }
        else {
            return new Vec4(this.x-v.x,
                            this.y-v.y,
                            this.z-v.z);
        }
    }

    public function subVectors(a:Vec4, b:Vec4):Vec4 {
        x = a.x - b.x;
        y = a.y - b.y;
        z = a.z - b.z;
        return this;
    }   

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

    // Get the 2-norm (length) of the vector
    public function norm():Float {
        var x:Float = this.x; var y:Float = this.y; var z:Float = this.z;
        return std.Math.sqrt(x * x + y * y + z * z);
    }

    public function distanceTo(p:Vec4):Float {
        var x:Float = this.x; var y:Float = this.y; var z:Float = this.z;
        var px:Float = p.x; var py:Float = p.y; var pz:Float = p.z;
        return std.Math.sqrt((px - x) * (px - x) +
                         (py - y) * (py - y) +
                         (pz - z) * (pz - z));
    }

    // Multiply the vector with a scalar
    public function mult(scalar:Float, target:Vec4 = null):Vec4 {
        if (target == null) target = new Vec4();
        var x:Float = this.x;
        var y:Float = this.y;
        var z:Float = this.z;
        target.x = scalar * x;
        target.y = scalar * y;
        target.z = scalar * z;
        return target;
    }

    public function multiplyScalar(scalar:Float):Vec4 {
        x *= scalar;
        y *= scalar;
        z *= scalar;
        return this;
    }

    public function dot(v:Vec4):Float {
        return this.x * v.x + this.y * v.y + this.z * v.z;
    }

    public function toString():String {
        return this.x + "," + this.y + "," + this.z;
    }

    public function copy(target:Vec4):Vec4 {
        if (target == null) target = new Vec4();
        target.x = this.x;
        target.y = this.y;
        target.z = this.z;
        return target;
    }

    public function copy2(v:Vec4):Vec4 {
        x = v.x;
        y = v.y;
        z = v.z;
        return this;
    }   

    public function clone():Vec4 {
        return new Vec4(x, y, z);
    }

    // Do a linear interpolation between two vectors
    // t A number between 0 and 1. 0 will make this function return u, and 1 will make it return v. Numbers in between will generate a vector in between them.
    public static function lerp(va:Vec4, vb:Vec4, t:Float) {
        var target = new Vec4();
        target.x = vb.x + (va.x - vb.x) * t;
        target.y = vb.y + (va.y - vb.y) * t;
        target.z = vb.z + (va.z - vb.z) * t;
        return target;
    }

    public function applyProjection(m:Mat4):Vec4 {
        var x = this.x;
        var y = this.y;
        var z = this.z;

        // Perspective divide
        var d = 1 / (m._03 * x + m._13 * y + m._23 * z + m._33);

        this.x = (m._00 * x + m._10 * y + m._20 * z + m._30) * d;
        this.y = (m._01 * x + m._11 * y + m._21 * z + m._31) * d;
        this.z = (m._02 * x + m._12 * y + m._22 * z + m._32) * d;

        return this;
    }

    public function applyMat4(m:Mat4):Vec4 {
        var x = this.x;
        var y = this.y;
        var z = this.z;

        this.x = (m._00 * x + m._10 * y + m._20 * z + m._30);
        this.y = (m._01 * x + m._11 * y + m._21 * z + m._31);
        this.z = (m._02 * x + m._12 * y + m._22 * z + m._32);

        return this;
    }   

    public function normalize2():Vec4 {
        return this.divideScalar(this.length());
    }

    public function divideScalar(scalar:Float):Vec4 {
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

    public function sub(v:Vec4):Vec4 {
        this.x -= v.x;
        this.y -= v.y;
        this.z -= v.z;

        return this;
    } 

    public function addScalar(s:Float):Vec4 {
        x += s;
        y += s;
        z += s;
        return this;
    }

    public function unproject(P:Mat4, V:Mat4):Vec4 {
        var VPInv = Mat4.identity();
        var PInv = Mat4.identity();
        var VInv = Mat4.identity();

        PInv.getInverse(P);
        VInv.getInverse(V);

        VPInv.multiplyMatrices(VInv, PInv);

        return this.applyProjection(VPInv);
    }

    public static function xAxis():Vec4 {
        return new Vec4(1, 0, 0);
    }

    public static function yAxis():Vec4 {
        return new Vec4(0, 1, 0);
    }

    public static function zAxis():Vec4 {
        return new Vec4(0, 0, 1);
    }

    public static inline function distance3d(v1:Vec4, v2:Vec4):Float {
        return distance3dRaw(v1.x, v1.y, v1.z, v2.x, v2.y, v2.z);
    }

    public static inline function distance3dRaw(v1x:Float, v1y:Float, v1z:Float, v2x:Float, v2y:Float, v2z:Float):Float {
        var vx = v1x - v2x;
        var vy = v1y - v2y;
        var vz = v1z - v2z;
        return std.Math.sqrt(vx * vx + vy * vy + vz * vz);
    }
}
