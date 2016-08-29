package iron.math;

import kha.FastFloat;

class Mat4 extends kha.math.FastMatrix4 {

	public function new(_00:FastFloat, _10:FastFloat, _20:FastFloat, _30:FastFloat,
						_01:FastFloat, _11:FastFloat, _21:FastFloat, _31:FastFloat,
						_02:FastFloat, _12:FastFloat, _22:FastFloat, _32:FastFloat,
						_03:FastFloat, _13:FastFloat, _23:FastFloat, _33:FastFloat) {
		
		super(_00, _10, _20, _30, _01, _11, _21, _31, _02, _12, _22, _32, _03, _13, _23, _33);
	}

	public function compose(position:Vec4, quaternion:Quat, sc:Vec4):Mat4 {
		makeRotationFromQuaternion(quaternion);
		scale(sc);
		setPosition(position);
		return this;
	}

	static var vector = new Vec4();
	static var matrix = Mat4.identity();
	public function decompose(position:Vec4, quaternion:Quat, scale:Vec4) {
		// var vector = new Vec4(0, 0, 0, 0);
		vector.w = 0.0;
		// var matrix = Mat4.identity();

		var sx = vector.set(_00, _01, _02).length();
		var sy = vector.set(_10, _11, _12).length();
		var sz = vector.set(_20, _21, _22).length();
		var det = this.determinant();
		if (det < 0) sx = -sx;
		position.x = _30;
		position.y = _31;
		position.z = _32;
		// scale the rotation part
		matrix._00 = _00;
		matrix._10 = _10;
		matrix._20 = _20;
		matrix._30 = _30;
		matrix._01 = _01;
		matrix._11 = _11;
		matrix._21 = _21;
		matrix._31 = _31;
		matrix._02 = _02;
		matrix._12 = _12;
		matrix._22 = _22;
		matrix._32 = _32;
		matrix._03 = _03;
		matrix._13 = _13;
		matrix._23 = _23;
		matrix._33 = _33;
		var invSX = 1 / sx;
		var invSY = 1 / sy;
		var invSZ = 1 / sz;
		matrix._00 *= invSX;
		matrix._01 *= invSX;
		matrix._02 *= invSX;
		matrix._03 = 0;
		matrix._10 *= invSY;
		matrix._11 *= invSY;
		matrix._12 *= invSY;
		matrix._13 = 0;
		matrix._20 *= invSZ;
		matrix._21 *= invSZ;
		matrix._22 *= invSZ;
		matrix._23 = 0;
		matrix._30 = 0;
		matrix._31 = 0;
		matrix._32 = 0;
		matrix._33 = 0;
		quaternion.setFromRotationMatrix(matrix);
		scale.x = sx;
		scale.y = sy;
		scale.z = sz;
		return this;
	}

	public function setPosition(v:Vec4) {
		_30 = v.x;
		_31 = v.y;
		_32 = v.z;
		return this;
	}

	public function makeRotationFromQuaternion(q:Quat) {
		var x = q.x, y = q.y, z = q.z, w = q.w;
		var x2 = x + x, y2 = y + y, z2 = z + z;
		var xx = x * x2, xy = x * y2, xz = x * z2;
		var yy = y * y2, yz = y * z2, zz = z * z2;
		var wx = w * x2, wy = w * y2, wz = w * z2;

		_00 = 1 - ( yy + zz );
		_10 = xy - wz;
		_20 = xz + wy;

		_01 = xy + wz;
		_11 = 1 - ( xx + zz );
		_21 = yz - wx;

		_02 = xz - wy;
		_12 = yz + wx;
		_22 = 1 - ( xx + yy );

		// last column
		_03 = 0;
		_13 = 0;
		_23 = 0;

		// bottom row
		_30 = 0;
		_31 = 0;
		_32 = 0;
		_33 = 1;

		return this;
	}

	public static function identity():Mat4 {
		return new Mat4(
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		);
	}

	public static function fromArray(a:Array<Float>) {
		return new Mat4(
			a[0], a[1], a[2], a[3],
			a[4], a[5], a[6], a[7],
			a[8], a[9], a[10], a[11],
			a[12], a[13], a[14], a[15]
		);
	}

