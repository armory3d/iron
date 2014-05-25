package wings.math;

// Adapted from Cannon 3D Physics

using wings.math.Math;

/**
 * @class Quaternion
 * @brief A Quaternion describes a rotation in 3D space.
 * @description The Quaternion is mathematically defined as Q = x*i + y*j + z*k + w, where (i,j,k) are imaginary basis vectors. (x,y,z) can be seen as a vector related to the axis of rotation, while the real multiplier, w, is related to the amount of rotation.
 * @param float x Multiplier of the imaginary basis vector i.
 * @param float y Multiplier of the imaginary basis vector j.
 * @param float z Multiplier of the imaginary basis vector k.
 * @param float w Multiplier of the real part.
 * @see http://en.wikipedia.org/wiki/Quaternion
 */
class Quat {

    public var x:Float;
    public var y:Float;
    public var z:Float;
    public var w:Float;

    static var Quaternion_mult_va:Vec3 = new Vec3();
    static var Quaternion_mult_vb:Vec3 = new Vec3();
    static var Quaternion_mult_vaxvb:Vec3 = new Vec3();

    public function new(x = 0.0,y = 0.0,z = 0.0,w = 1.0){
        /**
        * @property float x
        * @memberof Quaternion
        */
        this.x = x;
        /**
        * @property float y
        * @memberof Quaternion
        */
        this.y = y;
        /**
        * @property float z
        * @memberof Quaternion
        */
        this.z = z;
        /**
        * @property float w
        * @memberof Quaternion
        * @brief The multiplier of the real quaternion basis vector.
        */
        this.w = w;
    }

    /**
     * @method set
     * @memberof Quaternion
     * @brief Set the value of the quaternion.
     * @param float x
     * @param float y
     * @param float z
     * @param float w
     */
    public function set(x,y,z,w):Void{
        this.x = x;
        this.y = y;
        this.z = z;
        this.w = w;
    }

    /**
     * @method toString
     * @memberof Quaternion
     * @brief Convert to a readable format
     * @return string
     */
    public function toString():String{
        return this.x+","+this.y+","+this.z+","+this.w;
    }

    /**
     * @method setFromAxisAngle
     * @memberof Quaternion
     * @brief Set the quaternion components given an axis and an angle.
     * @param Vec3 axis
     * @param float angle in radians
     */
    public function setFromAxisAngle(axis:Vec3,angle:Float):Void{
        var s:Float = Math.sin(angle*0.5);
        this.x = axis.x * s;
        this.y = axis.y * s;
        this.z = axis.z * s;
        this.w = Math.cos(angle*0.5);
    }

    // saves axis to targetAxis and returns 
    public function toAxisAngle(targetAxis):Dynamic{
        if (targetAxis == null) targetAxis = new Vec3();
        this.normalize(); // if w>1 acos and sqrt will produce errors, this cant happen if quaternion is normalised
        var angle:Float = 2 * Math.acos(this.w);
        var s:Float = Math.sqrt(1-this.w*this.w); // assuming quaternion normalised then w is less than 1, so term always positive.
        if (s < 0.001) { // test to avoid divide by zero, s is always positive due to sqrt
            // if s close to zero then direction of axis not important
            targetAxis.x = this.x; // if it is important that axis is normalised then replace with x=1; y=z=0;
            targetAxis.y = this.y;
            targetAxis.z = this.z;
        } else {
            targetAxis.x = this.x / s; // normalise axis
            targetAxis.y = this.y / s;
            targetAxis.z = this.z / s;
        }
        return [targetAxis,angle];
    }

    /**
     * @method setFromVectors
     * @memberof Quaternion
     * @brief Set the quaternion value given two vectors. The resulting rotation will be the needed rotation to rotate u to v.
     * @param Vec3 u
     * @param Vec3 v
     */
    public function setFromVectors(u,v){
        if(u.isAntiparallelTo(v)) {
            var t1 = new Vec3();//sfv_t1;
            var t2 = new Vec3();//sfv_t2;

            u.tangents(t1,t2);
            this.setFromAxisAngle(t1,Math.PI);
        } else {
            var a = u.cross(v);
            this.x = a.x;
            this.y = a.y;
            this.z = a.z;
            this.w = Math.sqrt(Math.pow(u.norm(),2) * Math.pow(v.norm(),2)) + u.dot(v);
            this.normalize();
        }
    }

