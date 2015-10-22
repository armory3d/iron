package lue.math;

// https://github.com/mrdoob/three.js/

import lue.math.Math;

class Mat4 {
	
	static var tmp = new Mat4();

	public var _11:Float; // 0
	public var _12:Float; // 1
	public var _13:Float; // 2
	public var _14:Float; // 3
	public var _21:Float; // 4
	public var _22:Float; // 5
	public var _23:Float; // 6
	public var _24:Float; // 7
	public var _31:Float; // 8
	public var _32:Float; // 9
	public var _33:Float; // 10
	public var _34:Float; // 11
	public var _41:Float; // 12
	public var _42:Float; // 13
	public var _43:Float; // 14
	public var _44:Float; // 15

	var m:Array<Float> = [];

	public function new(values:Array<Float> = null) {
		if (values != null) load(values);
		else identity();

		for (i in 0...16) m.push(0);
		toBuffer();
	}

	public function zero() {
		_11 = 0.0; _12 = 0.0; _13 = 0.0; _14 = 0.0;
		_21 = 0.0; _22 = 0.0; _23 = 0.0; _24 = 0.0;
		_31 = 0.0; _32 = 0.0; _33 = 0.0; _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 0.0;
	}

	public function identity() {
		_11 = 1.0; _12 = 0.0; _13 = 0.0; _14 = 0.0;
		_21 = 0.0; _22 = 1.0; _23 = 0.0; _24 = 0.0;
		_31 = 0.0; _32 = 0.0; _33 = 1.0; _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 1.0;
	}

	public function initTranslate(x = 0.0, y = 0.0, z = 0.0) {
		_11 = 1.0; _12 = 0.0; _13 = 0.0; _14 = 0.0;
		_21 = 0.0; _22 = 1.0; _23 = 0.0; _24 = 0.0;
		_31 = 0.0; _32 = 0.0; _33 = 1.0; _34 = 0.0;
		_41 = x;   _42 = y;   _43 = z;   _44 = 1.0;
	}

	public function initScale(x = 1.0, y = 1.0, z = 1.0) {
		_11 = x;   _12 = 0.0; _13 = 0.0; _14 = 0.0;
		_21 = 0.0; _22 = y;   _23 = 0.0; _24 = 0.0;
		_31 = 0.0; _32 = 0.0; _33 = z;   _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 1.0;
	}
	
	public function initRotate(x:Float, y:Float, z:Float) {
		var cx = std.Math.cos(x);
		var sx = std.Math.sin(x);
		var cy = std.Math.cos(y);
		var sy = std.Math.sin(y);
		var cz = std.Math.cos(z);
		var sz = std.Math.sin(z);
		var cxsy = cx * sy;
		var sxsy = sx * sy;
		_11 = cy * cz;
		_12 = cy * sz;
		_13 = -sy;
		_14 = 0;
		_21 = sxsy * cz - cx * sz;
		_22 = sxsy * sz + cx * cz;
		_23 = sx * cy;
		_24 = 0;
		_31 = cxsy * cz + sx * sz;
		_32 = cxsy * sz - sx * cz;
		_33 = cx * cy;
		_34 = 0;
		_41 = 0;
		_42 = 0;
		_43 = 0;
		_44 = 1;
	}
	
	public function translate(x = 0.0, y = 0.0, z = 0.0) {
		_11 += x * _14;
		_12 += y * _14;
		_13 += z * _14;
		_21 += x * _24;
		_22 += y * _24;
		_23 += z * _24;
		_31 += x * _34;
		_32 += y * _34;
		_33 += z * _34;
		_41 += x * _44;
		_42 += y * _44;
		_43 += z * _44;
	}
	
	public function scale(v:Vec3) {
		_11 *= v.x;
		_12 *= v.x;
		_13 *= v.x;
		_14 *= v.x;

		_21 *= v.y;
		_22 *= v.y;
		_23 *= v.y;
		_24 *= v.y;

		_31 *= v.z;
		_32 *= v.z;
		_33 *= v.z;
		_34 *= v.z;
	}
	
