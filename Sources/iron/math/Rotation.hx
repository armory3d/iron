package iron.math;

import iron.math.Vec3;
import iron.math.Quat;
import iron.math.Mat3;
//import iron.math.Math;
import kha.FastFloat;


class Rotation{  

    static inline var SQRT2:FastFloat = 1.4142135623730951;

    // those first two are borrowed from the 'iron' package,
    // but have better comments and a slight clarification

    public static function quatToNative(q:Quat):Vec4 {
        var x:FastFloat = q.x;
        var y:FastFloat = q.y;
        var z:FastFloat = q.z;
        var w:FastFloat = q.w;
        // YZX (XZY, according to blender)
        var roll = Math.NaN;
        var yaw = 0.0;
        var pitch = 0.0;

        var test = x * y + z * w;
        if (test > 0.499) { // Singularity at north pole
            roll = 2 * Math.atan2(x, w);
            yaw = Math.PI / 2;
            pitch = 0;
        }
        if (test < -0.499) { // Singularity at south pole
            roll = -2 * Math.atan2(x, w);
            yaw = -Math.PI / 2;
            pitch = 0;
        }
        if (Math.isNaN(roll)) {
            var sqx = x * x;
            var sqy = y * y;
            var sqz = z * z;
            roll = Math.atan2(2 * y * w - 2 * x * z , 1.0 - 2 * sqy - 2 * sqz);
            yaw = Math.asin(2 * test);
            pitch = Math.atan2(2 * x * w - 2 * y * z , 1.0 - 2 * sqx - 2 * sqz);
        }
        return new Vec4(pitch, roll, yaw, 1);
    }


    public static function nativeToQuat(e:Vec4):Quat {
        var c1 = Math.cos(e.x / 2);
        var c3 = Math.cos(e.y / 2);
        var c2 = Math.cos(e.z / 2);
        var s1 = Math.sin(e.x / 2);
        var s3 = Math.sin(e.y / 2);
        var s2 = Math.sin(e.z / 2);
        // YZX (Quats multiplied in this order. (so 321).)
        // blender says this is XZY, though.
        var w = c1 * c2 * c3 - s1 * s2 * s3;
        var x = s1 * c2 * c3 + c1 * s2 * s3;
        var y = c1 * c2 * s3 + s1 * s2 * c3;
        var z = c1 * s2 * c3 - s1 * c2 * s3;
        return new Quat(x,y,z,w);  // because OF COURSE the w is last.
    }
    
    // Those two required the help of
    // https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles,
    // and some thinking about the respective conventions of blender and armory

 /*   public static function toEulerXYZold(w:FastFloat, x:FastFloat, y:FastFloat, z:FastFloat):Vec4 {
        // XYZ   means that (transformed:Vec3 == yaw:Mat3*roll:Mat3*pitch:Mat3 * raw:Vec3)
        // WARNING: if you compare this method to online tutorials / articles / wikis / etc,
        //          'roll', 'yaw', and 'pitch' are probably wrong terms
        //          in this function, because applied in the wrong order.
        
        var q0:Float = SQRT2 * w;
        var q1:Float = SQRT2 * x;
        var q2:Float = SQRT2 * y;
        var q3:Float = SQRT2 * z;

        var qda:Float = q0 * q1;
        var qdb:Float = q0 * q2;
        var qdc:Float = q0 * q3;
        var qaa:Float = q1 * q1;
        var qab:Float = q1 * q2;
        var qac:Float = q1 * q3;
        var qbb:Float = q2 * q2;
        var qbc:Float = q2 * q3;
        var qcc:Float = q3 * q3;
        
        
		var to_z = Math.NaN;
		var to_y = 0.0;
		var to_x = 0.0;

		var test = qac + qdb;  // 01
		//if (test > 0.998) { // Singularity at east "pole"
		//	to_z = 2 * Math.atan2(x, w);
		//	to_y = Math.PI / 2;
		//}
		//if (test < -0.998) { // Singularity at west "pole"
		//	to_z = -2 * Math.atan2(x, w);
		//	to_y = -Math.PI / 2;
		//	to_x = 0;
		//}
		if (Math.isNaN(to_z)) {
			to_z = -Math.atan2(-qdc - qab , 1.0 - qbb - qcc);  // -02 , 00
			to_y = Math.asin(test);
			to_x = -Math.atan2(-qda - qbc , 1.0 - qaa - qbb); // -21 , 11
		}
		return new Vec4(to_x, to_y, to_z);
	}

        
        //var test = w * y - x * z;
        //if (test > 0.499) { // Singularity at north pole
        //    yaw = 2 * Math.atan2(z, w);
        //    roll = Math.PI / 2;
        //    pitch = 0;
        //}
        //if (test < -0.499) { // Singularity at south pole
        //    yaw = -2 * Math.atan2(z, w);
        //    roll = -Math.PI / 2;
        //    pitch = 0;
        //}
        //if (Math.isNaN(roll)) {
        //    var sqx = x * x;
        //    var sqy = y * y;
        //    var sqz = z * z;
        //    pitch = Math.atan2(2 * w * x - 2 * y * z , 1.0 - 2 * sqx - 2 * sqy);
        //    roll = Math.asin(2 * test);
        //    yaw = Math.atan2(2 * w * z + 2 * x * y , 1.0 - 2 * sqy -  2 * sqz);
        //}
        //return new Vec4(to_x, to_y, to_z);
    */

