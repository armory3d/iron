package fox.math;

class Vector3 {
	
	public function new(x: Float = 0, y: Float = 0, z: Float = 0): Void {
        this.x = x;
        this.y = y;
        this.z = z;
    }
    
    public var x: Float;
    public var y: Float;
    public var z: Float;
    public var length(get, set): Float;
    
    private function get_length(): Float {
        return Math.sqrt(x * x + y * y + z * z);
    }
    
    private function set_length(length: Float): Float {
        if (get_length() == 0) return 0;
        var mul = length / get_length();
        x *= mul;
        y *= mul;
        z *= mul;
        return length;
    }

    public var clone(get_clone, null):Vector3;
    private function get_clone():Vector3 { return new Vector3(x, y, z); }

    public function set(x:Float, y:Float, z:Float):Vector3 {
        this.x = x;
        this.y = y;
        this.z = z;
        return this;
    }
    
    public function add(vec: Vector3): Vector3 {
        return new Vector3(x + vec.x, y + vec.y, z + vec.z);
    }
    
    public function sub(vec: Vector3): Vector3 {
        return new Vector3(x - vec.x, y - vec.y, z - vec.z);
    }
    
    public function mult(value: Float): Vector3 {
        return new Vector3(x * value, y * value, z * value);
    }
    
    public function dot(v: Vector3): Float {
        return x * v.x + y * v.y + z * v.z;
    }
    
    public function cross(v: Vector3): Vector3 {
        var _x = y * v.z - z * v.y;
        var _y = z * v.x - x * v.z;
        var _z = x * v.y - y * v.x;
        return new Vector3(_x, _y, _z);
    }
    
    public function normalize(): Void {
        var l = 1 / length;
        x *= l;
        y *= l;
        z *= l;
    }

	public function applyProjection(m:Matrix4):Vector3 {
        var x = this.x, y = this.y, z = this.z;

        var e = m.matrix;
        var d = 1 / ( e[3] * x + e[7] * y + e[11] * z + e[15] ); // perspective divide

        this.x = ( e[0] * x + e[4] * y + e[8]  * z + e[12] ) * d;
        this.y = ( e[1] * x + e[5] * y + e[9]  * z + e[13] ) * d;
        this.z = ( e[2] * x + e[6] * y + e[10] * z + e[14] ) * d;

        return this;
    }
}