	public function multiply3x4(a:Mat4, b:Mat4) {
		var m11 = a._11; var m12 = a._12; var m13 = a._13;
		var m21 = a._21; var m22 = a._22; var m23 = a._23;
		var a31 = a._31; var a32 = a._32; var a33 = a._33;
		var a41 = a._41; var a42 = a._42; var a43 = a._43;
		var b11 = b._11; var b12 = b._12; var b13 = b._13;
		var b21 = b._21; var b22 = b._22; var b23 = b._23;
		var b31 = b._31; var b32 = b._32; var b33 = b._33;
		var b41 = b._41; var b42 = b._42; var b43 = b._43;

		_11 = m11 * b11 + m12 * b21 + m13 * b31;
		_12 = m11 * b12 + m12 * b22 + m13 * b32;
		_13 = m11 * b13 + m12 * b23 + m13 * b33;
		_14 = 0;

		_21 = m21 * b11 + m22 * b21 + m23 * b31;
		_22 = m21 * b12 + m22 * b22 + m23 * b32;
		_23 = m21 * b13 + m22 * b23 + m23 * b33;
		_24 = 0;

		_31 = a31 * b11 + a32 * b21 + a33 * b31;
		_32 = a31 * b12 + a32 * b22 + a33 * b32;
		_33 = a31 * b13 + a32 * b23 + a33 * b33;
		_34 = 0;

		_41 = a41 * b11 + a42 * b21 + a43 * b31 + b41;
		_42 = a41 * b12 + a42 * b22 + a43 * b32 + b42;
		_43 = a41 * b13 + a42 * b23 + a43 * b33 + b43;
		_44 = 1;
	}

	public function mult(b:Mat4) {
		multiply(this, b);
	}

	public function multiply(a:Mat4, b:Mat4) {
		var a11 = a._11; var a12 = a._12; var a13 = a._13; var a14 = a._14;
		var a21 = a._21; var a22 = a._22; var a23 = a._23; var a24 = a._24;
		var a31 = a._31; var a32 = a._32; var a33 = a._33; var a34 = a._34;
		var a41 = a._41; var a42 = a._42; var a43 = a._43; var a44 = a._44;
		var b11 = b._11; var b12 = b._12; var b13 = b._13; var b14 = b._14;
		var b21 = b._21; var b22 = b._22; var b23 = b._23; var b24 = b._24;
		var b31 = b._31; var b32 = b._32; var b33 = b._33; var b34 = b._34;
		var b41 = b._41; var b42 = b._42; var b43 = b._43; var b44 = b._44;

		_11 = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
		_12 = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
		_13 = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
		_14 = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

		_21 = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
		_22 = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
		_23 = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
		_24 = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

		_31 = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
		_32 = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
		_33 = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
		_34 = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

		_41 = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
		_42 = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
		_43 = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
		_44 = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;
	}

	public inline function invert():Mat4 {
		inverse(this);
		return this;
	}

	/*public function inverse3x4(m:Mat4) {
		var m11 = m._11; var m12 = m._12; var m13 = m._13;
		var m21 = m._21; var m22 = m._22; var m23 = m._23;
		var m31 = m._31; var m32 = m._32; var m33 = m._33;
		var m41 = m._41; var m42 = m._42; var m43 = m._43;
		_11 = m22 * m33 - m23 * m32;
		_12 = m13 * m32 - m12 * m33;
		_13 = m12 * m23 - m13 * m22;
		_14 = 0;
		_21 = m23 * m31 - m21 * m33;
		_22 = m11 * m33 - m13 * m31;
		_23 = m13 * m21 - m11 * m23;
		_24 = 0;
		_31 = m21 * m32 - m22 * m31;
		_32 = m12 * m31 - m11 * m32;
		_33 = m11 * m22 - m12 * m21;
		_34 = 0;
		_41 = -m21 * m32 * m43 + m21 * m33 * m42 + m31 * m22 * m43 - m31 * m23 * m42 - m41 * m22 * m33 + m41 * m23 * m32;
		_42 =  m11 * m32 * m43 - m11 * m33 * m42 - m31 * m12 * m43 + m31 * m13 * m42 + m41 * m12 * m33 - m41 * m13 * m32;
		_43 = -m11 * m22 * m43 + m11 * m23 * m42 + m21 * m12 * m43 - m21 * m13 * m42 - m41 * m12 * m23 + m41 * m13 * m22;
		_44 =  m11 * m22 * m33 - m11 * m23 * m32 - m21 * m12 * m33 + m21 * m13 * m32 + m31 * m12 * m23 - m31 * m13 * m22;
		_44 = 1;
		var det = m11 * _11 + m12 * _21 + m13 * _31;
		if (Math.abs(det) < Math.EPSILON) {
			zero();
			return;
		}
		var invDet = 1.0 / det;
		_11 *= invDet; _12 *= invDet; _13 *= invDet;
		_21 *= invDet; _22 *= invDet; _23 *= invDet;
		_31 *= invDet; _32 *= invDet; _33 *= invDet;
		_41 *= invDet; _42 *= invDet; _43 *= invDet;
	}*/
	
