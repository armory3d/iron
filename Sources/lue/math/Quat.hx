package lue.math;

// https://github.com/mrdoob/three.js/

using Math;

// A Quaternion describes a rotation in 3D space.
// The Quaternion is mathematically defined as Q = x*i + y*j + z*k + w, where (i,j,k) are imaginary basis vectors. (x,y,z) can be seen as a vector related to the axis of rotation, while the real multiplier, w, is related to the amount of rotation.
class Quat {

    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var w:Float;

    static var Quaternion_mult_va = new Vec4();
    static var Quaternion_mult_vb = new Vec4();
    static var Quaternion_mult_vaxvb = new Vec4();

    public function new(x = 0.0, y = 0.0, z = 0.0, w = 1.0) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    // Set the value of the quaternion.
    public function set(x:Float, y:Float, z:Float, w:Float) {
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    public function toString():String {
        return this.x + "," + this.y + "," + this.z + "," + this.w;
    }

    // Set the quaternion components given an axis and an angle.
    // angle in radians
    public function setFromAxisAngle(axis:Vec4, angle:Float) {
        var s:Float = std.Math.sin(angle * 0.5);
        this.x = axis.x * s;
        this.y = axis.y * s;
        this.z = axis.z * s;
        this.w = std.Math.cos(angle * 0.5);
    }

    // Saves axis to targetAxis and returns 
    public function toAxisAngle(targetAxis):Dynamic {
        if (targetAxis == null) targetAxis = new Vec4();
        this.normalize(); // if w>1 acos and sqrt will produce errors, this cant happen if quaternion is normalised
        var angle:Float = 2 * std.Math.acos(this.w);
        var s:Float = std.Math.sqrt(1 - this.w * this.w); // assuming quaternion normalised then w is less than 1, so term always positive.
        if (s < 0.001) { // test to avoid divide by zero, s is always positive due to sqrt
            // if s close to zero then direction of axis not important
            targetAxis.x = this.x; // if it is important that axis is normalised then replace with x=1; y=z=0;
            targetAxis.y = this.y;
            targetAxis.z = this.z;
        }
        else {
            targetAxis.x = this.x / s; // normalise axis
            targetAxis.y = this.y / s;
            targetAxis.z = this.z / s;
        }
        return [targetAxis, angle];
    }

    // Quaternion multiplication
    public function mult(q:Quat, target:Quat):Quat {
        if (target == null) target = new Quat();
        var w:Float = this.w;
        var va = Quaternion_mult_va;
        var vb = Quaternion_mult_vb;
        var vaxvb = Quaternion_mult_vaxvb;

        va.set(this.x, this.y, this.z);
        vb.set(q.x, q.y, q.z);
        target.w = w * q.w - va.dot(vb);
        va.cross(vb, vaxvb);

        target.x = w * vb.x + q.w * va.x + vaxvb.x;
        target.y = w * vb.y + q.w * va.y + vaxvb.y;
        target.z = w * vb.z + q.w * va.z + vaxvb.z;

        return target;
    }

    // Get the inverse quaternion rotation.
    public function inverse(target:Quat):Quat {
        var x:Float = this.x; var y:Float = this.y; var z:Float = this.z; var w:Float = this.w;
        if (target == null) target = new Quat();

        this.conjugate(target);
        var inorm2:Float = 1 / (x * x + y * y + z * z + w * w);
        target.x *= inorm2;
        target.y *= inorm2;
        target.z *= inorm2;
        target.w *= inorm2;

        return target;
    }

    // Get the quaternion conjugate
    public function conjugate(target:Quat):Quat {
        if (target == null) target = new Quat();

        target.x = -this.x;
        target.y = -this.y;
        target.z = -this.z;
        target.w = this.w;

        return target;
    }

    // Normalize the quaternion
    public function normalize() {
        var l = std.Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w);
        if (l == 0.0) {
            this.x = 0;
            this.y = 0;
            this.z = 0;
            this.w = 0;
        }
        else {
            l = 1 / l;
            this.x *= l;
            this.y *= l;
            this.z *= l;
            this.w *= l;
        }
    }

    // Approximation of quaternion normalization. Works best when quat is already almost-normalized.
    public function normalizeFast() {
        var f = (3.0 - (this.x * this.x + this.y * this.y + this.z * this.z + this.w * this.w)) / 2.0;
        if (f == 0) {
            this.x = 0;
            this.y = 0;
            this.z = 0;
            this.w = 0;
        }
        else {
            this.x *= f;
            this.y *= f;
            this.z *= f;
            this.w *= f;
        }
    }

