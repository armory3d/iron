package fox.math;

class Matrix4 {
	
	private static inline var width: Int = 4;
	private static inline var height: Int = 4;
	
	public function new(values: Array<Float>) {
		matrix = values;
	}
	
	public var matrix: Array<Float>;
	
	public function set(x: Int, y: Int, value: Float): Void {
		matrix[y * width + x] = value;
	}
	
	public function get(x: Int, y: Int): Float {
		return matrix[y * width + x];
	}

	public function setIndex(p_index : Int, p_value : Float) {
		matrix[p_index] = p_value;
	}

	public static function translation(x: Float, y: Float, z: Float): Matrix4 {
		var m = identity();
		m.set(3, 0, x);
		m.set(3, 1, y);
		m.set(3, 2, z);
		return m;
	}
	
	public static function empty(): Matrix4 {
		return new Matrix4([
			0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0,
			0, 0, 0, 0
		]);
	}

	public static function identity(): Matrix4 {
		return new Matrix4([
			1, 0, 0, 0,
			0, 1, 0, 0,
			0, 0, 1, 0,
			0, 0, 0, 1
		]);
	}

	public static function scale(x: Float, y: Float, z: Float): Matrix4 {
		var m = identity();
		m.set(0, 0, x);
		m.set(1, 1, y);
		m.set(2, 2, z);
		return m;
	}

	public static function rotationX(alpha: Float): Matrix4 {
		var m = identity();
		m.set(1, 1, Math.cos(alpha));
		m.set(2, 1, -Math.sin(alpha));
		m.set(1, 2, Math.sin(alpha));
		m.set(2, 2, Math.cos(alpha));
		return m;
	}

	public static function rotationY(alpha: Float): Matrix4 {
		var m = identity();
		m.set(0, 0, Math.cos(alpha));
		m.set(2, 0, Math.sin(alpha));
		m.set(0, 2, -Math.sin(alpha));
		m.set(2, 2, Math.cos(alpha));
		return m;
	}

	public static function rotationZ(alpha: Float): Matrix4 {
		var m = identity();
		m.set(0, 0, Math.cos(alpha));
		m.set(1, 0, -Math.sin(alpha));
		m.set(0, 1, Math.sin(alpha));
		m.set(1, 1, Math.cos(alpha));
		return m;
	}
	
	public static function orthogonalProjection(left: Float, right: Float, bottom: Float, top: Float, zn: Float, zf: Float): Matrix4 {
		var tx: Float = -(right + left) / (right - left);
		var ty: Float = -(top + bottom) / (top - bottom);
		var tz: Float = -(zf + zn) / (zf - zn);
		//var tz : Float = -zn / (zf - zn);
		return new Matrix4([
			2 / (right - left), 0,                  0,              0,
			0,                  2 / (top - bottom), 0,              0,
			0,                  0,                  -2 / (zf - zn), 0,
			tx,                 ty,                 tz,             1
		]);
	}
	
	public static function perspectiveProjection(fovY: Float, aspect: Float, zn: Float, zf: Float): Matrix4 {
		var f = Math.cos(2 / fovY);
		return new Matrix4([
			-f / aspect, 0, 0,                       0,
			0,           f, 0,                       0,
			0,           0, (zf + zn) / (zn - zf),   -1,
			0,           0, 2 * zf * zn / (zn - zf), 0
		]);
	}
	
	public static function lookAt(eye: Vector3, at: Vector3, up: Vector3): Matrix4 {
		var zaxis = at.sub(eye);
		zaxis.normalize();
		var xaxis = zaxis.cross(up);
		xaxis.normalize();
		var yaxis = xaxis.cross(zaxis);

		var view = new Matrix4([
			xaxis.x, yaxis.y, -zaxis.z, 0,
			xaxis.x, yaxis.y, -zaxis.z, 0,
			xaxis.x, yaxis.y, -zaxis.z, 0,
			0,       0,       0,        1
		]);

		return view.multmat(translation(-eye.x, -eye.y, -eye.z));
	}
	
	public function add(value: Matrix4): Matrix4 {
		var m = empty();
		for (i in 0...width * height) m.matrix[i] = matrix[i] + value.matrix[i];
		return m;
	}