	public function inverse(m:Mat4) {
		var m11 = m._11; var m12 = m._12; var m13 = m._13; var m14 = m._14;
		var m21 = m._21; var m22 = m._22; var m23 = m._23; var m24 = m._24;
		var m31 = m._31; var m32 = m._32; var m33 = m._33; var m34 = m._34;
		var m41 = m._41; var m42 = m._42; var m43 = m._43; var m44 = m._44;

		_11 =  m22 * m33 * m44 - m22 * m34 * m43 - m32 * m23 * m44 + m32 * m24 * m43 + m42 * m23 * m34 - m42 * m24 * m33;
		_12 = -m12 * m33 * m44 + m12 * m34 * m43 + m32 * m13 * m44 - m32 * m14 * m43 - m42 * m13 * m34 + m42 * m14 * m33;
		_13 =  m12 * m23 * m44 - m12 * m24 * m43 - m22 * m13 * m44 + m22 * m14 * m43 + m42 * m13 * m24 - m42 * m14 * m23;
		_14 = -m12 * m23 * m34 + m12 * m24 * m33 + m22 * m13 * m34 - m22 * m14 * m33 - m32 * m13 * m24 + m32 * m14 * m23;
		_21 = -m21 * m33 * m44 + m21 * m34 * m43 + m31 * m23 * m44 - m31 * m24 * m43 - m41 * m23 * m34 + m41 * m24 * m33;
		_22 =  m11 * m33 * m44 - m11 * m34 * m43 - m31 * m13 * m44 + m31 * m14 * m43 + m41 * m13 * m34 - m41 * m14 * m33;
		_23 = -m11 * m23 * m44 + m11 * m24 * m43 + m21 * m13 * m44 - m21 * m14 * m43 - m41 * m13 * m24 + m41 * m14 * m23;
		_24 =  m11 * m23 * m34 - m11 * m24 * m33 - m21 * m13 * m34 + m21 * m14 * m33 + m31 * m13 * m24 - m31 * m14 * m23;
		_31 =  m21 * m32 * m44 - m21 * m34 * m42 - m31 * m22 * m44 + m31 * m24 * m42 + m41 * m22 * m34 - m41 * m24 * m32;
		_32 = -m11 * m32 * m44 + m11 * m34 * m42 + m31 * m12 * m44 - m31 * m14 * m42 - m41 * m12 * m34 + m41 * m14 * m32;
		_33 =  m11 * m22 * m44 - m11 * m24 * m42 - m21 * m12 * m44 + m21 * m14 * m42 + m41 * m12 * m24 - m41 * m14 * m22;
		_34 = -m11 * m22 * m34 + m11 * m24 * m32 + m21 * m12 * m34 - m21 * m14 * m32 - m31 * m12 * m24 + m31 * m14 * m22;
		_41 = -m21 * m32 * m43 + m21 * m33 * m42 + m31 * m22 * m43 - m31 * m23 * m42 - m41 * m22 * m33 + m41 * m23 * m32;
		_42 =  m11 * m32 * m43 - m11 * m33 * m42 - m31 * m12 * m43 + m31 * m13 * m42 + m41 * m12 * m33 - m41 * m13 * m32;
		_43 = -m11 * m22 * m43 + m11 * m23 * m42 + m21 * m12 * m43 - m21 * m13 * m42 - m41 * m12 * m23 + m41 * m13 * m22;
		_44 =  m11 * m22 * m33 - m11 * m23 * m32 - m21 * m12 * m33 + m21 * m13 * m32 + m31 * m12 * m23 - m31 * m13 * m22;

		var det = m11 * _11 + m12 * _21 + m13 * _31 + m14 * _41;
		if(Math.abs(det) < Math.EPSILON) {
			zero();
			return;
		}

		det = 1.0 / det;
		_11 *= det;
		_12 *= det;
		_13 *= det;
		_14 *= det;
		_21 *= det;
		_22 *= det;
		_23 *= det;
		_24 *= det;
		_31 *= det;
		_32 *= det;
		_33 *= det;
		_34 *= det;
		_41 *= det;
		_42 *= det;
		_43 *= det;
		_44 *= det;
	}