    // Multiply the quaternion by a vector
    public function vmult(v:Vec4, target:Vec4):Vec4 {
        if (target == null) target = new Vec4();

        var x:Float = v.x;
        var y:Float = v.y;
        var z:Float = v.z;
        
        var qx = this.x;
        var qy = this.y;
        var qz = this.z;
        var qw = this.w;

        // q * v
        var ix:Float =  qw * x + qy * z - qz * y;
        var iy:Float =  qw * y + qz * x - qx * z;
        var iz:Float =  qw * z + qx * y - qy * x;
        var iw:Float = -qx * x - qy * y - qz * z;

        target.x = ix * qw + iw * -qx + iy * -qz - iz * -qy;
        target.y = iy * qw + iw * -qy + iz * -qx - ix * -qz;
        target.z = iz * qw + iw * -qz + ix * -qy - iy * -qx;

        return target;
    }


    public function vecmult(vec:Vec4):Vec4 {
        var num = this.x * 2.0;
        var num2 = this.y * 2.0;
        var num3 = this.z * 2.0;
        var num4 = this.x * num;
        var num5 = this.y * num2;
        var num6 = this.z * num3;
        var num7 = this.x * num2;
        var num8 = this.x * num3;
        var num9 = this.y * num3;
        var num10 = this.w * num;
        var num11 = this.w * num2;
        var num12 = this.w * num3;

        var result = new Vec4();
        result.x = (1.0 - (num5 + num6)) * vec.x + (num7 - num12) * vec.y + (num8 + num11) * vec.z;
        result.y = (num7 + num12) * vec.x + (1.0 - (num4 + num6)) * vec.y + (num9 - num10) * vec.z;
        result.z = (num8 - num11) * vec.x + (num9 + num10) * vec.y + (1.0 - (num4 + num5)) * vec.z;
        return result;
    }

    // Quaternion target
    public function copy(target) {
        target.x = this.x;
        target.y = this.y;
        target.z = this.z;
        target.w = this.w;
    }

    // Convert the quaternion to euler angle representation. Order: YZX, as this page describes: http://www.euclideanspace.com/maths/standards/index.htm
    public function toEuler(target:Vec4, order = "YZX") {
        var heading:Float = std.Math.NaN; var attitude:Float = 0.0; var bank:Float = 0.0;
        var x:Float = this.x; var y:Float = this.y; var z:Float = this.z; var w:Float = this.w;

        switch(order) {
            case "YZX":
                var test:Float = x * y + z * w;
                if (test > 0.499) { // singularity at north pole
                    heading = 2 * std.Math.atan2(x, w);
                    attitude = Math.PI / 2;
                    bank = 0;
                }
                if (test < -0.499) { // singularity at south pole
                    heading = -2 * std.Math.atan2(x, w);
                    attitude = -Math.PI / 2;
                    bank = 0;
                }
                if (std.Math.isNaN(heading)) {
                    var sqx:Float = x * x;
                    var sqy:Float = y * y;
                    var sqz:Float = z * z;
                    heading = std.Math.atan2(2 * y * w - 2 * x * z , 1.0 - 2 * sqy - 2 * sqz); // Heading
                    attitude = std.Math.asin(2 * test); // attitude
                    bank = std.Math.atan2(2 * x * w - 2 * y * z , 1.0 - 2 * sqx - 2 * sqz); // bank
                }
            default:
                throw "Euler order " + order + " not supported yet.";
        }

        target.y = heading;
        target.z = attitude;
        target.x = bank;
    }

    public function getEuler() {
        var roll  = Math.atan2(2*y*w - 2*x*z, 1 - 2*y*y - 2*z*z);
        var pitch = Math.atan2(2*x*w - 2*y*z, 1 - 2*x*x - 2*z*z);
        var yaw   = Math.asin(2*x*y + 2*z*w);

        return new Vec4(pitch, roll, yaw);
    }