	public function setIdentity() {
		_00 = 1.0; _01 = 0.0; _02 = 0.0; _03 = 0.0;
		_10 = 0.0; _11 = 1.0; _12 = 0.0; _13 = 0.0;
		_20 = 0.0; _21 = 0.0; _22 = 1.0; _23 = 0.0;
		_30 = 0.0; _31 = 0.0; _32 = 0.0; _33 = 1.0;
	}

	public function initTranslate(x = 0.0, y = 0.0, z = 0.0) {
		_00 = 1.0; _01 = 0.0; _02 = 0.0; _03 = 0.0;
		_10 = 0.0; _11 = 1.0; _12 = 0.0; _13 = 0.0;
		_20 = 0.0; _21 = 0.0; _22 = 1.0; _23 = 0.0;
		_30 = x;   _31 = y;   _32 = z;   _33 = 1.0;
	}
	
	public function translate(x = 0.0, y = 0.0, z = 0.0) {
		_00 += x * _03;
		_01 += y * _03;
		_02 += z * _03;
		_10 += x * _13;
		_11 += y * _13;
		_12 += z * _13;
		_20 += x * _23;
		_21 += y * _23;
		_22 += z * _23;
		_30 += x * _33;
		_31 += y * _33;
		_32 += z * _33;
	}
	
	public function scale(v:Vec4) {
		_00 *= v.x;
		_01 *= v.x;
		_02 *= v.x;
		_03 *= v.x;

		_10 *= v.y;
		_11 *= v.y;
		_12 *= v.y;
		_13 *= v.y;

		_20 *= v.z;
		_21 *= v.z;
		_22 *= v.z;
		_23 *= v.z;
	}
	
	public function multiply3x4(a:Mat4, b:Mat4) {
		var m11 = a._00; var m12 = a._01; var m13 = a._02;
		var m21 = a._10; var m22 = a._11; var m23 = a._12;
		var a31 = a._20; var a32 = a._21; var a33 = a._22;
		var a41 = a._30; var a42 = a._31; var a43 = a._32;
		var b11 = b._00; var b12 = b._01; var b13 = b._02;
		var b21 = b._10; var b22 = b._11; var b23 = b._12;
		var b31 = b._20; var b32 = b._21; var b33 = b._22;
		var b41 = b._30; var b42 = b._31; var b43 = b._32;

		_00 = m11 * b11 + m12 * b21 + m13 * b31;
		_01 = m11 * b12 + m12 * b22 + m13 * b32;
		_02 = m11 * b13 + m12 * b23 + m13 * b33;
		_03 = 0;

		_10 = m21 * b11 + m22 * b21 + m23 * b31;
		_11 = m21 * b12 + m22 * b22 + m23 * b32;
		_12 = m21 * b13 + m22 * b23 + m23 * b33;
		_13 = 0;

		_20 = a31 * b11 + a32 * b21 + a33 * b31;
		_21 = a31 * b12 + a32 * b22 + a33 * b32;
		_22 = a31 * b13 + a32 * b23 + a33 * b33;
		_23 = 0;

		_30 = a41 * b11 + a42 * b21 + a43 * b31 + b41;
		_31 = a41 * b12 + a42 * b22 + a43 * b32 + b42;
		_32 = a41 * b13 + a42 * b23 + a43 * b33 + b43;
		_33 = 1;
	}

	public function mult2(b:Mat4) {
		multiply(this, b);
	}

	public function multiply(a:Mat4, b:Mat4) {
		var a11 = a._00; var a12 = a._01; var a13 = a._02; var a14 = a._03;
		var a21 = a._10; var a22 = a._11; var a23 = a._12; var a24 = a._13;
		var a31 = a._20; var a32 = a._21; var a33 = a._22; var a34 = a._23;
		var a41 = a._30; var a42 = a._31; var a43 = a._32; var a44 = a._33;
		var b11 = b._00; var b12 = b._01; var b13 = b._02; var b14 = b._03;
		var b21 = b._10; var b22 = b._11; var b23 = b._12; var b24 = b._13;
		var b31 = b._20; var b32 = b._21; var b33 = b._22; var b34 = b._23;
		var b41 = b._30; var b42 = b._31; var b43 = b._32; var b44 = b._33;

		_00 = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
		_01 = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
		_02 = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
		_03 = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

		_10 = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
		_11 = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
		_12 = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
		_13 = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

		_20 = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
		_21 = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
		_22 = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
		_23 = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

		_30 = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
		_31 = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
		_32 = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
		_33 = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;
	}
	