    /**
     * @method mult
     * @memberof Quaternion
     * @brief Quaternion multiplication
     * @param Quaternion q
     * @param Quaternion target Optional.
     * @return Quaternion
     */
    public function mult(q:Quat,target:Quat):Quat{
        if (target == null) target = new Quat();
        var w:Float = this.w;
        var va = Quaternion_mult_va;
        var vb = Quaternion_mult_vb;
        var vaxvb = Quaternion_mult_vaxvb;

        va.set(this.x,this.y,this.z);
        vb.set(q.x,q.y,q.z);
        target.w = w*q.w - va.dot(vb);
        va.cross(vb,vaxvb);

        target.x = w * vb.x + q.w*va.x + vaxvb.x;
        target.y = w * vb.y + q.w*va.y + vaxvb.y;
        target.z = w * vb.z + q.w*va.z + vaxvb.z;

        return target;
    }

    /**
     * @method inverse
     * @memberof Quaternion
     * @brief Get the inverse quaternion rotation.
     * @param Quaternion target
     * @return Quaternion
     */
    public function inverse(target):Quat{
        var x:Float = this.x; var y:Float = this.y; var z:Float = this.z; var w:Float = this.w;
        if (target == null) target = new Quat();

        this.conjugate(target);
        var inorm2:Float = 1/(x*x + y*y + z*z + w*w);
        target.x *= inorm2;
        target.y *= inorm2;
        target.z *= inorm2;
        target.w *= inorm2;

        return target;
    }

    /**
     * @method conjugate
     * @memberof Quaternion
     * @brief Get the quaternion conjugate
     * @param Quaternion target
     * @return Quaternion
     */
    public function conjugate(target):Quat{
        if (target == null) target = new Quat();

        target.x = -this.x;
        target.y = -this.y;
        target.z = -this.z;
        target.w = this.w;

        return target;
    }

    /**
     * @method normalize
     * @memberof Quaternion
     * @brief Normalize the quaternion. Note that this changes the values of the quaternion.
     */
    public function normalize():Void{
        var l = Math.sqrt(this.x*this.x+this.y*this.y+this.z*this.z+this.w*this.w);
        if ( l == 0.0 ) {
            this.x = 0;
            this.y = 0;
            this.z = 0;
            this.w = 0;
        } else {
            l = 1 / l;
            this.x *= l;
            this.y *= l;
            this.z *= l;
            this.w *= l;
        }
    }

    /**
     * @method normalizeFast
     * @memberof Quaternion
     * @brief Approximation of quaternion normalization. Works best when quat is already almost-normalized.
     * @see http://jsperf.com/fast-quaternion-normalization
     * @author unphased, https://github.com/unphased
     */
    public function normalizeFast():Void {
        var f = (3.0-(this.x*this.x+this.y*this.y+this.z*this.z+this.w*this.w))/2.0;
        if ( f == 0 ) {
            this.x = 0;
            this.y = 0;
            this.z = 0;
            this.w = 0;
        } else {
            this.x *= f;
            this.y *= f;
            this.z *= f;
            this.w *= f;
        }
    }

    /**
     * @method vmult
     * @memberof Quaternion
     * @brief Multiply the quaternion by a vector
     * @param Vec3 v
     * @param Vec3 target Optional
     * @return Vec3
     */
    public function vmult(v:Vec3,target:Vec3):Vec3{
        if (target == null) target = new Vec3();

        var x:Float = v.x;
        var y:Float = v.y;
        var z:Float = v.z;
        
        var qx = this.x;
        var qy = this.y;
        var qz = this.z;
        var qw = this.w;

        // q*v
        var ix:Float =  qw * x + qy * z - qz * y;
        var iy:Float =  qw * y + qz * x - qx * z;
        var iz:Float =  qw * z + qx * y - qy * x;
        var iw:Float = -qx * x - qy * y - qz * z;

        target.x = ix * qw + iw * -qx + iy * -qz - iz * -qy;
        target.y = iy * qw + iw * -qy + iz * -qx - ix * -qz;
        target.z = iz * qw + iw * -qz + ix * -qy - iy * -qx;

        return target;
    }


    public function vecmult(vec:Vec3):Vec3 {
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

        var result = new Vec3();
        result.x = (1.0 - (num5 + num6)) * vec.x + (num7 - num12) * vec.y + (num8 + num11) * vec.z;
        result.y = (num7 + num12) * vec.x + (1.0 - (num4 + num6)) * vec.y + (num9 - num10) * vec.z;
        result.z = (num8 - num11) * vec.x + (num9 + num10) * vec.y + (1.0 - (num4 + num5)) * vec.z;
        return result;
    }




    /**
     * @method copy
     * @memberof Quaternion
     * @param Quaternion target
     */
    public function copy(target):Void{
        target.x = this.x;
        target.y = this.y;
        target.z = this.z;
        target.w = this.w;
    }