	public function transpose() {
		var tmp:Float;
		tmp = _12; _12 = _21; _21 = tmp;
		tmp = _13; _13 = _31; _31 = tmp;
		tmp = _14; _14 = _41; _41 = tmp;
		tmp = _23; _23 = _32; _32 = tmp;
		tmp = _24; _24 = _42; _42 = tmp;
		tmp = _34; _34 = _43; _43 = tmp;
	}

	public function clone() {
		var m = new Mat4();
		m._11 = _11; m._12 = _12; m._13 = _13; m._14 = _14;
		m._21 = _21; m._22 = _22; m._23 = _23; m._24 = _24;
		m._31 = _31; m._32 = _32; m._33 = _33; m._34 = _34;
		m._41 = _41; m._42 = _42; m._43 = _43; m._44 = _44;
		return m;
	}
	
	public function load(a:Array<Float>) {
		_11 = a[0];  _12 = a[1];  _13 = a[2];  _14 = a[3];
		_21 = a[4];  _22 = a[5];  _23 = a[6];  _24 = a[7];
		_31 = a[8];  _32 = a[9];  _33 = a[10]; _34 = a[11];
		_41 = a[12]; _42 = a[13]; _43 = a[14]; _44 = a[15];
	}

	public function loadFrom(m:Mat4) {		
		_11 = m._11; _12 = m._12; _13 = m._13; _14 = m._14;		
		_21 = m._21; _22 = m._22; _23 = m._23; _24 = m._24;		
		_31 = m._31; _32 = m._32; _33 = m._33; _34 = m._34;		
		_41 = m._41; _42 = m._42; _43 = m._43; _44 = m._44;		
	}
	
	public function getFloats():Array<Float> {
		return [_11, _12, _13, _14,
				_21, _22, _23, _24,
				_31, _32, _33, _34,
				_41, _42, _43, _44];
	}
	
	public function toString() {
		return "MAT=[\n" +
			"  [ " + Math.fmt(_11) + ", " + Math.fmt(_12) + ", " + Math.fmt(_13) + ", " + Math.fmt(_14) + " ]\n" +
			"  [ " + Math.fmt(_21) + ", " + Math.fmt(_22) + ", " + Math.fmt(_23) + ", " + Math.fmt(_24) + " ]\n" +
			"  [ " + Math.fmt(_31) + ", " + Math.fmt(_32) + ", " + Math.fmt(_33) + ", " + Math.fmt(_34) + " ]\n" +
			"  [ " + Math.fmt(_41) + ", " + Math.fmt(_42) + ", " + Math.fmt(_43) + ", " + Math.fmt(_44) + " ]\n" +
		"]";
	}

	// Retrieves pos vector from matrix
	public inline function pos(v:Vec3 = null):Vec3 {
		if (v == null)
			return new Vec3(_41, _42 , _43 , _44);
		else {
			v.x = _41;
			v.y = _42;
			v.z = _43;
			v.w = _44;
			return v;
		}
	}

	public function scaleV():Vec3 {
		return new Vec3(
			std.Math.sqrt(_11*_11 + _21*_21 + _31*_31),
			std.Math.sqrt(_12*_12 + _22*_22 + _32*_32),
			std.Math.sqrt(_13*_13 + _23*_23 + _33*_33)
		);
	}
	