	public function inverse2(m:Mat4) {
		var m11 = m._00; var m12 = m._01; var m13 = m._02; var m14 = m._03;
		var m21 = m._10; var m22 = m._11; var m23 = m._12; var m24 = m._13;
		var m31 = m._20; var m32 = m._21; var m33 = m._22; var m34 = m._23;
		var m41 = m._30; var m42 = m._31; var m43 = m._32; var m44 = m._33;

		_00 =  m22 * m33 * m44 - m22 * m34 * m43 - m32 * m23 * m44 + m32 * m24 * m43 + m42 * m23 * m34 - m42 * m24 * m33;
		_01 = -m12 * m33 * m44 + m12 * m34 * m43 + m32 * m13 * m44 - m32 * m14 * m43 - m42 * m13 * m34 + m42 * m14 * m33;
		_02 =  m12 * m23 * m44 - m12 * m24 * m43 - m22 * m13 * m44 + m22 * m14 * m43 + m42 * m13 * m24 - m42 * m14 * m23;
		_03 = -m12 * m23 * m34 + m12 * m24 * m33 + m22 * m13 * m34 - m22 * m14 * m33 - m32 * m13 * m24 + m32 * m14 * m23;
		_10 = -m21 * m33 * m44 + m21 * m34 * m43 + m31 * m23 * m44 - m31 * m24 * m43 - m41 * m23 * m34 + m41 * m24 * m33;
		_11 =  m11 * m33 * m44 - m11 * m34 * m43 - m31 * m13 * m44 + m31 * m14 * m43 + m41 * m13 * m34 - m41 * m14 * m33;
		_12 = -m11 * m23 * m44 + m11 * m24 * m43 + m21 * m13 * m44 - m21 * m14 * m43 - m41 * m13 * m24 + m41 * m14 * m23;
		_13 =  m11 * m23 * m34 - m11 * m24 * m33 - m21 * m13 * m34 + m21 * m14 * m33 + m31 * m13 * m24 - m31 * m14 * m23;
		_20 =  m21 * m32 * m44 - m21 * m34 * m42 - m31 * m22 * m44 + m31 * m24 * m42 + m41 * m22 * m34 - m41 * m24 * m32;
		_21 = -m11 * m32 * m44 + m11 * m34 * m42 + m31 * m12 * m44 - m31 * m14 * m42 - m41 * m12 * m34 + m41 * m14 * m32;
		_22 =  m11 * m22 * m44 - m11 * m24 * m42 - m21 * m12 * m44 + m21 * m14 * m42 + m41 * m12 * m24 - m41 * m14 * m22;
		_23 = -m11 * m22 * m34 + m11 * m24 * m32 + m21 * m12 * m34 - m21 * m14 * m32 - m31 * m12 * m24 + m31 * m14 * m22;
		_30 = -m21 * m32 * m43 + m21 * m33 * m42 + m31 * m22 * m43 - m31 * m23 * m42 - m41 * m22 * m33 + m41 * m23 * m32;
		_31 =  m11 * m32 * m43 - m11 * m33 * m42 - m31 * m12 * m43 + m31 * m13 * m42 + m41 * m12 * m33 - m41 * m13 * m32;
		_32 = -m11 * m22 * m43 + m11 * m23 * m42 + m21 * m12 * m43 - m21 * m13 * m42 - m41 * m12 * m23 + m41 * m13 * m22;
		_33 =  m11 * m22 * m33 - m11 * m23 * m32 - m21 * m12 * m33 + m21 * m13 * m32 + m31 * m12 * m23 - m31 * m13 * m22;

		var det = m11 * _00 + m12 * _10 + m13 * _20 + m14 * _30;
		
		if (std.Math.abs(det) < 1e-10) { // EPSILON
			_00 = _01 = _02 = _03 = _10 = _11 = _12 = _13 = _20 = _21 = _22 = _23 = _30 = _31 = _32 = _33 = 0.0;
			return;
		}

		det = 1.0 / det;
		_00 *= det;
		_01 *= det;
		_02 *= det;
		_03 *= det;
		_10 *= det;
		_11 *= det;
		_12 *= det;
		_13 *= det;
		_20 *= det;
		_21 *= det;
		_22 *= det;
		_23 *= det;
		_30 *= det;
		_31 *= det;
		_32 *= det;
		_33 *= det;
	}