    /**
     * @method toEuler
     * @memberof Quaternion
     * @brief Convert the quaternion to euler angle representation. Order: YZX, as this page describes: http://www.euclideanspace.com/maths/standards/index.htm
     * @param Vec3 target
     * @param string order Three-character string e.g. "YZX", which also is default.
     */
    public function toEuler(target:Vec3, order:String = null):Void{
        if (order == null) order = "YZX";

        var heading:Float = Math.NaN; var attitude:Float = 0.0; var bank:Float = 0.0;
        var x:Float = this.x; var y:Float = this.y; var z:Float = this.z; var w:Float = this.w;

        switch(order){
        case "YZX":
            var test:Float = x * y + z * w;
            if (test > 0.499) { // singularity at north pole
                heading = 2 * Math.atan2(x,w);
                attitude = Math.PI/2;
                bank = 0;
            }
            if (test < -0.499) { // singularity at south pole
                heading = -2 * Math.atan2(x,w);
                attitude = - Math.PI/2;
                bank = 0;
            }
            if(Math.isNaN(heading)){
                var sqx:Float = x*x;
                var sqy:Float = y*y;
                var sqz:Float = z*z;
                heading = Math.atan2(2*y*w - 2*x*z , 1.0 - 2*sqy - 2*sqz); // Heading
                attitude = Math.asin(2*test); // attitude
                bank = Math.atan2(2*x*w - 2*y*z , 1.0 - 2*sqx - 2*sqz); // bank
            }
        default:
            throw "Euler order "+order+" not supported yet.";
        }

        target.y = heading;
        target.z = attitude;
        target.x = bank;
    }




    /**
     * See http://www.mathworks.com/matlabcentral/fileexchange/20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/content/SpinCalc.m
     * @method setFromEuler
     * @param {Number} x
     * @param {Number} y
     * @param {Number} z
     * @param {String} order The order to apply angles: 'XYZ' or 'YXZ' or any other combination
     */
    public function setFromEuler(x:Float, y:Float, z:Float) {

        var c1 = Math.cos( x / 2 );
        var c2 = Math.cos( y / 2 );
        var c3 = Math.cos( z / 2 );
        var s1 = Math.sin( x / 2 );
        var s2 = Math.sin( y / 2 );
        var s3 = Math.sin( z / 2 );

        /*if ( order === 'XYZ' ) {

            this.x = s1 * c2 * c3 + c1 * s2 * s3;
            this.y = c1 * s2 * c3 - s1 * c2 * s3;
            this.z = c1 * c2 * s3 + s1 * s2 * c3;
            this.w = c1 * c2 * c3 - s1 * s2 * s3;

        } else if ( order === 'YXZ' ) {

            this.x = s1 * c2 * c3 + c1 * s2 * s3;
            this.y = c1 * s2 * c3 - s1 * c2 * s3;
            this.z = c1 * c2 * s3 - s1 * s2 * c3;
            this.w = c1 * c2 * c3 + s1 * s2 * s3;

        } else if ( order === 'ZXY' ) {
*/
            this.x = s1 * c2 * c3 - c1 * s2 * s3;
            this.y = c1 * s2 * c3 + s1 * c2 * s3;
            this.z = c1 * c2 * s3 + s1 * s2 * c3;
            this.w = c1 * c2 * c3 - s1 * s2 * s3;
/*
        } else if ( order === 'ZYX' ) {

            this.x = s1 * c2 * c3 - c1 * s2 * s3;
            this.y = c1 * s2 * c3 + s1 * c2 * s3;
            this.z = c1 * c2 * s3 - s1 * s2 * c3;
            this.w = c1 * c2 * c3 + s1 * s2 * s3;

        } else if ( order === 'YZX' ) {

            this.x = s1 * c2 * c3 + c1 * s2 * s3;
            this.y = c1 * s2 * c3 + s1 * c2 * s3;
            this.z = c1 * c2 * s3 - s1 * s2 * c3;
            this.w = c1 * c2 * c3 - s1 * s2 * s3;

        } else if ( order === 'XZY' ) {

            this.x = s1 * c2 * c3 - c1 * s2 * s3;
            this.y = c1 * s2 * c3 - s1 * c2 * s3;
            this.z = c1 * c2 * s3 + s1 * s2 * c3;
            this.w = c1 * c2 * c3 + s1 * s2 * s3;

        }
*/
        return this;

    }


    // Extended
    public function toMatrix() {
        var m = new Mat4();
        saveToMatrix(m);
        return m;
    }