    public static function eulerXYZToQuat(e:Vec4):Quat {
        var c1 = Math.cos(e.x / 2);
        var c2 = Math.cos(e.y / 2);
        var c3 = Math.cos(e.z / 2);
        var s1 = Math.sin(e.x / 2);
        var s2 = Math.sin(e.y / 2);
        var s3 = Math.sin(e.z / 2);
        // ZYX for Arm, XYZ for blender.
        var w = c1 * c2 * c3 + s1 * s2 * s3;
        var x = s1 * c2 * c3 - c1 * s2 * s3;
        var y = c1 * s2 * c3 + s1 * c2 * s3;
        var z = c1 * c2 * s3 - s1 * s2 * c3;
        return new Quat(x,y,z,w);
    }
 
// blender order, as in reverse of armory (and mathematical) order
// (0, "XYZ", "")
// (1, "XZY", "")
// (2, "YXZ", "")
// (3, "YZX", "")
// (4, "ZXY", "")
// (5, "ZYX", "")

    public static function eulerToQuat(e:Vec4, order:String):Quat {
        var c1 = Math.cos(e.x / 2);
        var c2 = Math.cos(e.y / 2);
        var c3 = Math.cos(e.z / 2);
        var s1 = Math.sin(e.x / 2);
        var s2 = Math.sin(e.y / 2);
        var s3 = Math.sin(e.z / 2);
        
        var qx = new Quat(s1,0,0,c1);     // Quat order: XYZW (even though this isn't the mathematical order)
        var qy = new Quat(0,s2,0,c2);
        var qz = new Quat(0,0,s3,c3);
        var q:Quat;
        
        if (order.charAt(2) =='X')
            q = qx;
        else if (order.charAt(2)=='Y')
            q = qy;
        else
            q = qz;
        if (order.charAt(1)=='X')
            q.mult(qx);
        else if (order.charAt(1)=='Y')
            q.mult(qy);
        else
            q.mult(qz);
        if (order.charAt(0)=='X')
            q.mult(qx);
        else if (order.charAt(0) == 'Y')
            q.mult(qy);
        else
            q.mult(qz);
        
        return q;
    }
 
 
    // Updated method (but with more computation): use matrices as a middle ground
    // (borrowed from blender's internal code in mathutils)
    // note: there are two possible eulers for the same rotation, blender defines the 'best' as the one with the smallest sum of absolute components
    //        should we actually make that choice, or is just getting one of them randomly good?
    // note2: the name of the matrix members (eg: _01) are the opposite of the mathematical order: matrices are stored 'as arras of columns' instead of 'as arrays of lines'
    //        this is easily seen when the matrix is mapped to an array of arrays.
    
