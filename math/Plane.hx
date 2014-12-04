package fox.math;

/**
 * @author Three.js Project (http://threejs.org)
 * @author dcm
 */

class Plane {
	
	public var normal:Vector3;
	public var constant:Float;
	
	public function new(normal:Vector3 = null, constant:Float = 0) {
		this.normal = (normal != null ? normal : new Vector3(1,0,0));
		this.constant = constant;
	}
	
	public function set (normal:Vector3, constant:Float) : Plane {
		this.normal.copy(normal);
		this.constant = constant;
		return this;
	}
	
	public function setComponents (x:Float, y:Float, z:Float, w:Float) : Plane {
		normal.set(x, y, z);
		constant = w;
		return this;
	}
	
	public function setFromNormalAndCoplanarPoint (normal:Vector3, point:Vector3) : Plane {
		this.normal.copy(normal);
		constant = -point.dot(this.normal);
		return this;
	}
	
	public function setFromCoplanarPoints (a:Vector3, b:Vector3, c:Vector3) : Plane {
		var v1 = new Vector3();
		var v2 = new Vector3();
		var n = v1.subVectors(c, b).cross(v2.subVectors(a, b)).normalize();
		setFromNormalAndCoplanarPoint(n, a);
		return this;
	}
	
	public function copy (plane:Plane) : Plane {
		normal.copy(plane.normal);
		constant = plane.constant;
		return this;
	}
	
	public function normalize () : Plane {
		var inverseNormalLength = 1.0 / normal.length();
		normal.multiplyScalar(inverseNormalLength);
		constant *= inverseNormalLength;
		return this;
	}
	
	public function negate () : Plane {
		constant *= -1;
		normal.negate();
		return this;
	}
	
	public function distanceToPoint (point:Vector3) : Float {
		return normal.dot(point) + constant;
	}
	
	
	public function distanceToSphere (sphere:Sphere) : Float {
		return distanceToPoint(sphere.center) - sphere.radius;
	}
	
	public function projectPoint (point:Vector3, optTarget:Vector3 = null) : Vector3 {
		var result = (optTarget != null ? optTarget : new Vector3());
		return orthoPoint(point, result).sub(point).negate();
	}
	
	public function orthoPoint (point:Vector3, optTarget:Vector3 = null) : Vector3 {
		var result = (optTarget != null ? optTarget : new Vector3());
		var perpendicularMagnitude = distanceToPoint(point);
		return result.copy(normal).multiplyScalar(perpendicularMagnitude);
	}
	
	public function isIntersectionLine (line:Line3) : Bool {
		var startSign = distanceToPoint(line.start);
		var endSign = distanceToPoint(line.end);
		return ( startSign < 0 && endSign > 0 ) || ( endSign < 0 && startSign > 0 );
	}
	
	public function intersectLine (line:Line3, optTarget:Vector3 = null) : Vector3 {
		var v1 = new Vector3();
		var result = (optTarget != null ? optTarget : new Vector3());
		var direction = line.delta(v1);
		var denominator = normal.dot(direction);
		if (denominator == 0)  {
			if (distanceToPoint(line.start) == 0) return result.copy(line.start);
			return null;
		}
		
		var t = -(line.start.dot(normal) + constant) / denominator;
		if (t < 0 || t > 1) return null;
		
		return result.copy(direction).multiplyScalar(t).add(line.start);
	}
	
	public function coplanarPoint (optTarget:Vector3 = null) : Vector3 {
		var result = (optTarget != null ? optTarget : new Vector3());
		return result.copy(normal).multiplyScalar( -constant);
	}
	
	/*public function applyMatrix4 (m:Matrix4, normalMatrix:Matrix3 = null) : Plane
	{
		if (normalMatrix == null) normalMatrix = new Matrix3().getNormalMatrix(m);
		var newNormal = normal.clone().applyMatrix3(normalMatrix);
		var newCoplanarPoint = coplanarPoint(new Vector3());
		newCoplanarPoint.applyMatrix4(m);
		setFromNormalAndCoplanarPoint(newNormal, newCoplanarPoint);
		return this;
	}*/
	
	public function translate (offset:Vector3) : Plane {
		constant -= offset.dot(normal);
		return this;
	}
	
	public function equals (plane:Plane) : Bool {
		return plane.normal.equals(normal) && (plane.constant == constant);
	}
	
	public function clone () : Plane {
		return new Plane().copy(this);
	}
}