	public function transpose2() {
		var tmp:Float;
		tmp = _01; _01 = _10; _10 = tmp;
		tmp = _02; _02 = _20; _20 = tmp;
		tmp = _03; _03 = _30; _30 = tmp;
		tmp = _12; _12 = _21; _21 = tmp;
		tmp = _13; _13 = _31; _31 = tmp;
		tmp = _23; _23 = _32; _32 = tmp;
	}
	
	public function transpose23x3() {
		var tmp:Float;
		tmp = _01; _01 = _10; _10 = tmp;
		tmp = _02; _02 = _20; _20 = tmp;
		tmp = _12; _12 = _21; _21 = tmp;
	}

	public function clone() {
		var m = Mat4.identity();
		m._00 = _00; m._01 = _01; m._02 = _02; m._03 = _03;
		m._10 = _10; m._11 = _11; m._12 = _12; m._13 = _13;
		m._20 = _20; m._21 = _21; m._22 = _22; m._23 = _23;
		m._30 = _30; m._31 = _31; m._32 = _32; m._33 = _33;
		return m;
	}

	public function load(a:Array<Float>) {
		_00 = a[0];  _10 = a[1];  _20 = a[2];  _30 = a[3];
		_01 = a[4];  _11 = a[5];  _21 = a[6];  _31 = a[7];
		_02 = a[8];  _12 = a[9];  _22 = a[10]; _32 = a[11];
		_03 = a[12]; _13 = a[13]; _23 = a[14]; _33 = a[15];
	}

	public function loadFrom(m:Mat4) {		
		_00 = m._00; _01 = m._01; _02 = m._02; _03 = m._03;		
		_10 = m._10; _11 = m._11; _12 = m._12; _13 = m._13;		
		_20 = m._20; _21 = m._21; _22 = m._22; _23 = m._23;		
		_30 = m._30; _31 = m._31; _32 = m._32; _33 = m._33;		
	}

	// Retrieves location vector from matrix
	public inline function loc(v:Vec4 = null):Vec4 {
		if (v == null)
			return new Vec4(_30, _31 , _32 , _33);
		else {
			v.x = _30;
			v.y = _31;
			v.z = _32;
			v.w = _33;
			return v;
		}
	}

	public function scaleV():Vec4 {
		return new Vec4(
			std.Math.sqrt(_00*_00 + _10*_10 + _20*_20),
			std.Math.sqrt(_01*_01 + _11*_11 + _21*_21),
			std.Math.sqrt(_02*_02 + _12*_12 + _22*_22)
		);
	}
	
	public inline function up(?v:Vec4) {
		if (v == null)
			return new Vec4(_20, _21 , _22 , _23);
		else {
			v.x = _20;
			v.y = _21;
			v.z = _22;
			v.w = _23;
			return v;
		}
	}

