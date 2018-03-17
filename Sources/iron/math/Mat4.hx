package iron.math;

import kha.FastFloat;
import iron.data.SceneFormat;

class Mat4 {

	public var self:kha.math.FastMatrix4;

	static var helpVec = new Vec4();
	static var helpMat = Mat4.identity();

	public function new(_00:FastFloat, _10:FastFloat, _20:FastFloat, _30:FastFloat,
						_01:FastFloat, _11:FastFloat, _21:FastFloat, _31:FastFloat,
						_02:FastFloat, _12:FastFloat, _22:FastFloat, _32:FastFloat,
						_03:FastFloat, _13:FastFloat, _23:FastFloat, _33:FastFloat) {
		
		self = new kha.math.FastMatrix4(_00, _10, _20, _30, _01, _11, _21, _31, _02, _12, _22, _32, _03, _13, _23, _33);
	}

	public function compose(location:Vec4, quaternion:Quat, sc:Vec4):Mat4 {
		fromQuaternion(quaternion);
		scale(sc);
		setLocation(location);
		return this;
	}

	public function decompose(location:Vec4, quaternion:Quat, scale:Vec4):Mat4 {
		helpVec.w = 0.0;
		var sx = helpVec.set(_00, _01, _02).length();
		var sy = helpVec.set(_10, _11, _12).length();
		var sz = helpVec.set(_20, _21, _22).length();
		var det = self.determinant();
		if (det < 0.0) sx = -sx;
		location.x = _30; location.y = _31; location.z = _32;
		// Scale the rotation part
		helpMat._00 = _00; helpMat._10 = _10; helpMat._20 = _20; helpMat._30 = _30;
		helpMat._01 = _01; helpMat._11 = _11; helpMat._21 = _21; helpMat._31 = _31;
		helpMat._02 = _02; helpMat._12 = _12; helpMat._22 = _22; helpMat._32 = _32;
		helpMat._03 = _03; helpMat._13 = _13; helpMat._23 = _23; helpMat._33 = _33;
		var invSX = 1.0 / sx;
		var invSY = 1.0 / sy;
		var invSZ = 1.0 / sz;
		helpMat._00 *= invSX;
		helpMat._01 *= invSX;
		helpMat._02 *= invSX;
		helpMat._03 = 0.0;
		helpMat._10 *= invSY;
		helpMat._11 *= invSY;
		helpMat._12 *= invSY;
		helpMat._13 = 0.0;
		helpMat._20 *= invSZ;
		helpMat._21 *= invSZ;
		helpMat._22 *= invSZ;
		helpMat._23 = 0.0;
		helpMat._30 = 0.0;
		helpMat._31 = 0.0;
		helpMat._32 = 0.0;
		helpMat._33 = 0.0;
		quaternion.fromRotationMat(helpMat);
		scale.x = sx; scale.y = sy; scale.z = sz;
		return this;
	}

	public function setLocation(v:Vec4):Mat4 {
		_30 = v.x;
		_31 = v.y;
		_32 = v.z;
		return this;
	}

	public function fromQuaternion(q:Quat):Mat4 {
		var x = q.x, y = q.y, z = q.z, w = q.w;
		var x2 = x + x, y2 = y + y, z2 = z + z;
		var xx = x * x2, xy = x * y2, xz = x * z2;
		var yy = y * y2, yz = y * z2, zz = z * z2;
		var wx = w * x2, wy = w * y2, wz = w * z2;

		_00 = 1.0 - (yy + zz);
		_10 = xy - wz;
		_20 = xz + wy;

		_01 = xy + wz;
		_11 = 1.0 - (xx + zz);
		_21 = yz - wx;

		_02 = xz - wy;
		_12 = yz + wx;
		_22 = 1.0 - (xx + yy);

		_03 = 0.0; _13 = 0.0; _23 = 0.0;
		_30 = 0.0; _31 = 0.0; _32 = 0.0; _33 = 1.0;

		return this;
	}