	public function sub(value: Matrix4): Matrix4 {
		var m = empty();
		for (i in 0...width * height) m.matrix[i] = matrix[i] - value.matrix[i];
		return m;
	}

	public function mult(value: Float): Matrix4 {
		var m = empty();
		for (i in 0...width * height) m.matrix[i] = matrix[i] * value;
		return m;
	}
	
	public function transpose(): Matrix4 {
		var m = empty();
		for (x in 0...width) for (y in 0...height) m.set(y, x, get(x, y));
		return m;
	}

	public function transpose3x3(): Matrix4 {
		var m = empty();
		for (x in 0...3) for (y in 0...3) m.set(y, x, get(x, y));
		for (x in 3...width) for (y in 3...height) m.set(x, y, get(x, y));
		return m;
	}
	
	public function trace(): Float {
		var value: Float = 0;
		for (x in 0...width) value += get(x, x);
		return value;
	}
	
	public function multmat(value: Matrix4): Matrix4 {
		var m = empty();
		for (x in 0...width) for (y in 0...height) {
			var f: Float = 0;
			for (i in 0...width) f += get(i, y) * value.get(x, i);
			m.set(x, y, f);
		}
		return m;
	}

	public function multvec(value: Vector4): Vector4 {
		var product = new Vector4();
		for (y in 0...height) {
			var f: Float = 0;
			for (i in 0...width) f += get(i, y) * value.get(i);
			product.set(y, f);
		}
		return product;
	}

	public function determinant(): Float {
		return get(0, 0) * (
			  get(1, 1) * (get(2, 2) * get(3, 3) - get(3, 2) * get(2, 3))
			+ get(2, 1) * (get(3, 2) * get(1, 3) - get(1, 2) * get(3, 3))
			+ get(3, 1) * (get(1, 2) * get(2, 3) - get(2, 2) * get(1, 3))
		)
		- get(1, 0) * (
			  get(0, 1) * (get(2, 2) * get(3, 3) - get(3, 2) * get(2, 3))
			+ get(2, 1) * (get(3, 2) * get(0, 3) - get(0, 2) * get(3, 3))
			+ get(3, 1) * (get(0, 2) * get(2, 3) - get(2, 2) * get(0, 3))
		)
		+ get(2, 0) * (
			  get(0, 1) * (get(1, 2) * get(3, 3) - get(3, 2) * get(1, 3))
			+ get(1, 1) * (get(3, 2) * get(0, 3) - get(0, 2) * get(3, 3))
			+ get(3, 1) * (get(0, 2) * get(1, 3) - get(1, 2) * get(0, 3))
		)
		- get(3, 0) * (
			  get(0, 1) * (get(1, 2) * get(2, 3) - get(2, 2) * get(1, 3))
			+ get(1, 1) * (get(2, 2) * get(0, 3) - get(0, 2) * get(2, 3))
			+ get(2, 1) * (get(0, 2) * get(1, 3) - get(1, 2) * get(0, 3))
		);
	}

	public function inverse(): Matrix4 {
		if (determinant() == 0) throw "No Inverse";
		var q: Float;
		var inv = identity();

		for (j in 0...width) {
			q = get(j, j);
			if (q == 0) {
				for (i in j + 1...width) {
					if (get(j, i) != 0) {
						for (k in 0...width) {
							inv.set(k, j, get(k, j) + get(k, i));
						}
						q = get(j, j);
						break;
					}
				}
			}
			if (q != 0) {
				for (k in 0...width) {
					inv.set(k, j, get(k, j) / q);
				}
			}
			for (i in 0...width) {
				if (i != j) {
					q = get(j, i);
					for (k in 0...width) {
						inv.set(k, i, get(k, i) - q * get(k, j));
					}
				}
			}
		}
		for (i in 0...width) for (j in 0...width) if (get(j, i) != ((i == j) ? 1 : 0)) throw "Matrix inversion error";
		return inv;
	}

