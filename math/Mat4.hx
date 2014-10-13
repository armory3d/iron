package fox.math;

// Adapted from H3D Engine
// https://github.com/ncannasse/h3d
// TODO: merge with built in Kha matrix

import fox.math.Math;

class Mat4 {
	
	static var tmp = new Mat4();

	public var _11 : Float; // 0
	public var _12 : Float; // 1
	public var _13 : Float; // 2
	public var _14 : Float; // 3
	public var _21 : Float; // 4
	public var _22 : Float; // 5
	public var _23 : Float; // 6
	public var _24 : Float; // 7
	public var _31 : Float; // 8
	public var _32 : Float; // 9
	public var _33 : Float; // 10
	public var _34 : Float; // 11
	public var _41 : Float; // 12
	public var _42 : Float; // 13
	public var _43 : Float; // 14
	public var _44 : Float; // 15

	public function new(a : Array<Float> = null) {
		if (a != null) load(a);
		else identity();

		m = new Array<Float>();
		for (i in 0...16) m.push(0);
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

	public function initRotateX( a : Float ) {
		var cos = Math.cos(a);
		var sin = Math.sin(a);
		_11 = 1.0; _12 = 0.0; _13 = 0.0; _14 = 0.0;
		_21 = 0.0; _22 = cos; _23 = sin; _24 = 0.0;
		_31 = 0.0; _32 = -sin; _33 = cos; _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 1.0;
	}

	public function initRotateY( a : Float ) {
		var cos = Math.cos(a);
		var sin = Math.sin(a);
		_11 = cos; _12 = 0.0; _13 = -sin; _14 = 0.0;
		_21 = 0.0; _22 = 1.0; _23 = 0.0; _24 = 0.0;
		_31 = sin; _32 = 0.0; _33 = cos; _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 1.0;
	}

	public function initRotateZ( a : Float ) {
		var cos = Math.cos(a);
		var sin = Math.sin(a);
		_11 = cos; _12 = sin; _13 = 0.0; _14 = 0.0;
		_21 = -sin; _22 = cos; _23 = 0.0; _24 = 0.0;
		_31 = 0.0; _32 = 0.0; _33 = 1.0; _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 1.0;
	}

	public function initTranslate( x = 0., y = 0., z = 0. ) {
		_11 = 1.0; _12 = 0.0; _13 = 0.0; _14 = 0.0;
		_21 = 0.0; _22 = 1.0; _23 = 0.0; _24 = 0.0;
		_31 = 0.0; _32 = 0.0; _33 = 1.0; _34 = 0.0;
		_41 = x; _42 = y; _43 = z; _44 = 1.0;
	}

	public function initScale( x = 1., y = 1., z = 1. ) {
		_11 = x; _12 = 0.0; _13 = 0.0; _14 = 0.0;
		_21 = 0.0; _22 = y; _23 = 0.0; _24 = 0.0;
		_31 = 0.0; _32 = 0.0; _33 = z; _34 = 0.0;
		_41 = 0.0; _42 = 0.0; _43 = 0.0; _44 = 1.0;
	}

	public function initRotateAxis( axis : Vec3, angle : Float ) {
		var cos = Math.cos(angle), sin = Math.sin(angle);
		var cos1 = 1 - cos;
		var x = -axis.x, y = -axis.y, z = -axis.z;
		var xx = x * x, yy = y * y, zz = z * z;
		var len = Math.invSqrt(xx + yy + zz);
		x *= len;
		y *= len;
		z *= len;
		var xcos1 = x * cos1, zcos1 = z * cos1;
		_11 = cos + x * xcos1;
		_12 = y * xcos1 - z * sin;
		_13 = x * zcos1 + y * sin;
		_14 = 0.;
		_21 = y * xcos1 + z * sin;
		_22 = cos + y * y * cos1;
		_23 = y * zcos1 - x * sin;
		_24 = 0.;
		_31 = x * zcos1 - y * sin;
		_32 = y * zcos1 + x * sin;
		_33 = cos + z * zcos1;
		_34 = 0.;
		_41 = 0.; _42 = 0.; _43 = 0.; _44 = 1.;
	}
	
	public function initRotate( x : Float, y : Float, z : Float ) {
		var cx = Math.cos(x);
		var sx = Math.sin(x);
		var cy = Math.cos(y);
		var sy = Math.sin(y);
		var cz = Math.cos(z);
		var sz = Math.sin(z);
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
	
	public function translate( x = 0., y = 0., z = 0. ) {
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
	
	public function scale( x = 1., y = 1., z = 1. ) {
		_11 *= x;
		_21 *= x;
		_31 *= x;
		_41 *= x;
		_12 *= y;
		_22 *= y;
		_32 *= y;
		_42 *= y;
		_13 *= z;
		_23 *= z;
		_33 *= z;
		_43 *= z;
	}

	public function rotate( x, y, z ) {
		var tmp = tmp;
		tmp.initRotate(x,y,z);
		multiply(this, tmp);
	}
	
	public function rotateAxis( axis, angle ) {
		var tmp = tmp;
		tmp.initRotateAxis(axis, angle);
		multiply(this, tmp);
	}
	
	public inline function add( m : Mat4 ) {
		multiply(this, m);
	}
	
	public function prependTranslate( x = 0., y = 0., z = 0. ) {
		var vx = _11 * x + _21 * y + _31 * z + _41;
		var vy = _12 * x + _22 * y + _32 * z + _42;
		var vz = _13 * x + _23 * y + _33 * z + _43;
		var vw = _14 * x + _24 * y + _34 * z + _44;
		_41 = vx;
		_42 = vy;
		_43 = vz;
		_44 = vw;
	}

	public function prependRotate( x, y, z ) {
		var tmp = tmp;
		tmp.initRotate(x,y,z);
		multiply(tmp, this);
	}
	
	public function prependRotateAxis( axis, angle ) {
		var tmp = tmp;
		tmp.initRotateAxis(axis, angle);
		multiply(tmp, this);
	}

	public function prependScale( sx = 1., sy = 1., sz = 1. ) {
		var tmp = tmp;
		tmp.initScale(sx,sy,sz);
		multiply(tmp, this);
	}
	
	public function multiply3x4( a : Mat4, b : Mat4 ) {
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

	public function multiply( a : Mat4, b : Mat4 ) {
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

	public inline function invert() {
		inverse(this);
	}

	public function inverse3x4( m : Mat4 ) {
		var m11 = m._11, m12 = m._12, m13 = m._13;
		var m21 = m._21, m22 = m._22, m23 = m._23;
		var m31 = m._31, m32 = m._32, m33 = m._33;
		var m41 = m._41, m42 = m._42, m43 = m._43;
		_11 = m22*m33 - m23*m32;
		_12 = m13*m32 - m12*m33;
		_13 = m12*m23 - m13*m22;
		_14 = 0;
		_21 = m23*m31 - m21*m33;
		_22 = m11*m33 - m13*m31;
		_23 = m13*m21 - m11*m23;
		_24 = 0;
		_31 = m21*m32 - m22*m31;
		_32 = m12*m31 - m11*m32;
		_33 = m11*m22 - m12*m21;
		_34 = 0;
		_41 = -m21 * m32 * m43 + m21 * m33 * m42 + m31 * m22 * m43 - m31 * m23 * m42 - m41 * m22 * m33 + m41 * m23 * m32;
		_42 = m11 * m32 * m43 - m11 * m33 * m42 - m31 * m12 * m43 + m31 * m13 * m42 + m41 * m12 * m33 - m41 * m13 * m32;
		_43 = -m11 * m22 * m43 + m11 * m23 * m42 + m21 * m12 * m43 - m21 * m13 * m42 - m41 * m12 * m23 + m41 * m13 * m22;
		_44 = m11 * m22 * m33 - m11 * m23 * m32 - m21 * m12 * m33 + m21 * m13 * m32 + m31 * m12 * m23 - m31 * m13 * m22;
		_44 = 1;
		var det = m11 * _11 + m12 * _21 + m13 * _31;
		if(	Math.abs(det) < Math.EPSILON ) {
			zero();
			return;
		}
		var invDet = 1.0 / det;
		_11 *= invDet; _12 *= invDet; _13 *= invDet;
		_21 *= invDet; _22 *= invDet; _23 *= invDet;
		_31 *= invDet; _32 *= invDet; _33 *= invDet;
		_41 *= invDet; _42 *= invDet; _43 *= invDet;
	}
	
	public function inverse( m : Mat4 ) {
		var m11 = m._11; var m12 = m._12; var m13 = m._13; var m14 = m._14;
		var m21 = m._21; var m22 = m._22; var m23 = m._23; var m24 = m._24;
		var m31 = m._31; var m32 = m._32; var m33 = m._33; var m34 = m._34;
		var m41 = m._41; var m42 = m._42; var m43 = m._43; var m44 = m._44;

		_11 = m22 * m33 * m44 - m22 * m34 * m43 - m32 * m23 * m44 + m32 * m24 * m43 + m42 * m23 * m34 - m42 * m24 * m33;
		_12 = -m12 * m33 * m44 + m12 * m34 * m43 + m32 * m13 * m44 - m32 * m14 * m43 - m42 * m13 * m34 + m42 * m14 * m33;
		_13 = m12 * m23 * m44 - m12 * m24 * m43 - m22 * m13 * m44 + m22 * m14 * m43 + m42 * m13 * m24 - m42 * m14 * m23;
		_14 = -m12 * m23 * m34 + m12 * m24 * m33 + m22 * m13 * m34 - m22 * m14 * m33 - m32 * m13 * m24 + m32 * m14 * m23;
		_21 = -m21 * m33 * m44 + m21 * m34 * m43 + m31 * m23 * m44 - m31 * m24 * m43 - m41 * m23 * m34 + m41 * m24 * m33;
		_22 = m11 * m33 * m44 - m11 * m34 * m43 - m31 * m13 * m44 + m31 * m14 * m43 + m41 * m13 * m34 - m41 * m14 * m33;
		_23 = -m11 * m23 * m44 + m11 * m24 * m43 + m21 * m13 * m44 - m21 * m14 * m43 - m41 * m13 * m24 + m41 * m14 * m23;
		_24 =  m11 * m23 * m34 - m11 * m24 * m33 - m21 * m13 * m34 + m21 * m14 * m33 + m31 * m13 * m24 - m31 * m14 * m23;
		_31 = m21 * m32 * m44 - m21 * m34 * m42 - m31 * m22 * m44 + m31 * m24 * m42 + m41 * m22 * m34 - m41 * m24 * m32;
		_32 = -m11 * m32 * m44 + m11 * m34 * m42 + m31 * m12 * m44 - m31 * m14 * m42 - m41 * m12 * m34 + m41 * m14 * m32;
		_33 = m11 * m22 * m44 - m11 * m24 * m42 - m21 * m12 * m44 + m21 * m14 * m42 + m41 * m12 * m24 - m41 * m14 * m22;
		_34 =  -m11 * m22 * m34 + m11 * m24 * m32 + m21 * m12 * m34 - m21 * m14 * m32 - m31 * m12 * m24 + m31 * m14 * m22;
		_41 = -m21 * m32 * m43 + m21 * m33 * m42 + m31 * m22 * m43 - m31 * m23 * m42 - m41 * m22 * m33 + m41 * m23 * m32;
		_42 = m11 * m32 * m43 - m11 * m33 * m42 - m31 * m12 * m43 + m31 * m13 * m42 + m41 * m12 * m33 - m41 * m13 * m32;
		_43 = -m11 * m22 * m43 + m11 * m23 * m42 + m21 * m12 * m43 - m21 * m13 * m42 - m41 * m12 * m23 + m41 * m13 * m22;
		_44 = m11 * m22 * m33 - m11 * m23 * m32 - m21 * m12 * m33 + m21 * m13 * m32 + m31 * m12 * m23 - m31 * m13 * m22;

		var det = m11 * _11 + m12 * _21 + m13 * _31 + m14 * _41;
		if(	Math.abs(det) < Math.EPSILON ) {
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
		var tmp;
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

	public function loadFrom( m : Mat4 ) {
		_11 = m._11; _12 = m._12; _13 = m._13; _14 = m._14;
		_21 = m._21; _22 = m._22; _23 = m._23; _24 = m._24;
		_31 = m._31; _32 = m._32; _33 = m._33; _34 = m._34;
		_41 = m._41; _42 = m._42; _43 = m._43; _44 = m._44;
	}
	
	public function load( a : Array<Float> ) {
		_11 = a[0]; _12 = a[1]; _13 = a[2]; _14 = a[3];
		_21 = a[4]; _22 = a[5]; _23 = a[6]; _24 = a[7];
		_31 = a[8]; _32 = a[9]; _33 = a[10]; _34 = a[11];
		_41 = a[12]; _42 = a[13]; _43 = a[14]; _44 = a[15];
	}
	
	public function getFloats() {
		return [_11, _12, _13, _14, _21, _22, _23, _24, _31, _32, _33, _34, _41, _42, _43, _44];
	}
	
	public function toString() {
		return "MAT=[\n" +
			"  [ " + Math.fmt(_11) + ", " + Math.fmt(_12) + ", " + Math.fmt(_13) + ", " + Math.fmt(_14) + " ]\n" +
			"  [ " + Math.fmt(_21) + ", " + Math.fmt(_22) + ", " + Math.fmt(_23) + ", " + Math.fmt(_24) + " ]\n" +
			"  [ " + Math.fmt(_31) + ", " + Math.fmt(_32) + ", " + Math.fmt(_33) + ", " + Math.fmt(_34) + " ]\n" +
			"  [ " + Math.fmt(_41) + ", " + Math.fmt(_42) + ", " + Math.fmt(_43) + ", " + Math.fmt(_44) + " ]\n" +
		"]";
	}
	
	// ---- COLOR MATRIX FUNCTIONS -------

	static inline var lumR = 0.212671;
	static inline var lumG = 0.71516;
	static inline var lumB = 0.072169;
	
	public function colorHue( hue : Float ) {
		if( hue == 0. )
			return;
		var cv = Math.cos(hue);
		var sv = Math.sin(hue);
		tmp._11 = lumR + cv * (1 - lumR) - sv * lumR;
		tmp._12 = lumR - cv * lumR + sv * 0.143;
		tmp._13 = lumR - cv * lumR - sv * (1 - lumR);
		tmp._21 = lumG - cv * lumG - sv * lumG;
		tmp._22 = lumG + cv * (1 - lumG) + sv * 0.140;
		tmp._23 = lumG - cv * lumG + sv * lumG;
		tmp._31 = lumB - cv * lumB - sv * lumB;
		tmp._32 = lumB - cv * lumB - sv * 0.283;
		tmp._33 = lumB + cv * (1 - lumB) + sv * lumB;
		tmp._34 = 0;
		tmp._41 = 0;
		tmp._42 = 0;
		tmp._43 = 0;
		multiply3x4(this, tmp);
	}
	
	public function colorSaturation( sat : Float ) {
		var is = 1 - sat;
		var r = is * lumR;
		var g = is * lumG;
		var b = is * lumB;
		tmp._11 = r + sat;
		tmp._12 = r;
		tmp._13 = r;
		tmp._21 = g;
		tmp._22 = g + sat;
		tmp._23 = g;
		tmp._31 = b;
		tmp._32 = b;
		tmp._33 = b + sat;
		tmp._41 = 0;
		tmp._42 = 0;
		tmp._43 = 0;
		multiply3x4(this, tmp);
	}
	
	public function colorContrast( contrast : Float ) {
		var v = contrast + 1;
		tmp._11 = v;
		tmp._12 = 0;
		tmp._13 = 0;
		tmp._21 = 0;
		tmp._22 = v;
		tmp._23 = 0;
		tmp._31 = 0;
		tmp._32 = 0;
		tmp._33 = v;
		tmp._41 = -contrast*0.5;
		tmp._42 = -contrast*0.5;
		tmp._43 = -contrast*0.5;
		multiply3x4(this, tmp);
	}

	public function colorBrightness( brightness : Float ) {
		_41 += brightness;
		_42 += brightness;
		_43 += brightness;
	}
	
	public static function I() {
		var m = new Mat4();
		m.identity();
		return m;
	}

	public static function L( a : Array<Float> ) {
		var m = new Mat4();
		m.load(a);
		return m;
	}
	
	public static function T( x = 0., y = 0., z = 0. ) {
		var m = new Mat4();
		m.initTranslate(x, y, z);
		return m;
	}

	public static function R(x,y,z) {
		var m = new Mat4();
		m.initRotate(x,y,z);
		return m;
	}

	public static function S( x = 1., y = 1., z = 1.0 ) {
		var m = new Mat4();
		m.initScale(x, y, z);
		return m;
	}

	//retrieves pos vector from matrix
	public inline function pos( ? v: Vec3)
	{
		if( v == null )
			return new Vec3( _41, _42 , _43 , _44  );
		else
		{
			v.x = _41;
			v.y = _42;
			v.z = _43;
			v.w = _44;
			return v;
		}
	}
	
	//retrieves at vector from matrix
	public inline function at( ?v:Vec3)
	{
		if( v == null )
			return new Vec3( _31, _32 , _33 , _34  );
		else
		{
			v.x = _31;
			v.y = _32;
			v.z = _33;
			v.w = _34;
			return v;
		}
	}
	
	//retrieves up vector from matrix
	public inline function up(?v:Vec3)
	{
		if( v == null )
			return new Vec3( _21, _22 , _23 , _24  );
		else
		{
			v.x = _21;
			v.y = _22;
			v.z = _23;
			v.w = _24;
			return v;
		}
	}
	
	//retrieves right vector from matrix
	public inline function right(?v:Vec3)
	{
		if( v == null )
			return new Vec3( _11, _12 , _13 , _14  );
		else
		{
			v.x = _11;
			v.y = _12;
			v.z = _13;
			v.w = _14;
			return v;
		}
	}


	// Extended
	public function appendRotation (degrees:Float, axis:Vec3, pivotPoint:Vec3 = null) {
		
		var m = getAxisRotation (axis.x, axis.y, axis.z, degrees);
		
		if (pivotPoint != null) {
			
			var p = pivotPoint;
			m.appendTranslation (p.x, p.y, p.z);
			
		}
		
		this.append (m);
	}

	public function appendScale (xScale:Float, yScale:Float, zScale:Float) {
		
		this.append (new Mat4 ( [ xScale, 0.0, 0.0, 0.0, 0.0, yScale, 0.0, 0.0, 0.0, 0.0, zScale, 0.0, 0.0, 0.0, 0.0, 1.0 ] ));
		
	}


	static public function getAxisRotation (x:Float, y:Float, z:Float, degrees:Float):Mat4 {
		
		var m = new Mat4 ();
		
		var a1 = new Vec3 (x, y, z);
		var rad = -degrees * (Math.PI / 180);
		var c:Float = Math.cos (rad);
		var s:Float = Math.sin (rad);
		var t:Float = 1.0 - c;
		
		m._11 = c + a1.x * a1.x * t;
		m._22 = c + a1.y * a1.y * t;
		m._33 = c + a1.z * a1.z * t;
		
		var tmp1 = a1.x * a1.y * t;
		var tmp2 = a1.z * s;
		m._21 = tmp1 + tmp2;
		m._12 = tmp1 - tmp2;
		tmp1 = a1.x * a1.z * t;
		tmp2 = a1.y * s;
		m._31 = tmp1 - tmp2;
		m._13 = tmp1 + tmp2;
		tmp1 = a1.y * a1.z * t;
		tmp2 = a1.x*s;
		m._32 = tmp1 + tmp2;
		m._23 = tmp1 - tmp2;
		
		return m;
	}


	public function appendTranslation (x:Float, y:Float, z:Float) {
		
		_41 += x;
		_42 += y;
		_43 += z;
	}


	public function append (lhs:Mat4) {
		
		var m111:Float = this._11, m121:Float = this._21, m131:Float = this._31, m141:Float = this._41,
			m112:Float = this._12, m122:Float = this._22, m132:Float = this._32, m142:Float = this._42,
			m113:Float = this._13, m123:Float = this._23, m133:Float = this._33, m143:Float = this._43,
			m114:Float = this._14, m124:Float = this._24, m134:Float = this._34, m144:Float = this._44,
			m211:Float = lhs._11, m221:Float = lhs._21, m231:Float = lhs._31, m241:Float = lhs._41,
			m212:Float = lhs._12, m222:Float = lhs._22, m232:Float = lhs._32, m242:Float = lhs._42,
			m213:Float = lhs._13, m223:Float = lhs._23, m233:Float = lhs._33, m243:Float = lhs._43,
			m214:Float = lhs._14, m224:Float = lhs._24, m234:Float = lhs._34, m244:Float = lhs._44;
		
		_11 = m111 * m211 + m112 * m221 + m113 * m231 + m114 * m241;
		_12 = m111 * m212 + m112 * m222 + m113 * m232 + m114 * m242;
		_13 = m111 * m213 + m112 * m223 + m113 * m233 + m114 * m243;
		_14 = m111 * m214 + m112 * m224 + m113 * m234 + m114 * m244;
		
		_21 = m121 * m211 + m122 * m221 + m123 * m231 + m124 * m241;
		_22 = m121 * m212 + m122 * m222 + m123 * m232 + m124 * m242;
		_23 = m121 * m213 + m122 * m223 + m123 * m233 + m124 * m243;
		_24 = m121 * m214 + m122 * m224 + m123 * m234 + m124 * m244;
		
		_31 = m131 * m211 + m132 * m221 + m133 * m231 + m134 * m241;
		_32 = m131 * m212 + m132 * m222 + m133 * m232 + m134 * m242;
		_33 = m131 * m213 + m132 * m223 + m133 * m233 + m134 * m243;
		_34 = m131 * m214 + m132 * m224 + m133 * m234 + m134 * m244;
		
		_41 = m141 * m211 + m142 * m221 + m143 * m231 + m144 * m241;
		_42 = m141 * m212 + m142 * m222 + m143 * m232 + m144 * m242;
		_43 = m141 * m213 + m142 * m223 + m143 * m233 + m144 * m243;
		_44 = m141 * m214 + m142 * m224 + m143 * m234 + m144 * m244;
		
	}


	public function transformVector (v:Vec3):Vec3 {
		
		var x:Float = v.x, y:Float = v.y, z:Float = v.z;
		
		return new Vec3 (
			(x * _11 + y * _21 + z * _31 + _41),
			(x * _12 + y * _22 + z * _32 + _42),
			(x * _13 + y * _23 + z * _33 + _43),
		1);
		
	}


	public function multiplyByVector(vec:Vec3):Vec3 {
		var result:Vec3 = new Vec3(0, 0, 0, 0);

		result.x = _11 * vec.x + _12 * vec.y + _13 * vec.z + _14 * vec.w;
		result.y = _21 * vec.x + _22 * vec.y + _23 * vec.z + _24 * vec.w;
		result.z = _31 * vec.x + _32 * vec.y + _33 * vec.z + _34 * vec.w;
		result.w = _41 * vec.x + _42 * vec.y + _43 * vec.z + _44 * vec.w;
	
		return result;
	}


	public function getInverse(m:Mat4) {

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

		if ( det == 0 ) {

			this.identity();

			return this;
		}

		this.multiplyScalar( 1 / det );

		return this;
	}

	public function multiplyScalar(s:Float):Mat4 {

		_11 *= s; _21 *= s; _31 *= s; _41 *= s;
		_12 *= s; _22 *= s; _32 *= s; _42 *= s;
		_13 *= s; _23 *= s; _33 *= s; _43 *= s;
		_14 *= s; _24 *= s; _34 *= s; _44 *= s;

		return this;
	}



	public function multiplyMatrices(a:Mat4, b:Mat4):Mat4 {

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
		var tmp = new Vec3();
		tmp.set(_11, _12, _13).normalize(); _11 = tmp.x; _12 = tmp.y; _13 = tmp.z; _14 = 0.0;
		tmp.set(_21, _22, _23).normalize(); _21 = tmp.x; _22 = tmp.y; _23 = tmp.z; _24 = 0.0;
		tmp.set(_31, _32, _33).normalize(); _31 = tmp.x; _32 = tmp.y; _33 = tmp.z; _34 = 0.0;
		_41 = _42 = _43 = 0.0; _44 = 1.0;
		return this;
	}



	public function getQuat():Quat
	{
		var b : Array<Float> = toBuffer();
		var m:Mat4 = toRotation();
				
		var q : Quat = new Quat();				
		var diag : Float = m._11 + m._22 + m._33 + 1.0;
		var e : Float = 0;// Mathf.Epsilon;
		
		if(diag > e)
		{
			q.w = Math.sqrt(diag) / 2.0;			
			var w4 : Float = (4.0 * q.w);
			q.x = (m._32 - m._23) / w4;
			q.y = (m._13 - m._31) / w4;
			q.z = (m._21 - m._12) / w4;						
		}
		else
		{
			var d01 : Float = m._11 - m._22;
			var d02 : Float = m._11 - m._33;
			var d12 : Float = m._22 - m._33;
			
			if ((d01>e) && (d02>e))
			{
				// 1st element of diag is greatest value
				// find scale according to 1st element, and double it
				var scale : Float = Math.sqrt(1.0 + m._11 - m._22 - m._33) * 2.0;

				// TODO: speed this up
				q.x = 0.25 * scale;
				q.y = (m._21 + m._12) / scale;
				q.z = (m._13 + m._31) / scale;
				q.w = (m._23 - m._32) / scale;
			}
			else if (d12>e)
			{
				// 2nd element of diag is greatest value
				// find scale according to 2nd element, and double it
				var scale : Float = Math.sqrt(1.0 + m._22 - m._11 - m._33) * 2.0;
				
				// TODO: speed this up
				q.x = (m._21 + m._12) / scale;
				q.y = 0.25 * scale;
				q.z = (m._32 + m._23) / scale;
				q.w = (m._31 - m._13) / scale;
			}
			else
			{
				// 3rd element of diag is greatest value
				// find scale according to 3rd element, and double it
				var scale : Float = Math.sqrt(1.0 + m._33 - m._11 - m._22) * 2.0;
				
				// TODO: speed this up
				q.x = (m._31 + m._13) / scale;
				q.y = (m._32 + m._23) / scale;
				q.z = 0.25 * scale;
				q.w = (m._12 - m._21) / scale;
			}
		}

		_11 = b[0];
		_12 = b[1];
		_13 = b[2];
		_14 = b[3];

		_21 = b[4];
		_22 = b[5];
		_23 = b[6];
		_24 = b[7];

		_31 = b[8];
		_32 = b[9];
		_33 = b[10];
		_34 = b[11];

		_41 = b[12];
		_42 = b[13];
		_43 = b[14];
		_44 = b[15];
		
		q.normalize();
		
		return q;
	}


	private var m : Array<Float>;

	public function toBuffer() : Array<Float>
	{ 
		m[ 0] = _11;
		m[ 1] = _12;
		m[ 2] = _13;
		m[ 3] = _14;
		m[ 4] = _21;
		m[ 5] = _22;
		m[ 6] = _23;
		m[ 7] = _24;
		m[ 8] = _31;
		m[ 9] = _32;
		m[10] = _33;
		m[11] = _34;
		m[12] = _41;
		m[13] = _42;
		m[14] = _43;
		m[15] = _44;		
		return m; 
	}
}