	public inline function up(?v:Vec3) {
		if (v == null)
			return new Vec3(_31, _32 , _33 , _34);
		else {
			v.x = _31;
			v.y = _32;
			v.z = _33;
			v.w = _34;
			return v;
		}
	}
	public inline function at(v:Vec3 = null):Vec3 {
		if (v == null)
			return new Vec3(_21, _22 , _23 , _24);
		else {
			v.x = _21;
			v.y = _22;
			v.z = _23;
			v.w = _24;
			return v;
		}
	}
	public inline function right(?v:Vec3) {
		if (v == null)
			return new Vec3(_11, _12 , _13 , _14);
		else {
			v.x = _11;
			v.y = _12;
			v.z = _13;
			v.w = _14;
			return v;
		}
	}

	/*public function transformVector(v:Vec3):Vec3 {
		var x:Float = v.x;
		var y:Float = v.y;
		var z:Float = v.z;
		
		return new Vec3(
			(x * _11 + y * _21 + z * _31 + _41),
			(x * _12 + y * _22 + z * _32 + _42),
			(x * _13 + y * _23 + z * _33 + _43),
			1
		);
		
	}*/


	public function getInverse(m:Mat4) { //-
		// based on http://www.euclideanspace.com/maths/algebra/matrix/functions/inverse/fourD/index.htm

		var n11 = m._11, n12 = m._21, n13 = m._31, n14 = m._41;
		var n21 = m._12, n22 = m._22, n23 = m._32, n24 = m._42;
		var n31 = m._13, n32 = m._23, n33 = m._33, n34 = m._43;
		var n41 = m._14, n42 = m._24, n43 = m._34, n44 = m._44;

		_11 = n23*n34*n42 - n24*n33*n42 + n24*n32*n43 - n22*n34*n43 - n23*n32*n44 + n22*n33*n44;
		_21 = n14*n33*n42 - n13*n34*n42 - n14*n32*n43 + n12*n34*n43 + n13*n32*n44 - n12*n33*n44;
		_31 = n13*n24*n42 - n14*n23*n42 + n14*n22*n43 - n12*n24*n43 - n13*n22*n44 + n12*n23*n44;
		_41 = n14*n23*n32 - n13*n24*n32 - n14*n22*n33 + n12*n24*n33 + n13*n22*n34 - n12*n23*n34;
		_12 = n24*n33*n41 - n23*n34*n41 - n24*n31*n43 + n21*n34*n43 + n23*n31*n44 - n21*n33*n44;
		_22 = n13*n34*n41 - n14*n33*n41 + n14*n31*n43 - n11*n34*n43 - n13*n31*n44 + n11*n33*n44;
		_32 = n14*n23*n41 - n13*n24*n41 - n14*n21*n43 + n11*n24*n43 + n13*n21*n44 - n11*n23*n44;
		_42 = n13*n24*n31 - n14*n23*n31 + n14*n21*n33 - n11*n24*n33 - n13*n21*n34 + n11*n23*n34;
		_13 = n22*n34*n41 - n24*n32*n41 + n24*n31*n42 - n21*n34*n42 - n22*n31*n44 + n21*n32*n44;
		_23 = n14*n32*n41 - n12*n34*n41 - n14*n31*n42 + n11*n34*n42 + n12*n31*n44 - n11*n32*n44;
		_33 = n12*n24*n41 - n14*n22*n41 + n14*n21*n42 - n11*n24*n42 - n12*n21*n44 + n11*n22*n44;
		_43 = n14*n22*n31 - n12*n24*n31 - n14*n21*n32 + n11*n24*n32 + n12*n21*n34 - n11*n22*n34;
		_14 = n23*n32*n41 - n22*n33*n41 - n23*n31*n42 + n21*n33*n42 + n22*n31*n43 - n21*n32*n43;
		_24 = n12*n33*n41 - n13*n32*n41 + n13*n31*n42 - n11*n33*n42 - n12*n31*n43 + n11*n32*n43;
		_34 = n13*n22*n41 - n12*n23*n41 - n13*n21*n42 + n11*n23*n42 + n12*n21*n43 - n11*n22*n43;
		_44 = n12*n23*n31 - n13*n22*n31 + n13*n21*n32 - n11*n23*n32 - n12*n21*n33 + n11*n22*n33;

		var det = n11 * _11 + n21 * _21 + n31 * _31 + n41 * _41;

		if (det == 0) {
			this.identity();
			return this;
		}

		this.multiplyScalar(1 / det);

		return this;
	}