	public static function identity():Mat4 {
		return new Mat4(
			1.0, 0.0, 0.0, 0.0,
			0.0, 1.0, 0.0, 0.0,
			0.0, 0.0, 1.0, 0.0,
			0.0, 0.0, 0.0, 1.0
		);
	}

	public static function fromArray(a:Array<FastFloat>, offset = 0):Mat4 {
		return new Mat4(
			a[0 + offset], a[1 + offset], a[2 + offset], a[3 + offset],
			a[4 + offset], a[5 + offset], a[6 + offset], a[7 + offset],
			a[8 + offset], a[9 + offset], a[10 + offset], a[11 + offset],
			a[12 + offset], a[13 + offset], a[14 + offset], a[15 + offset]
		);
	}

	public static function fromFloat32Array(a:TFloat32Array, offset = 0):Mat4 {
		return new Mat4(
			a[0 + offset], a[1 + offset], a[2 + offset], a[3 + offset],
			a[4 + offset], a[5 + offset], a[6 + offset], a[7 + offset],
			a[8 + offset], a[9 + offset], a[10 + offset], a[11 + offset],
			a[12 + offset], a[13 + offset], a[14 + offset], a[15 + offset]
		);
	}

	public function toArray():Array<FastFloat> {
		return [
			_00, _10, _20, _30,
			_01, _11, _21, _31,
			_02, _12, _22, _32,
			_03, _13, _23, _33
		];
	}

	public function setIdentity():Mat4 {
		_00 = 1.0; _01 = 0.0; _02 = 0.0; _03 = 0.0;
		_10 = 0.0; _11 = 1.0; _12 = 0.0; _13 = 0.0;
		_20 = 0.0; _21 = 0.0; _22 = 1.0; _23 = 0.0;
		_30 = 0.0; _31 = 0.0; _32 = 0.0; _33 = 1.0;
		return this;
	}

	public function initTranslate(x = 0.0, y = 0.0, z = 0.0) {
		_00 = 1.0; _01 = 0.0; _02 = 0.0; _03 = 0.0;
		_10 = 0.0; _11 = 1.0; _12 = 0.0; _13 = 0.0;
		_20 = 0.0; _21 = 0.0; _22 = 1.0; _23 = 0.0;
		_30 = x;   _31 = y;   _32 = z;   _33 = 1.0;
	}
	
	public function translate(x = 0.0, y = 0.0, z = 0.0) {
		_00 += x * _03; _01 += y * _03; _02 += z * _03;
		_10 += x * _13; _11 += y * _13; _12 += z * _13;
		_20 += x * _23; _21 += y * _23; _22 += z * _23;
		_30 += x * _33; _31 += y * _33; _32 += z * _33;
	}
	
	public function scale(v:Vec4) {
		_00 *= v.x; _01 *= v.x; _02 *= v.x; _03 *= v.x;
		_10 *= v.y; _11 *= v.y; _12 *= v.y; _13 *= v.y;
		_20 *= v.z; _21 *= v.z; _22 *= v.z; _23 *= v.z;
	}
	
	public function multmat3x4(a:Mat4, b:Mat4) {
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
		_03 = 0.0;

		_10 = m21 * b11 + m22 * b21 + m23 * b31;
		_11 = m21 * b12 + m22 * b22 + m23 * b32;
		_12 = m21 * b13 + m22 * b23 + m23 * b33;
		_13 = 0.0;

		_20 = a31 * b11 + a32 * b21 + a33 * b31;
		_21 = a31 * b12 + a32 * b22 + a33 * b32;
		_22 = a31 * b13 + a32 * b23 + a33 * b33;
		_23 = 0.0;

		_30 = a41 * b11 + a42 * b21 + a43 * b31 + b41;
		_31 = a41 * b12 + a42 * b22 + a43 * b32 + b42;
		_32 = a41 * b13 + a42 * b23 + a43 * b33 + b43;
		_33 = 1.0;
	}