    public function saveToMatrix( m : Mat4 ):Mat4 {
        var xx = x * x;
        var xy = x * y;
        var xz = x * z;
        var xw = x * w;
        var yy = y * y;
        var yz = y * z;
        var yw = y * w;
        var zz = z * z;
        var zw = z * w;
        m._11 = 1 - 2 * ( yy + zz );
        m._12 = 2 * ( xy + zw );
        m._13 = 2 * ( xz - yw );
        m._14 = 0;
        m._21 = 2 * ( xy - zw );
        m._22 = 1 - 2 * ( xx + zz );
        m._23 = 2 * ( yz + xw );
        m._24 = 0;
        m._31 = 2 * ( xz + yw );
        m._32 = 2 * ( yz - xw );
        m._33 = 1 - 2 * ( xx + yy );
        m._34 = 0;
        m._41 = 0;
        m._42 = 0;
        m._43 = 0;
        m._44 = 1;
        return m;
    }

    public function initRotate( ax : Float, ay : Float, az : Float ) {
        var sinX = ( ax * 0.5 ).sin();
        var cosX = ( ax * 0.5 ).cos();
        var sinY = ( ay * 0.5 ).sin();
        var cosY = ( ay * 0.5 ).cos();
        var sinZ = ( az * 0.5 ).sin();
        var cosZ = ( az * 0.5 ).cos();
        var cosYZ = cosY * cosZ;
        var sinYZ = sinY * sinZ;
        x = sinX * cosYZ - cosX * sinYZ;
        y = cosX * sinY * cosZ + sinX * cosY * sinZ;
        z = cosX * cosY * sinZ - sinX * sinY * cosZ;
        w = cosX * cosYZ + sinX * sinYZ;
    }
    
    public function multiply( q1 : Quat, q2 : Quat ) {
        var x2 = q1.x * q2.w + q1.w * q2.x + q1.y * q2.z - q1.z * q2.y;
        var y2 = q1.w * q2.y - q1.x * q2.z + q1.y * q2.w + q1.z * q2.x;
        var z2 = q1.w * q2.z + q1.x * q2.y - q1.y * q2.x + q1.z * q2.w;
        var w2 = q1.w * q2.w - q1.x * q2.x - q1.y * q2.y - q1.z * q2.z;
        x = x2;
        y = y2;
        z = z2;
        w = w2;
    }

    /*public function slerp(qb:Quat, t:Float, target:Quat):Quat {
        var x = this.x, y = this.y, z = this.z, w = this.w;

        // http://www.euclideanspace.com/maths/algebra/realNormedAlgebra/quaternions/slerp/

        var cosHalfTheta = w * qb.w + x * qb.x + y * qb.y + z * qb.z;

        if (cosHalfTheta < 0) {
            target.w = -qb.w;
            target.x = -qb.x;
            target.y = -qb.y;
            target.z = -qb.z;

            cosHalfTheta = -cosHalfTheta;
        }
        else {
            this.copy(qb);
        }

        if (cosHalfTheta >= 1.0) {
            target.w = w;
            target.x = x;
            target.y = y;
            target.z = z;

            return this;
        }

        var halfTheta = Math.acos(cosHalfTheta);
        var sinHalfTheta = Math.sqrt(1.0 - cosHalfTheta * cosHalfTheta);

        if (Math.abs(sinHalfTheta) < 0.001) {
            target.w = 0.5 * (w + this.w);
            target.x = 0.5 * (x + this.x);
            target.y = 0.5 * (y + this.y);
            target.z = 0.5 * (z + this.z);

            return this;
        }

        var ratioA = Math.sin((1 - t) * halfTheta) / sinHalfTheta;
        var ratioB = Math.sin(t * halfTheta) / sinHalfTheta;

        target.w = (w * ratioA + this.w * ratioB);
        target.x = (x * ratioA + this.x * ratioB);
        target.y = (y * ratioA + this.y * ratioB);
        target.z = (z * ratioA + this.z * ratioB);

        return target;
    }*/



    public static function slerp(qa:Quat, qb:Quat, t:Float):Quat {
        // quaternion to return
        var qm = new Quat();
        // Calculate angle between them.
        var cosHalfTheta = qa.w * qb.w + qa.x * qb.x + qa.y * qb.y + qa.z * qb.z;
        // if qa=qb or qa=-qb then theta = 0 and we can return qa
        if (Math.abs(cosHalfTheta) >= 1.0){
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
        if (Math.abs(sinHalfTheta) < 0.001){ // fabs is floating point absolute
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
}