    public static function quatToEulerXYZ(q:Quat): Vec4{
        // normalize quat ?
        
        var q0:Float = SQRT2 * q.w;
        var q1:Float = SQRT2 * q.x;
        var q2:Float = SQRT2 * q.y;
        var q3:Float = SQRT2 * q.z;

        var qda:Float = q0 * q1;
        var qdb:Float = q0 * q2;
        var qdc:Float = q0 * q3;
        var qaa:Float = q1 * q1;
        var qab:Float = q1 * q2;
        var qac:Float = q1 * q3;
        var qbb:Float = q2 * q2;
        var qbc:Float = q2 * q3;
        var qcc:Float = q3 * q3;

        /*var m = new Mat3(

            (1.0 - qbb - qcc),
            (qdc + qab),
            (-qdb + qac),

            (-qdc + qab),
            (1.0 - qaa - qcc),
            (qda + qbc),

            (qdb + qac),
            (-qda + qbc),
            (1.0 - qaa - qbb)
        );*/
        var m00:FastFloat = (1.0 - qbb - qcc);
        var m10:FastFloat = (qdc + qab);
        var m20:FastFloat = (-qdb + qac);
        
        var m11:FastFloat = (1.0 - qaa - qcc);
        var m21:FastFloat = (qda + qbc);
        
        var m12:FastFloat = (-qda + qbc);
        var m22:FastFloat = (1.0 - qaa - qbb);
        
        var cy:Float = Math.sqrt(m00*m00 + m10*m10);
        
        //var cy:Float = hypotf(m._00, m._01);
        
        var eul1 = new Vec4();

        if (cy > 16.0 * 1e-3){
            eul1.x = Math.atan2(m21, m22);
            eul1.y = Math.atan2(-m20, cy);
            eul1.z = Math.atan2(m10, m00);
        }
        else {
            eul1.x = Math.atan2(-m12, m11);
            eul1.y = Math.atan2(-m20, cy);
            eul1.z = 2*Math.PI;
        }
        return eul1;
    }
    
    public static function quatToEuler(q:Quat, p:String): Vec4{
        // normalize quat ?
        
        var q0:Float = SQRT2 * q.w;
        var q1:Float = SQRT2 * q.x;
        var q2:Float = SQRT2 * q.y;
        var q3:Float = SQRT2 * q.z;

        var qda:Float = q0 * q1;
        var qdb:Float = q0 * q2;
        var qdc:Float = q0 * q3;
        var qaa:Float = q1 * q1;
        var qab:Float = q1 * q2;
        var qac:Float = q1 * q3;
        var qbb:Float = q2 * q2;
        var qbc:Float = q2 * q3;
        var qcc:Float = q3 * q3;

        var m = new Mat3(

            (1.0 - qbb - qcc),
            (qdc + qab),
            (-qdb + qac),

            (-qdc + qab),
            (1.0 - qaa - qcc),
            (qda + qbc),

            (qdb + qac),
            (-qda + qbc),
            (1.0 - qaa - qbb)
        );
        
        // now define what is necessary to perform look-ups in that matrix
        var ml:Array<Array<FastFloat>> = [[m._00, m._10, m._20],
                                          [m._01, m._11, m._21],
                                          [m._02, m._12, m._22]];
        var eull:Array<FastFloat> = [0, 0, 0];
                                          
        var i:Int = p.charCodeAt(0) - "X".charCodeAt(0);
        var j:Int = p.charCodeAt(1) - "X".charCodeAt(0);
        var k:Int = p.charCodeAt(2) - "X".charCodeAt(0);
        
        // now the dumber version (isolating code)
        if (p.charAt(0)=="X") i=0;
        else if (p.charAt(0)=="Y") i=1;
        else i=2;
        if (p.charAt(1)=="X") j=0;
        else if (p.charAt(1)=="Y") j=1;
        else j=2;
        if (p.charAt(2)=="X") k=0;
        else if (p.charAt(2)=="Y") k=1;
        else k=2;
        
        var cy:Float = Math.sqrt(ml[i][i]*ml[i][i] + ml[i][j]*ml[i][j]);
        
        var eul1 = new Vec4();

        if (cy > 16.0 * 1e-3){
            eull[i] = Math.atan2(ml[j][k], ml[k][k]);
            eull[j] = Math.atan2(-ml[i][k], cy);
            eull[k] = Math.atan2(ml[i][j], ml[i][i]);
        }
        else {
            eull[i] = Math.atan2(-ml[k][j], ml[j][j]);
            eull[j] = Math.atan2(-ml[i][k], cy);
            eull[k] = 0; //2*Math.PI;
        }
        eul1.x = eull[0];
        eul1.y = eull[1];
        eul1.z = eull[2];
        
        if (p=="XZY" || p=="YXZ" || p=="ZYX"){
            eul1.x *= -1;
            eul1.y *= -1;
            eul1.z *= -1;
        }
        return eul1;
    }
}