    // See http://www.mathworks.com/matlabcentral/fileexchange/20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/content/SpinCalc.m
    public function setFromEuler(x:Float, y:Float, z:Float, order = "ZXY") {

        var c1 = std.Math.cos(x / 2);
        var c2 = std.Math.cos(y / 2);
        var c3 = std.Math.cos(z / 2);
        var s1 = std.Math.sin(x / 2);
        var s2 = std.Math.sin(y / 2);
        var s3 = std.Math.sin(z / 2);

        if (order == 'XYZ') {
            this.x = s1 * c2 * c3 + c1 * s2 * s3;
            this.y = c1 * s2 * c3 - s1 * c2 * s3;
            this.z = c1 * c2 * s3 + s1 * s2 * c3;
            this.w = c1 * c2 * c3 - s1 * s2 * s3;
        }
        else if (order == 'YXZ') {
            this.x = s1 * c2 * c3 + c1 * s2 * s3;
            this.y = c1 * s2 * c3 - s1 * c2 * s3;
            this.z = c1 * c2 * s3 - s1 * s2 * c3;
            this.w = c1 * c2 * c3 + s1 * s2 * s3;
        }
        else if (order == 'ZXY') {
            this.x = s1 * c2 * c3 - c1 * s2 * s3;
            this.y = c1 * s2 * c3 + s1 * c2 * s3;
            this.z = c1 * c2 * s3 + s1 * s2 * c3;
            this.w = c1 * c2 * c3 - s1 * s2 * s3;
        }
        else if (order == 'ZYX') {
            this.x = s1 * c2 * c3 - c1 * s2 * s3;
            this.y = c1 * s2 * c3 + s1 * c2 * s3;
            this.z = c1 * c2 * s3 - s1 * s2 * c3;
            this.w = c1 * c2 * c3 + s1 * s2 * s3;
        }
        else if (order == 'YZX') {
            this.x = s1 * c2 * c3 + c1 * s2 * s3;
            this.y = c1 * s2 * c3 + s1 * c2 * s3;
            this.z = c1 * c2 * s3 - s1 * s2 * c3;
            this.w = c1 * c2 * c3 - s1 * s2 * s3;
        }
        else if (order == 'XZY') {
            this.x = s1 * c2 * c3 - c1 * s2 * s3;
            this.y = c1 * s2 * c3 - s1 * c2 * s3;
            this.z = c1 * c2 * s3 + s1 * s2 * c3;
            this.w = c1 * c2 * c3 + s1 * s2 * s3;
        }
        return this;
    }

    // Extended
    public function toMatrix():Mat4 {
        var m = Mat4.identity();
        saveToMatrix(m);
        return m;
    }

    public function saveToMatrix(m:Mat4):Mat4 {
        var x = this.x, y = this.y, z = this.z, w = this.w;
        var x2 = x + x, y2 = y + y, z2 = z + z;
        var xx = x * x2, xy = x * y2, xz = x * z2;
        var yy = y * y2, yz = y * z2, zz = z * z2;
        var wx = w * x2, wy = w * y2, wz = w * z2;

        m._00 = 1 - ( yy + zz );
        m._10 = xy - wz;
        m._20 = xz + wy;

        m._01 = xy + wz;
        m._11 = 1 - ( xx + zz );
        m._21 = yz - wx;

        m._02 = xz - wy;
        m._12 = yz + wx;
        m._22 = 1 - ( xx + yy );

        // last column
        m._03 = 0;
        m._13 = 0;
        m._23 = 0;

        // bottom row
        m._30 = 0;
        m._31 = 0;
        m._32 = 0;
        m._33 = 1;

        return m;
    }

    public function initRotate(ax:Float, ay:Float, az:Float) {
        var sinX = (ax * 0.5).sin();
        var cosX = (ax * 0.5).cos();
        var sinY = (ay * 0.5).sin();
        var cosY = (ay * 0.5).cos();
        var sinZ = (az * 0.5).sin();
        var cosZ = (az * 0.5).cos();
        var cosYZ = cosY * cosZ;
        var sinYZ = sinY * sinZ;
        x = sinX * cosYZ - cosX * sinYZ;
        y = cosX * sinY * cosZ + sinX * cosY * sinZ;
        z = cosX * cosY * sinZ - sinX * sinY * cosZ;
        w = cosX * cosYZ + sinX * sinYZ;
    }
    
    public function multiply(q1:Quat, q2:Quat) {
        var x2 = q1.x * q2.w + q1.w * q2.x + q1.y * q2.z - q1.z * q2.y;
        var y2 = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x;
        var z2 = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w;
        var w2 = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
        x = x2;
        y = y2;
        z = z2;
        w = w2;
    }

    public static function lerp(p_a:Quat, p_b:Quat, p_ratio:Float):Quat {
        var c = new Quat();
        //var ca : Quat = p_a.clone;
        var ca = new Quat();
        p_a.copy(ca);
        var dot:Float = p_a.dot(p_b);
        if (dot < 0.0) {
            ca.w = -ca.w;
            ca.x = -ca.x;
            ca.y = -ca.y;
            ca.z = -ca.z;
        }
        
        c.x = ca.x + (p_b.x - ca.x) * p_ratio;
        c.y = ca.y + (p_b.y - ca.y) * p_ratio;
        c.z = ca.z + (p_b.z - ca.z) * p_ratio;
        c.w = ca.w + (p_b.w - ca.w) * p_ratio;
        c.normalize();
        return c;
    }

