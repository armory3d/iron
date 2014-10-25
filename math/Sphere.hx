package fox.math;

/**
 * @author bhouston / http://exocortex.com
 * @author mrdoob / http://mrdoob.com/
 */

/**
 * 
 * @haxeport Krtolica Vujadin - GameStudioHx.com
 */

class Sphere {
	
	public var center:Vector3;
	public var radius:Float;
	
	public function new(center:Vector3 = null, radius:Float = 0) {
		this.center = center != null ? center : new Vector3();
		this.radius = radius;
	}	
	
	public function set(center:Vector3, radius:Float):Sphere {
		this.center.copy(center);
		this.radius = radius;
		return this;
	}	
	
	public function setFromPoints(points:Array<Vector3>, optionalCenter:Vector3 = null):Sphere {
		var box = new Box3();		

		var center = this.center;
		if (optionalCenter != null) {
			center.copy(optionalCenter);
		} else {
			box.setFromPoints(points).center(center);
		}

		var maxRadiusSq:Float = 0;
		for (i in 0...points.length) {
			maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(points[i]));
		}

		this.radius = Math.sqrt(maxRadiusSq);

		return this;	
	}	
	
	public function copy(sphere:Sphere):Sphere {
		this.center.copy(sphere.center);
		this.radius = sphere.radius;
		return this;
	}	
	
	public function empty():Bool {
		return (radius <= 0);
	}	
	
	public function containsPoint(point:Vector3):Bool {
		return (point.distanceToSquared(this.center) <= (this.radius * this.radius));
	}	
	
	public function distanceToPoint(point:Vector3):Float {
		return (point.distanceTo(this.center) - this.radius);
	}	
	
	public function intersectsSphere(sphere:Sphere):Bool {
		var radiusSum = radius + sphere.radius;
		return (sphere.center.distanceToSquared(center) <= (radiusSum * radiusSum));
	}	
	
	public function clampPoint(point:Vector3, optionalTarget:Vector3 = null):Vector3 {
		var deltaLengthSq = this.center.distanceToSquared(point);

		var result = optionalTarget != null ? optionalTarget : new Vector3();
		result.copy(point);

		if (deltaLengthSq > (this.radius * this.radius)) {
			result.sub(this.center).normalize();
			result.multiplyScalar(this.radius).add(this.center);
		}

		return result;
	}	
	
	public function getBoundingBox(optionalTarget:Box3 = null):Box3 {
		var box = optionalTarget != null ? optionalTarget : new Box3();
		box.set(this.center, this.center);
		box.expandByScalar(this.radius);
		return box;
	}	
	
	public function applyMatrix4(matrix:Matrix4):Sphere {
		this.center.applyMatrix4(matrix);
		this.radius = this.radius * matrix.getMaxScaleOnAxis();
		return this;
	}	
	
	public function translate(offset:Vector3):Sphere {
		this.center.add(offset);
		return this;
	}	
	
	public function equals(sphere:Sphere):Bool {
		return sphere.center.equals(this.center) && (sphere.radius == this.radius);
	}	
	
	public function clone():Sphere {
		return new Sphere().copy(this);
	}
	
}