	public function multiplyScalar(s:Float):Mat4 {
		_11 *= s; _21 *= s; _31 *= s; _41 *= s;
		_12 *= s; _22 *= s; _32 *= s; _42 *= s;
		_13 *= s; _23 *= s; _33 *= s; _43 *= s;
		_14 *= s; _24 *= s; _34 *= s; _44 *= s;

		return this;
	}



	public function multiplyMatrices(a:Mat4, b:Mat4):Mat4 { //-
		var a11 = a._11, a12 = a._21, a13 = a._31, a14 = a._41;
		var a21 = a._12, a22 = a._22, a23 = a._32, a24 = a._42;
		var a31 = a._13, a32 = a._23, a33 = a._33, a34 = a._43;
		var a41 = a._14, a42 = a._24, a43 = a._34, a44 = a._44;

		var b11 = b._11, b12 = b._21, b13 = b._31, b14 = b._41;
		var b21 = b._12, b22 = b._22, b23 = b._32, b24 = b._42;
		var b31 = b._13, b32 = b._23, b33 = b._33, b34 = b._43;
		var b41 = b._14, b42 = b._24, b43 = b._34, b44 = b._44;

		_11 = a11 * b11 + a12 * b21 + a13 * b31 + a14 * b41;
		_21 = a11 * b12 + a12 * b22 + a13 * b32 + a14 * b42;
		_31 = a11 * b13 + a12 * b23 + a13 * b33 + a14 * b43;
		_41 = a11 * b14 + a12 * b24 + a13 * b34 + a14 * b44;

		_12 = a21 * b11 + a22 * b21 + a23 * b31 + a24 * b41;
		_22 = a21 * b12 + a22 * b22 + a23 * b32 + a24 * b42;
		_32 = a21 * b13 + a22 * b23 + a23 * b33 + a24 * b43;
		_42 = a21 * b14 + a22 * b24 + a23 * b34 + a24 * b44;

		_13 = a31 * b11 + a32 * b21 + a33 * b31 + a34 * b41;
		_23 = a31 * b12 + a32 * b22 + a33 * b32 + a34 * b42;
		_33 = a31 * b13 + a32 * b23 + a33 * b33 + a34 * b43;
		_43 = a31 * b14 + a32 * b24 + a33 * b34 + a34 * b44;

		_14 = a41 * b11 + a42 * b21 + a43 * b31 + a44 * b41;
		_24 = a41 * b12 + a42 * b22 + a43 * b32 + a44 * b42;
		_34 = a41 * b13 + a42 * b23 + a43 * b33 + a44 * b43;
		_44 = a41 * b14 + a42 * b24 + a43 * b34 + a44 * b44;

		return this;
	}

	public function toRotation():Mat4 {
		var v1 = new Vec3();
		var scaleX = 1 / v1.set(_11, _12, _13).length();
		var scaleY = 1 / v1.set(_21, _22, _23).length();
		var scaleZ = 1 / v1.set(_31, _32, _33).length();

		_11 = _11 * scaleX;
		_12 = _12 * scaleX;
		_13 = _13 * scaleX;
		_14 = 0;

		_21 = _21 * scaleY;
		_22 = _22 * scaleY;
		_23 = _23 * scaleY;
		_24 = 0;

		_31 = _31 * scaleZ;
		_32 = _32 * scaleZ;
		_33 = _33 * scaleZ;
		_34 = 0;

		_41 = 0;
		_42 = 0;
		_43 = 0;
		_44 = 0;

		return this;
	}