	public function multmat(m:Mat4):Mat4 {
		return new Mat4(
			_00 * m._00 + _10 * m._01 + _20 * m._02 + _30 * m._03, _00 * m._10 + _10 * m._11 + _20 * m._12 + _30 * m._13, _00 * m._20 + _10 * m._21 + _20 * m._22 + _30 * m._23, _00 * m._30 + _10 * m._31 + _20 * m._32 + _30 * m._33,
			_01 * m._00 + _11 * m._01 + _21 * m._02 + _31 * m._03, _01 * m._10 + _11 * m._11 + _21 * m._12 + _31 * m._13, _01 * m._20 + _11 * m._21 + _21 * m._22 + _31 * m._23, _01 * m._30 + _11 * m._31 + _21 * m._32 + _31 * m._33,
			_02 * m._00 + _12 * m._01 + _22 * m._02 + _32 * m._03, _02 * m._10 + _12 * m._11 + _22 * m._12 + _32 * m._13, _02 * m._20 + _12 * m._21 + _22 * m._22 + _32 * m._23, _02 * m._30 + _12 * m._31 + _22 * m._32 + _32 * m._33,
			_03 * m._00 + _13 * m._01 + _23 * m._02 + _33 * m._03, _03 * m._10 + _13 * m._11 + _23 * m._12 + _33 * m._13, _03 * m._20 + _13 * m._21 + _23 * m._22 + _33 * m._23, _03 * m._30 + _13 * m._31 + _23 * m._32 + _33 * m._33
		);
	}

	public function multmat2(m:Mat4):Mat4 {
		var a11 = _00; var a12 = _01; var a13 = _02; var a14 = _03;
		var a21 = _10; var a22 = _11; var a23 = _12; var a24 = _13;
		var a31 = _20; var a32 = _21; var a33 = _22; var a34 = _23;
		var a41 = _30; var a42 = _31; var a43 = _32; var a44 = _33;
		var b11 = m._00; var b12 = m._01; var b13 = m._02; var b14 = m._03;
		var b21 = m._10; var b22 = m._11; var b23 = m._12; var b24 = m._13;
		var b31 = m._20; var b32 = m._21; var b33 = m._22; var b34 = m._23;
		var b41 = m._30; var b42 = m._31; var b43 = m._32; var b44 = m._33;

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
		return this;
	}