	public function getInverse(m:Mat4) {
		// based on http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm

		var n11 = m._00, n12 = m._10, n13 = m._20, n14 = m._30;
		var n21 = m._01, n22 = m._11, n23 = m._21, n24 = m._31;
		var n31 = m._02, n32 = m._12, n33 = m._22, n34 = m._32;
		var n41 = m._03, n42 = m._13, n43 = m._23, n44 = m._33;

		_00 = n23*n34*n42 - n24*n33*n42 + n24*n32*n43 - n22*n34*n43 - n23*n32*n44 + n22*n33*n44;
		_10 = n14*n33*n42 - n13*n34*n42 - n14*n32*n43 + n12*n34*n43 + n13*n32*n44 - n12*n33*n44;
		_20 = n13*n24*n42 - n14*n23*n42 + n14*n22*n43 - n12*n24*n43 - n13*n22*n44 + n12*n23*n44;
		_30 = n14*n23*n32 - n13*n24*n32 - n14*n22*n33 + n12*n24*n33 + n13*n22*n34 - n12*n23*n34;
		_01 = n24*n33*n41 - n23*n34*n41 - n24*n31*n43 + n21*n34*n43 + n23*n31*n44 - n21*n33*n44;
		_11 = n13*n34*n41 - n14*n33*n41 + n14*n31*n43 - n11*n34*n43 - n13*n31*n44 + n11*n33*n44;
		_21 = n14*n23*n41 - n13*n24*n41 - n14*n21*n43 + n11*n24*n43 + n13*n21*n44 - n11*n23*n44;
		_31 = n13*n24*n31 - n14*n23*n31 + n14*n21*n33 - n11*n24*n33 - n13*n21*n34 + n11*n23*n34;
		_02 = n22*n34*n41 - n24*n32*n41 + n24*n31*n42 - n21*n34*n42 - n22*n31*n44 + n21*n32*n44;
		_12 = n14*n32*n41 - n12*n34*n41 - n14*n31*n42 + n11*n34*n42 + n12*n31*n44 - n11*n32*n44;
		_22 = n12*n24*n41 - n14*n22*n41 + n14*n21*n42 - n11*n24*n42 - n12*n21*n44 + n11*n22*n44;
		_32 = n14*n22*n31 - n12*n24*n31 - n14*n21*n32 + n11*n24*n32 + n12*n21*n34 - n11*n22*n34;
		_03 = n23*n32*n41 - n22*n33*n41 - n23*n31*n42 + n21*n33*n42 + n22*n31*n43 - n21*n32*n43;
		_13 = n12*n33*n41 - n13*n32*n41 + n13*n31*n42 - n11*n33*n42 - n12*n31*n43 + n11*n32*n43;
		_23 = n13*n22*n41 - n12*n23*n41 - n13*n21*n42 + n11*n23*n42 + n12*n21*n43 - n11*n22*n43;
		_33 = n12*n23*n31 - n13*n22*n31 + n13*n21*n32 - n11*n23*n32 - n12*n21*n33 + n11*n22*n33;

		var det = n11 * _00 + n21 * _10 + n31 * _20 + n41 * _30;

		if (det == 0) {
			this.setIdentity();
			return this;
		}

		this.multiplyScalar(1 / det);

		return this;
	}

	public function multiplyScalar(s:Float):Mat4 {
		_00 *= s; _10 *= s; _20 *= s; _30 *= s;
		_01 *= s; _11 *= s; _21 *= s; _31 *= s;
		_02 *= s; _12 *= s; _22 *= s; _32 *= s;
		_03 *= s; _13 *= s; _23 *= s; _33 *= s;

		return this;
	}

	public function multiplyMatrices(a:Mat4, b:Mat4):Mat4 {
		var a11 = a._00, a12 = a._10, a13 = a._20, a14 = a._30;
		var a21 = a._01, a22 = a._11, a23 = a._21, a24 = a._31;
		var a31 = a._02, a32 = a._12, a33 = a._22, a34 = a._32;
		var a41 = a._03, a42 = a._13, a43 = a._23, a44 = a._33;

		var b11 = b._00, b12 = b._10, b13 = b._20, b14 = b._30;
		var b21 = b._01, b22 = b._11, b23 = b._21, b24 = b._31;
		var b31 = b._02, b32 = b._12, b33 = b._22, b34 = b._32;
		var b41 = b._03, b42 = b._13, b43 = b._23, b44 = b._33;

		_00 = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
		_10 = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
		_20 = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
		_30 = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

		_01 = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
		_11 = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
		_21 = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
		_31 = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

		_02 = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
		_12 = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
		_22 = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
		_32 = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

		_03 = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
		_13 = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
		_23 = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
		_33 = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;

		return this;
	}

	public function toRotation():Mat4 {
		var v1 = new Vec4();
		var scaleX = 1 / v1.set(_00, _01, _02).length();
		var scaleY = 1 / v1.set(_10, _11, _12).length();
		var scaleZ = 1 / v1.set(_20, _21, _22).length();

		_00 = _00 * scaleX;
		_01 = _01 * scaleX;
		_02 = _02 * scaleX;
		_03 = 0;

		_10 = _10 * scaleY;
		_11 = _11 * scaleY;
		_12 = _12 * scaleY;
		_13 = 0;

		_20 = _20 * scaleZ;
		_21 = _21 * scaleZ;
		_22 = _22 * scaleZ;
		_23 = 0;

		_30 = 0;
		_31 = 0;
		_32 = 0;
		_33 = 1;

		return this;
	}