    public static function slerp(qa:Quat, qb:Quat, t:Float):Quat {
        // quaternion to return
        var qm = new Quat();
        // Calculate angle between them.
        var cosHalfTheta = qa.w * qb.w + qa.x * qb.x + qa.y * qb.y + qa.z * qb.z;
        // if qa=qb or qa=-qb then theta = 0 and we can return qa
        if (Math.abs(cosHalfTheta) >= 1.0) {
            qm.w = qa.w;
            qm.x = qa.x;
            qm.y = qa.y;
            qm.z = qa.z;
            return qm;
        }
        // Calculate temporary values.
        var halfTheta = Math.acos(cosHalfTheta);
        var sinHalfTheta = Math.sqrt(1.0 - cosHalfTheta * cosHalfTheta);
        // if theta = 180 degrees then result is not fully defined
        // we could rotate around any axis normal to qa or qb
        if (Math.abs(sinHalfTheta) < 0.001) { // fabs is floating point absolute
            qm.w = (qa.w * 0.5 + qb.w * 0.5);
            qm.x = (qa.x * 0.5 + qb.x * 0.5);
            qm.y = (qa.y * 0.5 + qb.y * 0.5);
            qm.z = (qa.z * 0.5 + qb.z * 0.5);
            return qm;
        }
        var ratioA = Math.sin((1 - t) * halfTheta) / sinHalfTheta;
        var ratioB = Math.sin(t * halfTheta) / sinHalfTheta; 
        //calculate Quaternion.
        qm.w = (qa.w * ratioA + qb.w * ratioB);
        qm.x = (qa.x * ratioA + qb.x * ratioB);
        qm.y = (qa.y * ratioA + qb.y * ratioB);
        qm.z = (qa.z * ratioA + qb.z * ratioB);
        return qm;
    }

    public var euler(get_euler, null):Vec4;
    private function get_euler():Vec4 { 
        normalize();
        var test:Float = x * y + z * w;
        var a = new Vec4();
        if (test > 0.499) { // singularity at north pole
            a.x = 2.0 * std.Math.atan2(x, w) * lue.math.Math.Rad2Deg;
            a.y = (lue.math.Math.PI / 2) * lue.math.Math.Rad2Deg;
            a.z = 0;
            return a;
        }
        if (test < -0.499) { // singularity at south pole
            a.x = -2.0 * std.Math.atan2(x, w) * lue.math.Math.Rad2Deg;
            a.y = -(lue.math.Math.PI / 2) * lue.math.Math.Rad2Deg;
            a.z = 0;
            return a;
        }
        var sqx:Float = x * x;
        var sqy:Float = y * y;
        var sqz:Float = z * z;        
        a.x = std.Math.atan2(2.0 * y * w - 2.0 * x * z , 1.0 - 2.0 * sqy - 2.0 * sqz) * lue.math.Math.Rad2Deg;
        a.y = std.Math.asin(2.0 * test) * lue.math.Math.Rad2Deg;
        a.z = std.Math.atan2(2.0 * x * w - 2.0 * y * z , 1.0 - 2.0 * sqx - 2.0 * sqz) * lue.math.Math.Rad2Deg;     
        return a;
    }

    static public function fromEuler(p_euler:Vec4):Quat {
        // Assuming the angles are in radians.
        var q = new Quat();
        var ax:Float = p_euler.x * lue.math.Math.Rad2Deg;
        var ay:Float = p_euler.y * lue.math.Math.Rad2Deg;
        var az:Float = p_euler.z * lue.math.Math.Rad2Deg;     
        var c1:Float = std.Math.cos(ax * 0.5);
        var s1:Float = std.Math.sin(ax * 0.5);
        var c2:Float = std.Math.cos(ay * 0.5);
        var s2:Float = std.Math.sin(ay * 0.5);
        var c3:Float = std.Math.cos(az * 0.5);
        var s3:Float = std.Math.sin(az * 0.5);
        var c1c2:Float = c1*c2;
        var s1s2:Float = s1*s2;
        q.w = c1c2 * c3 - s1s2 * s3;
        q.x = c1c2 * s3 + s1s2 * c3;
        q.y = s1 * c2 * c3 + c1 * s2 * s3;
        q.z = c1 * s2 * c3 - s1 * c2 * s3;
        q.normalize();
        return q;
    }

    public function dot(p_v:Quat):Float {
        return (x * p_v.x) + (y * p_v.y) + (z * p_v.z) + (w * p_v.w);
    }
}
