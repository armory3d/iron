package fox.math;

/**
 * @author bhouston / http://exocortex.com
 * @author mrdoob / http://mrdoob.com/
 * @haxeport Krtolica Vujadin - GameStudioHx.com
 */

class Sphere {
	
	public var center:Vec3;
	public var radius:Float;
	
	public function new(center:Vec3 = null, radius:Float = 0) {
		this.center = center != null ? center : new Vec3();
		this.radius = radius;
	}	
	
	public function set(center:Vec3, radius:Float):Sphere {
		this.center.copy(center);
		this.radius = radius;
		return this;
	}	
	
	public function setFromPoints(points:Array<Vec3>, optionalCenter:Vec3 = null):Sphere {
		var box = new Box3();		

		var center = this.center;
		if (optionalCenter != null) {
			center.copy(optionalCenter);
		}
		else {
			box.setFromPoints(points).center(center);
		}

		var maxRadiusSq:Float = 0;
		for (i in 0...points.length) {
			maxRadiusSq = Math.max(maxRadiusSq, center.distanceToSquared(points[i]));
		}

		this.radius = std.Math.sqrt(maxRadiusSq);

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
	
	public function containsPoint(point:Vec3):Bool {
		return (point.distanceToSquared(this.center) <= (this.radius * this.radius));
	}	
	
	public function distanceToPoint(point:Vec3):Float {
		return (point.distanceTo(this.center) - this.radius);
	}	
	
	public function intersectsSphere(sphere:Sphere):Bool {
		var radiusSum = radius + sphere.radius;
		return (sphere.center.distanceToSquared(center) <= (radiusSum * radiusSum));
	}	
	
	public function clampPoint(point:Vec3, optionalTarget:Vec3 = null):Vec3 {
		var deltaLengthSq = this.center.distanceToSquared(point);

		var result = optionalTarget != null ? optionalTarget : new Vec3();
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
	
	public function applyMat4(matrix:Mat4):Sphere {
		this.center.applyMat4(matrix);
		this.radius = this.radius * matrix.getMaxScaleOnAxis();
		return this;
	}	
	
	public function translate(offset:Vec3):Sphere {
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