	public function multmats(a:Mat4, b:Mat4):Mat4 {
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

	public function getInverse(m:Mat4):Mat4 {
		var n11 = m._00, n12 = m._10, n13 = m._20, n14 = m._30;
		var n21 = m._01, n22 = m._11, n23 = m._21, n24 = m._31;
		var n31 = m._02, n32 = m._12, n33 = m._22, n34 = m._32;
		var n41 = m._03, n42 = m._13, n43 = m._23, n44 = m._33;

		_00 = (n23 * n34 * n42) - (n24 * n33 * n42) + (n24 * n32 * n43) - (n22 * n34 * n43) - (n23 * n32 * n44) + (n22 * n33 * n44);
		_10 = (n14 * n33 * n42) - (n13 * n34 * n42) - (n14 * n32 * n43) + (n12 * n34 * n43) + (n13 * n32 * n44) - (n12 * n33 * n44);
		_20 = (n13 * n24 * n42) - (n14 * n23 * n42) + (n14 * n22 * n43) - (n12 * n24 * n43) - (n13 * n22 * n44) + (n12 * n23 * n44);
		_30 = (n14 * n23 * n32) - (n13 * n24 * n32) - (n14 * n22 * n33) + (n12 * n24 * n33) + (n13 * n22 * n34) - (n12 * n23 * n34);
		_01 = (n24 * n33 * n41) - (n23 * n34 * n41) - (n24 * n31 * n43) + (n21 * n34 * n43) + (n23 * n31 * n44) - (n21 * n33 * n44);
		_11 = (n13 * n34 * n41) - (n14 * n33 * n41) + (n14 * n31 * n43) - (n11 * n34 * n43) - (n13 * n31 * n44) + (n11 * n33 * n44);
		_21 = (n14 * n23 * n41) - (n13 * n24 * n41) - (n14 * n21 * n43) + (n11 * n24 * n43) + (n13 * n21 * n44) - (n11 * n23 * n44);
		_31 = (n13 * n24 * n31) - (n14 * n23 * n31) + (n14 * n21 * n33) - (n11 * n24 * n33) - (n13 * n21 * n34) + (n11 * n23 * n34);
		_02 = (n22 * n34 * n41) - (n24 * n32 * n41) + (n24 * n31 * n42) - (n21 * n34 * n42) - (n22 * n31 * n44) + (n21 * n32 * n44);
		_12 = (n14 * n32 * n41) - (n12 * n34 * n41) - (n14 * n31 * n42) + (n11 * n34 * n42) + (n12 * n31 * n44) - (n11 * n32 * n44);
		_22 = (n12 * n24 * n41) - (n14 * n22 * n41) + (n14 * n21 * n42) - (n11 * n24 * n42) - (n12 * n21 * n44) + (n11 * n22 * n44);
		_32 = (n14 * n22 * n31) - (n12 * n24 * n31) - (n14 * n21 * n32) + (n11 * n24 * n32) + (n12 * n21 * n34) - (n11 * n22 * n34);
		_03 = (n23 * n32 * n41) - (n22 * n33 * n41) - (n23 * n31 * n42) + (n21 * n33 * n42) + (n22 * n31 * n43) - (n21 * n32 * n43);
		_13 = (n12 * n33 * n41) - (n13 * n32 * n41) + (n13 * n31 * n42) - (n11 * n33 * n42) - (n12 * n31 * n43) + (n11 * n32 * n43);
		_23 = (n13 * n22 * n41) - (n12 * n23 * n41) - (n13 * n21 * n42) + (n11 * n23 * n42) + (n12 * n21 * n43) - (n11 * n22 * n43);
		_33 = (n12 * n23 * n31) - (n13 * n22 * n31) + (n13 * n21 * n32) - (n11 * n23 * n32) - (n12 * n21 * n33) + (n11 * n22 * n33);

		var det = n11 * _00 + n21 * _10 + n31 * _20 + n41 * _30;
		if (det == 0.0) return setIdentity();
		this.mult(1.0 / det);
		return this;
	}

	public function transpose() {
		var tmp:Float;
		tmp = _01; _01 = _10; _10 = tmp;
		tmp = _02; _02 = _20; _20 = tmp;
		tmp = _03; _03 = _30; _30 = tmp;
		tmp = _12; _12 = _21; _21 = tmp;
		tmp = _13; _13 = _31; _31 = tmp;
		tmp = _23; _23 = _32; _32 = tmp;
	}
	
	public function transpose3x3() {
		var tmp:Float;
		tmp = _01; _01 = _10; _10 = tmp;
		tmp = _02; _02 = _20; _20 = tmp;
		tmp = _12; _12 = _21; _21 = tmp;
	}

	public function clone():Mat4 {
		var m = Mat4.identity();
		m._00 = _00; m._01 = _01; m._02 = _02; m._03 = _03;
		m._10 = _10; m._11 = _11; m._12 = _12; m._13 = _13;
		m._20 = _20; m._21 = _21; m._22 = _22; m._23 = _23;
		m._30 = _30; m._31 = _31; m._32 = _32; m._33 = _33;
		return m;
	}

	public function init(_00:FastFloat, _10:FastFloat, _20:FastFloat, _30:FastFloat,
						 _01:FastFloat, _11:FastFloat, _21:FastFloat, _31:FastFloat,
						 _02:FastFloat, _12:FastFloat, _22:FastFloat, _32:FastFloat,
						 _03:FastFloat, _13:FastFloat, _23:FastFloat, _33:FastFloat) {
		this._00 = _00; this._10 = _10; this._20 = _20; this._30 = _30;
		this._01 = _01; this._11 = _11; this._21 = _21; this._31 = _31;
		this._02 = _02; this._12 = _12; this._22 = _22; this._32 = _32;
		this._03 = _03; this._13 = _13; this._23 = _23; this._33 = _33;
	}

	public function set(a:Array<FastFloat>, offset = 0) {
		_00 = a[0 + offset]; _10 = a[1 + offset]; _20 = a[2 + offset]; _30 = a[3 + offset];
		_01 = a[4 + offset]; _11 = a[5 + offset]; _21 = a[6 + offset]; _31 = a[7 + offset];
		_02 = a[8 + offset]; _12 = a[9 + offset]; _22 = a[10 + offset];_32 = a[11 + offset];
		_03 = a[12 + offset]; _13 = a[13 + offset]; _23 = a[14 + offset]; _33 = a[15 + offset];
	}

	public function setF32(a:TFloat32Array, offset = 0) {
		_00 = a[0 + offset]; _10 = a[1 + offset]; _20 = a[2 + offset]; _30 = a[3 + offset];
		_01 = a[4 + offset]; _11 = a[5 + offset]; _21 = a[6 + offset]; _31 = a[7 + offset];
		_02 = a[8 + offset]; _12 = a[9 + offset]; _22 = a[10 + offset];_32 = a[11 + offset];
		_03 = a[12 + offset]; _13 = a[13 + offset]; _23 = a[14 + offset]; _33 = a[15 + offset];
	}

	public function setFrom(m:Mat4) {
		_00 = m._00; _01 = m._01; _02 = m._02; _03 = m._03;
		_10 = m._10; _11 = m._11; _12 = m._12; _13 = m._13;
		_20 = m._20; _21 = m._21; _22 = m._22; _23 = m._23;
		_30 = m._30; _31 = m._31; _32 = m._32; _33 = m._33;
		return this;
	}

	public inline function getLoc():Vec4 {
		return new Vec4(_30, _31 , _32 , _33);
	}

	public function getScale():Vec4 {
		return new Vec4(
			Math.sqrt(_00 * _00 + _10 * _10 + _20 * _20),
			Math.sqrt(_01 * _01 + _11 * _11 + _21 * _21),
			Math.sqrt(_02 * _02 + _12 * _12 + _22 * _22)
		);
	}

	public function mult(s:Float):Mat4 {
		_00 *= s; _10 *= s; _20 *= s; _30 *= s;
		_01 *= s; _11 *= s; _21 *= s; _31 *= s;
		_02 *= s; _12 *= s; _22 *= s; _32 *= s;
		_03 *= s; _13 *= s; _23 *= s; _33 *= s;
		return this;
	}

	public function toRotation():Mat4 {
		var v1 = new Vec4();
		var scaleX = 1.0 / v1.set(_00, _01, _02).length();
		var scaleY = 1.0 / v1.set(_10, _11, _12).length();
		var scaleZ = 1.0 / v1.set(_20, _21, _22).length();

		_00 = _00 * scaleX; _01 = _01 * scaleX; _02 = _02 * scaleX;
		_03 = 0.0;

		_10 = _10 * scaleY; _11 = _11 * scaleY; _12 = _12 * scaleY;
		_13 = 0.0;

		_20 = _20 * scaleZ; _21 = _21 * scaleZ; _22 = _22 * scaleZ;
		_23 = 0.0;

		_30 = 0.0; _31 = 0.0; _32 = 0.0; _33 = 1.0;
		return this;
	}

	public function getQuat():Quat {
		helpMat.setFrom(this);
		helpMat.toRotation();

		var q:Quat = new Quat();

		var m11 = helpMat._00;
		var m12 = helpMat._10;
		var m13 = helpMat._20;
		var m21 = helpMat._01;
		var m22 = helpMat._11;
		var m23 = helpMat._21;
		var m31 = helpMat._02;
		var m32 = helpMat._12;
		var m33 = helpMat._22;

		var ftrace = m11 + m22 + m33;
		var s = 0.0;

		if (ftrace > 0.0) {
			s = 0.5 / Math.sqrt(ftrace + 1.0);
			q.w = 0.25 / s;
			q.x = (m32 - m23) * s;
			q.y = (m13 - m31) * s;
			q.z = (m21 - m12) * s;

		}
		else if (m11 > m22 && m11 > m33) {
			s = 2.0 * Math.sqrt(1.0 + m11 - m22 - m33);
			q.w = (m32 - m23) / s;
			q.x = 0.25 * s;
			q.y = (m12 + m21) / s;
			q.z = (m13 + m31) / s;

		}
		else if (m22 > m33) {
			s = 2.0 * Math.sqrt(1.0 + m22 - m11 - m33);
			q.w = (m13 - m31) / s;
			q.x = (m12 + m21) / s;
			q.y = 0.25 * s;
			q.z = (m23 + m32) / s;

		}
		else {
			s = 2.0 * Math.sqrt(1.0 + m33 - m11 - m22);
			q.w = (m21 - m12) / s;
			q.x = (m13 + m31) / s;
			q.y = (m23 + m32) / s;
			q.z = 0.25 * s;
		}
		return q;
	}

	public static function persp(fovY:Float, aspect:Float, zn:Float, zf:Float):Mat4 {
		var uh = 1.0 / Math.tan(fovY / 2);
		var uw = uh / aspect;
		return new Mat4(
			uw, 0, 0, 0,
			0, uh, 0, 0,
			0, 0, (zf + zn) / (zn - zf), 2 * zf * zn / (zn - zf),
			0, 0, -1, 0
		);
	}

	public static function ortho(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float):Mat4 {
		var rl = right - left;
		var tb = top - bottom;
		var fn = far - near;
		var tx = -(right + left) / (rl);
		var ty = -(top + bottom) / (tb);
		var tz = -(far + near) / (fn);
		return new Mat4(
			2 / rl,	0,		0,		 tx,
			0,		2 / tb,	0,		 ty,
			0,		0,		-2 / fn, tz,
			0,		0,		0,		 1
		);
	}

	public function setLookAt(eye:Vec4, center:Vec4, up:Vec4):Mat4 {
		var f0 = center.x - eye.x;
		var f1 = center.y - eye.y;
		var f2 = center.z - eye.z;
		var n = 1.0 / Math.sqrt(f0 * f0 + f1 * f1 + f2 * f2);
		f0 *= n;
		f1 *= n;
		f2 *= n;

		var s0 = f1 * up.z - f2 * up.y;
		var s1 = f2 * up.x - f0 * up.z;
		var s2 = f0 * up.y - f1 * up.x;
		n = 1.0 / Math.sqrt(s0 * s0 + s1 * s1 + s2 * s2);
		s0 *= n;
		s1 *= n;
		s2 *= n;

		var u0 = s1 * f2 - s2 * f1;
		var u1 = s2 * f0 - s0 * f2;
		var u2 = s0 * f1 - s1 * f0;
		var d0 = -eye.x * s0 - eye.y * s1 - eye.z * s2;
		var d1 = -eye.x * u0 - eye.y * u1 - eye.z * u2;
		var d2 =  eye.x * f0 + eye.y * f1 + eye.z * f2;
		
		_00 = s0;
		_10 = s1;
		_20 = s2;
		_30 = d0;
		_01 = u0;
		_11 = u1;
		_21 = u2;
		_31 = d1;
		_02 = -f0;
		_12 = -f1;
		_22 = -f2;
		_32 = d2;
		_03 = 0.0;
		_13 = 0.0;
		_23 = 0.0;
		_33 = 1.0;
		return this;
	}

	public function applyQuat(q:Quat) {
		q.toMat(helpMat);
		multmat2(helpMat);
	}

	public function write(ar:haxe.ds.Vector<kha.FastFloat>, offset = 0) {
		ar[offset] = _00;
		ar[offset + 1] = _01;
		ar[offset + 2] = _02;
		ar[offset + 3] = _03;
		ar[offset + 4] = _10;
		ar[offset + 5] = _11;
		ar[offset + 6] = _12;
		ar[offset + 7] = _13;
		ar[offset + 8] = _20;
		ar[offset + 9] = _21;
		ar[offset + 10] = _22;
		ar[offset + 11] = _23;
		ar[offset + 12] = _30;
		ar[offset + 13] = _31;
		ar[offset + 14] = _32;
		ar[offset + 15] = _33;
	}
	
	public static function lookAt(eye:Vec4, center:Vec4, up:Vec4):Mat4 {
		return Mat4.identity().setLookAt(eye, center, up);
	}

	public inline function multvec(value: kha.math.FastVector4):kha.math.FastVector4 {
		return self.multvec(value);
	}
	
	public inline function right():Vec4 { return new Vec4(_00, _01, _02); }
	public inline function up():Vec4 { return new Vec4(_20, _21, _22); }
	public inline function look():Vec4 { return new Vec4(_10, _11, _12); }

	public var _00(get, set):FastFloat; inline function get__00():FastFloat { return self._00; } inline function set__00(f:FastFloat):FastFloat { return self._00 = f; }
	public var _01(get, set):FastFloat; inline function get__01():FastFloat { return self._01; } inline function set__01(f:FastFloat):FastFloat { return self._01 = f; }
	public var _02(get, set):FastFloat; inline function get__02():FastFloat { return self._02; } inline function set__02(f:FastFloat):FastFloat { return self._02 = f; }
	public var _03(get, set):FastFloat; inline function get__03():FastFloat { return self._03; } inline function set__03(f:FastFloat):FastFloat { return self._03 = f; }
	public var _10(get, set):FastFloat; inline function get__10():FastFloat { return self._10; } inline function set__10(f:FastFloat):FastFloat { return self._10 = f; }
	public var _11(get, set):FastFloat; inline function get__11():FastFloat { return self._11; } inline function set__11(f:FastFloat):FastFloat { return self._11 = f; }
	public var _12(get, set):FastFloat; inline function get__12():FastFloat { return self._12; } inline function set__12(f:FastFloat):FastFloat { return self._12 = f; }
	public var _13(get, set):FastFloat; inline function get__13():FastFloat { return self._13; } inline function set__13(f:FastFloat):FastFloat { return self._13 = f; }
	public var _20(get, set):FastFloat; inline function get__20():FastFloat { return self._20; } inline function set__20(f:FastFloat):FastFloat { return self._20 = f; }
	public var _21(get, set):FastFloat; inline function get__21():FastFloat { return self._21; } inline function set__21(f:FastFloat):FastFloat { return self._21 = f; }
	public var _22(get, set):FastFloat; inline function get__22():FastFloat { return self._22; } inline function set__22(f:FastFloat):FastFloat { return self._22 = f; }
	public var _23(get, set):FastFloat; inline function get__23():FastFloat { return self._23; } inline function set__23(f:FastFloat):FastFloat { return self._23 = f; }
	public var _30(get, set):FastFloat; inline function get__30():FastFloat { return self._30; } inline function set__30(f:FastFloat):FastFloat { return self._30 = f; }
	public var _31(get, set):FastFloat; inline function get__31():FastFloat { return self._31; } inline function set__31(f:FastFloat):FastFloat { return self._31 = f; }
	public var _32(get, set):FastFloat; inline function get__32():FastFloat { return self._32; } inline function set__32(f:FastFloat):FastFloat { return self._32 = f; }
	public var _33(get, set):FastFloat; inline function get__33():FastFloat { return self._33; } inline function set__33(f:FastFloat):FastFloat { return self._33 = f; }

	public function toString():String {
        return '[[$_00, $_10, $_20, $_30], [$_01, $_11, $_21, $_31], [$_02, $_12, $_22, $_32], [$_03, $_13, $_23, $_33]]';
    }
}