	public function getQuat():Quat {
		// assumes the upper 3x3 of m is a pure rotation matrix (i.e, unscaled)

		var m = clone();
		m.toRotation();
				
		var q:Quat = new Quat();

		var m11 = _11;
		var m12 = _21;
		var m13 = _31;
		var m21 = _12;
		var m22 = _22;
		var m23 = _32;
		var m31 = _13;
		var m32 = _23;
		var m33 = _33;

		var ftrace = m11 + m22 + m33;
		var s:Float = 0;

		if ( ftrace > 0 ) {

			s = 0.5 / std.Math.sqrt( ftrace + 1.0 );

			q.w = 0.25 / s;
			q.x = ( m32 - m23 ) * s;
			q.y = ( m13 - m31 ) * s;
			q.z = ( m21 - m12 ) * s;

		} else if ( m11 > m22 && m11 > m33 ) {

			s = 2.0 * std.Math.sqrt( 1.0 + m11 - m22 - m33 );

			q.w = ( m32 - m23 ) / s;
			q.x = 0.25 * s;
			q.y = ( m12 + m21 ) / s;
			q.z = ( m13 + m31 ) / s;

		} else if ( m22 > m33 ) {

			s = 2.0 * std.Math.sqrt( 1.0 + m22 - m11 - m33 );

			q.w = ( m13 - m31 ) / s;
			q.x = ( m12 + m21 ) / s;
			q.y = 0.25 * s;
			q.z = ( m23 + m32 ) / s;

		} else {

			s = 2.0 * std.Math.sqrt( 1.0 + m33 - m11 - m22 );

			q.w = ( m21 - m12 ) / s;
			q.x = ( m13 + m31 ) / s;
			q.y = ( m23 + m32 ) / s;
			q.z = 0.25 * s;

		}
		
		return q;
	}


	public function toBuffer():Array<Float> {
		m[0] = _11;
		m[1] = _12;
		m[2] = _13;
		m[3] = _14;
		m[4] = _21;
		m[5] = _22;
		m[6] = _23;
		m[7] = _24;
		m[8] = _31;
		m[9] = _32;
		m[10] = _33;
		m[11] = _34;
		m[12] = _41;
		m[13] = _42;
		m[14] = _43;
		m[15] = _44;		
		return m; 
	}

	public function getMaxScaleOnAxis():Float { //-
		var te = this.getFloats();

		var scaleXSq = te[0] * te[0] + te[1] * te[1] + te[2] * te[2];
		var scaleYSq = te[4] * te[4] + te[5] * te[5] + te[6] * te[6];
		var scaleZSq = te[8] * te[8] + te[9] * te[9] + te[10] * te[10];

		return std.Math.sqrt(Math.max(scaleXSq, Math.max(scaleYSq, scaleZSq)));	
	}

	public function getScale():Vec3 {
		var sx:Float = std.Math.sqrt(_11 * _11 + _12 * _12 + _13 * _13);
		var sy:Float = std.Math.sqrt(_21 * _21 + _22 * _22 + _23 * _23);
		var sz:Float = std.Math.sqrt(_31 * _31 + _32 * _32 + _33 * _33);
		return new Vec3(sx, sy, sz);
	}

	public static function perspective(fovY:Float, aspectRatio:Float, zNear:Float, zFar:Float):Mat4 {
        
        var f = 1.0 / std.Math.tan(fovY / 2);
        var t = 1.0 / (zNear - zFar);

        return new Mat4([f / aspectRatio, 0.0,      0.0,                   0.0,
                         0.0,             f,        0.0,                   0.0,
                         0.0,             0.0,      (zFar + zNear) * t,   -1.0,
                         0.0,             0.0,      2 * zFar * zNear * t , 0.0]);
    }

    public static function orthogonal(left:Float, right:Float, bottom:Float, top:Float, near:Float, far:Float, orthoScale:Float = 7.314):Mat4 {

		var w = right - left;
		var h = top - bottom;
		var p = far - near;

		var x = (right + left) / w;
		var y = (top + bottom) / h;
		var z = (far + near) / p;

		return new Mat4([
			orthoScale / w,	0,				0,				-x,
			0,				orthoScale / h,	0,				-y,
			0,				0,				-orthoScale / p,-z,
			0,				0,				0,				1
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

        return new Mat4([s0, u0,-f0, 0.0,
                         s1, u1,-f1, 0.0,
                         s2, u2,-f2, 0.0,
                         d0, d1, d2, 1.0]);
    }
}