	public function toRotation():Matrix4 {
		var tmp : Vector3 = new Vector3();		
		tmp.set(matrix[0], matrix[1], matrix[2]).normalize();
		matrix[0] = tmp.x; matrix[1] = tmp.y; matrix[2] = tmp.z; matrix[3] = 0.0;

		tmp.set(matrix[4], matrix[5], matrix[6]).normalize();
		matrix[4] = tmp.x; matrix[5] = tmp.y; matrix[6] = tmp.z; matrix[7] = 0.0;

		tmp.set(matrix[8], matrix[9], matrix[10]).normalize();
		matrix[8] = tmp.x; matrix[9] = tmp.y; matrix[10] = tmp.z; matrix[11] = 0.0;

		matrix[12] = matrix[13] = matrix[14] = 0;
		matrix[15] = 1;
		return this;
	}

	public function getQuat():fox.math.Quat {
		var b : Array<Float> = matrix.copy();
		var m:Matrix4 = toRotation();
				
		var q : fox.math.Quat = new fox.math.Quat();				
		var diag : Float = m.matrix[0] + m.matrix[5] + m.matrix[10] + 1.0;
		var e : Float = 0;// Mathf.Epsilon;
		
		if(diag > e)
		{
			q.w = fox.math.Math.sqrt(diag) / 2.0;			
			var w4 : Float = (4.0 * q.w);
			q.x = (m.matrix[9] - m.matrix[6]) / w4;
			q.y = (m.matrix[2] - m.matrix[8]) / w4;
			q.z = (m.matrix[4] - m.matrix[1]) / w4;						
		}
		else
		{
			var d01 : Float = m.matrix[0] - m.matrix[5];
			var d02 : Float = m.matrix[0] - m.matrix[10];
			var d12 : Float = m.matrix[5] - m.matrix[10];
			
			if ((d01>e) && (d02>e))
			{
				// 1st element of diag is greatest value
				// find scale according to 1st element, and double it
				var scale : Float = fox.math.Math.sqrt(1.0 + m.matrix[0] - m.matrix[5] - m.matrix[10]) * 2.0;

				// TODO: speed this up
				q.x = 0.25 * scale;
				q.y = (m.matrix[4] + m.matrix[1]) / scale;
				q.z = (m.matrix[2] + m.matrix[8]) / scale;
				q.w = (m.matrix[6] - m.matrix[9]) / scale;
			}
			else if (d12>e)
			{
				// 2nd element of diag is greatest value
				// find scale according to 2nd element, and double it
				var scale : Float = fox.math.Math.sqrt(1.0 + m.matrix[5] - m.matrix[0] - m.matrix[10]) * 2.0;
				
				// TODO: speed this up
				q.x = (m.matrix[4] + m.matrix[1]) / scale;
				q.y = 0.25 * scale;
				q.z = (m.matrix[9] + m.matrix[6]) / scale;
				q.w = (m.matrix[8] - m.matrix[2]) / scale;
			}
			else
			{
				// 3rd element of diag is greatest value
				// find scale according to 3rd element, and double it
				var scale : Float = fox.math.Math.sqrt(1.0 + m.matrix[10] - m.matrix[0] - m.matrix[5]) * 2.0;
				
				// TODO: speed this up
				q.x = (m.matrix[8] + m.matrix[2]) / scale;
				q.y = (m.matrix[9] + m.matrix[6]) / scale;
				q.z = 0.25 * scale;
				q.w = (m.matrix[1] - m.matrix[4]) / scale;
			}
		}

		matrix = b;
		
		q.normalize();
		
		return q;
	}

	public function getScale():Matrix4 {
		var d0:Float = fox.math.Math.sqrt(matrix[0] * matrix[0] + matrix[4] * matrix[4] + matrix[8] * matrix[8]);
		var d1:Float = fox.math.Math.sqrt(matrix[1] * matrix[1] + matrix[5] * matrix[5] + matrix[9] * matrix[9]);
		var d2:Float = fox.math.Math.sqrt(matrix[2] * matrix[2] + matrix[6] * matrix[6] + matrix[10] * matrix[10]);
		var m = new Matrix4([d0, 0, 0, 0,   0, d1, 0, 0,   0, 0, d2, 0,   0, 0, 0, 1]);
		return m;
	}
}