	public function getQuat():Quat {
		// assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)
		var m = clone();
		m.toRotation();
				
		var q:Quat = new Quat();

		var m11 = _00;
		var m12 = _10;
		var m13 = _20;
		var m21 = _01;
		var m22 = _11;
		var m23 = _21;
		var m31 = _02;
		var m32 = _12;
		var m33 = _22;

		var ftrace = m11 + m22 + m33;
		var s:Float = 0;

		if ( ftrace > 0 ) {
			s = 0.5 / std.Math.sqrt( ftrace + 1.0 );
			q.w = 0.25 / s;
			q.x = ( m32 - m23 ) * s;
			q.y = ( m13 - m31 ) * s;
			q.z = ( m21 - m12 ) * s;

		}
		else if ( m11 > m22 && m11 > m33 ) {
			s = 2.0 * std.Math.sqrt( 1.0 + m11 - m22 - m33 );
			q.w = ( m32 - m23 ) / s;
			q.x = 0.25 * s;
			q.y = ( m12 + m21 ) / s;
			q.z = ( m13 + m31 ) / s;

		}
		else if ( m22 > m33 ) {
			s = 2.0 * std.Math.sqrt( 1.0 + m22 - m11 - m33 );
			q.w = ( m13 - m31 ) / s;
			q.x = ( m12 + m21 ) / s;
			q.y = 0.25 * s;
			q.z = ( m23 + m32 ) / s;

		}
		else {
			s = 2.0 * std.Math.sqrt( 1.0 + m33 - m11 - m22 );
			q.w = ( m21 - m12 ) / s;
			q.x = ( m13 + m31 ) / s;
			q.y = ( m23 + m32 ) / s;
			q.z = 0.25 * s;
		}
		return q;
	}

	public function getScale():Vec4 {
		var sx:Float = std.Math.sqrt(_00 * _00 + _01 * _01 + _02 * _02);
		var sy:Float = std.Math.sqrt(_10 * _10 + _11 * _11 + _12 * _12);
		var sz:Float = std.Math.sqrt(_20 * _20 + _21 * _21 + _22 * _22);
		return new Vec4(sx, sy, sz);
	}

	public static function perspective(fovY:Float, aspect:Float, zn:Float, zf:Float):Mat4 {
		var uh = 1.0 / std.Math.tan(fovY / 2);
		var uw = uh / aspect;
		return new Mat4(
			uw, 0, 0, 0,
			0, uh, 0, 0,
			0, 0, (zf + zn) / (zn - zf), 2 * zf * zn / (zn - zf),
			0, 0, -1, 0
		);
	}

	public static function orthogonal(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float, orthoScale:Float = 7.314):Mat4 {
		var w = right - left;
		var h = top - bottom;
		var p = far - near;

		var x = (right + left) / w;
		var y = (top + bottom) / h;
		var z = (far + near) / p;

		return new Mat4(
			orthoScale / w,	0,				0,				-x,
			0,				orthoScale / h,	0,				-y,
			0,				0,				-orthoScale / p,-z,
			0,				0,				0,				1
		);
	}
	
	public static function lookAt(_eye:Vec4, _centre:Vec4, _up:Null<Vec4> = null):Mat4 {
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
		var n = 1 / std.Math.sqrt(f0 * f0 + f1 * f1 + f2 * f2);
		f0 *= n;
		f1 *= n;
		f2 *= n;

		var s0 = f1 * u2 - f2 * u1;
		var s1 = f2 * u0 - f0 * u2;
		var s2 = f0 * u1 - f1 * u0;
		n = 1 / std.Math.sqrt(s0 * s0 + s1 * s1 + s2 * s2);
		s0 *= n;
		s1 *= n;
		s2 *= n;

		u0 = s1 * f2 - s2 * f1;
		u1 = s2 * f0 - s0 * f2;
		u2 = s0 * f1 - s1 * f0;

		var d0 = -e0 * s0 - e1 * s1 - e2 * s2;
		var d1 = -e0 * u0 - e1 * u1 - e2 * u2;
		var d2 =  e0 * f0 + e1 * f1 + e2 * f2;
						
		return new Mat4( s0,  s1,  s2, d0,
						 u0,  u1,  u2, d1,
						-f0, -f1, -f2, d2,
						0.0, 0.0, 0.0, 1.0);
	}
	
	public inline function _right():Vec4 { return new Vec4(_00, _10, _20); }
	public inline function _up():Vec4 { return new Vec4(_01, _11, _21); }
	public inline function _look():Vec4 { return new Vec4(_02, _12, _22); }
}
