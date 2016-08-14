package iron.math;

class Ray {
	
	public var origin:Vec4;
	public var direction:Vec4;
	
	public function new(origin:Vec4 = null, direction:Vec4 = null) {
		this.origin = origin == null ? new Vec4() : origin;		
		this.direction = direction == null ? new Vec4() : direction;
	}	
	
	public function set(origin:Vec4, direction:Vec4):Ray {
		this.origin.copy2(origin);
		this.direction.copy2(direction);
		return this;
	}	
	
	public function copy2(ray:Ray):Ray {
		return set(ray.origin, ray.direction);
	}	
	
	public function at(t:Float, optionalTarget:Vec4 = null):Vec4 {
		var result = optionalTarget != null ? optionalTarget : new Vec4();
		return result.copy2(direction).multiplyScalar(t).add(origin);
	}
	
	public function distanceToPoint(point:Vec4):Float {
		var v1 = new Vec4();
		var directionDistance = v1.subVectors(point, this.origin).dot(this.direction);
		
		// point behind the ray
		if (directionDistance < 0) {
			return this.origin.distanceTo(point);
		}

		v1.copy2(this.direction).multiplyScalar(directionDistance).add(this.origin);

		return v1.distanceTo(point);
	}	
	
	public function isIntersectionSphere(sphereCenter:Vec4, sphereRadius:Float):Bool {
		return distanceToPoint(sphereCenter) <= sphereRadius;
	}	
	
	public function isIntersectionPlane(plane:Plane):Bool {
		// check if the ray lies on the plane first
		var distToPoint = plane.distanceToPoint(this.origin);

		if (distToPoint == 0) {
			return true;
		}

		var denominator = plane.normal.dot(this.direction);

		if (denominator * distToPoint < 0) {
			return true;
		}

		// ray origin is behind the plane (and is pointing behind it)
		return false;
	}	
	
	public function distanceToPlane(plane:Plane):Float {
		var denominator = plane.normal.dot(this.direction);
		if (denominator == 0) {
			// line is coplanar, return origin
			if (plane.distanceToPoint(this.origin) == 0) {
				return 0;
			}

			// Null is preferable to undefined since undefined means.... it is undefined
			return -1;
		}

		var t = -(this.origin.dot(plane.normal) + plane.constant) / denominator;

		// Return if the ray never intersects the plane
		return t >= 0 ? t :  -1;
	}	
	
	public function intersectPlane(plane:Plane, optionalTarget:Vec4 = null):Vec4 {
		var t = this.distanceToPlane(plane);

		//if (t == null) {
		if (t == -1) {
			return null;
		}

		return this.at(t, optionalTarget);
	}
	
	public function isIntersectionBox(center:Vec4, size:Vec4):Bool {
		return this.intersectBox(center, size) != null;
	}
	
	public function intersectBox(center:Vec4, size:Vec4):Vec4 {
		// http://www.scratchapixel.com/lessons/3d-basic-lessons/lesson-7-intersecting-simple-shapes/ray-box-intersection/
		var tmin, tmax, tymin, tymax, tzmin, tzmax;

		var halfX = size.x / 2;
		var halfY = size.x / 2;
		var halfZ = size.x / 2;
		var boxMinX = center.x - halfX;
		var boxMinY = center.y - halfY;
		var boxMinZ = center.z - halfZ;
		var boxMaxX = center.x + halfX;
		var boxMaxY = center.y + halfY;
		var boxMaxZ = center.z + halfZ;

		var invdirx = 1 / this.direction.x;
		var	invdiry = 1 / this.direction.y;
		var invdirz = 1 / this.direction.z;

		var origin = this.origin;

		if (invdirx >= 0) {				
			tmin = (boxMinX - origin.x) * invdirx;
			tmax = (boxMaxX - origin.x) * invdirx;
		}
		else { 
			tmin = (boxMaxX - origin.x) * invdirx;
			tmax = (boxMinX - origin.x) * invdirx;
		}			

		if (invdiry >= 0) {		
			tymin = (boxMinY - origin.y) * invdiry;
			tymax = (boxMaxY - origin.y) * invdiry;
		}
		else {
			tymin = (boxMaxY - origin.y) * invdiry;
			tymax = (boxMinY - origin.y) * invdiry;
		}

		if ((tmin > tymax) || (tymin > tmax)) return null;

		// These lines also handle the case where tmin or tmax is NaN
		// (result of 0 * Infinity). x !== x returns true if x is NaN		
		if (tymin > tmin || tmin != tmin) tmin = tymin;
		if (tymax < tmax || tmax != tmax) tmax = tymax;

		if (invdirz >= 0) {		
			tzmin = (boxMinZ - origin.z) * invdirz;
			tzmax = (boxMaxZ - origin.z) * invdirz;
		}
		else {
			tzmin = (boxMaxZ - origin.z) * invdirz;
			tzmax = (boxMinZ - origin.z) * invdirz;
		}

		if ((tmin > tzmax) || (tzmin > tmax)) return null;
		if (tzmin > tmin || tmin != tmin ) tmin = tzmin;
		if (tzmax < tmax || tmax != tmax ) tmax = tzmax;

		// Return point closest to the ray (positive side)
		if (tmax < 0) return null;

		return this.at(tmin >= 0 ? tmin : tmax);
	}
	
	public function intersectTriangle(a:Vec4, b:Vec4, c:Vec4, backfaceCulling:Bool, optionalTarget:Vec4 = null):Vec4 {
		// Compute the offset origin, edges, and normal.
		var diff = new Vec4();
		var edge1 = new Vec4();
		var edge2 = new Vec4();
		var normal = new Vec4();

		// from http://www.geometrictools.com/LibMathematics/Intersection/Wm5IntrRay3Triangle3.cpp
		edge1.subVectors(b, a);
		edge2.subVectors(c, a);
		normal.crossVectors(edge1, edge2);

		// Solve Q + t*D = b1*E1 + b2*E2 (Q = kDiff, D = ray direction,
		// E1 = kEdge1, E2 = kEdge2, N = Cross(E1,E2)) by
		//   |Dot(D,N)|*b1 = sign(Dot(D,N))*Dot(D,Cross(Q,E2))
		//   |Dot(D,N)|*b2 = sign(Dot(D,N))*Dot(D,Cross(E1,Q))
		//   |Dot(D,N)|*t = -sign(Dot(D,N))*Dot(Q,N)
		var DdN = this.direction.dot(normal);
		var sign;
		
		if (DdN > 0) {
			if (backfaceCulling) return null;
			sign = 1;
		} else if (DdN < 0) {
			sign = -1;
			DdN = -DdN;
		} else {
			return null;
		}

		diff.subVectors(this.origin, a);
		var DdQxE2 = sign * this.direction.dot(edge2.crossVectors(diff, edge2));

		// b1 < 0, no intersection
		if (DdQxE2 < 0) {
			return null;
		}

		var DdE1xQ = sign * this.direction.dot(edge1.cross2(diff));

		// b2 < 0, no intersection
		if (DdE1xQ < 0) {
			return null;
		}

		// b1+b2 > 1, no intersection
		if (DdQxE2 + DdE1xQ > DdN) {
			return null;
		}

		// Line intersects triangle, check if ray does.
		var QdN = -sign * diff.dot(normal);

		// t < 0, no intersection
		if (QdN < 0) {
			return null;
		}

		// Ray intersects triangle.
		return this.at(QdN / DdN, optionalTarget);
	}
	
	public function applyMat4(matrix4:Mat4):Ray {
		this.direction.add(this.origin).applyMat4(matrix4);
		this.origin.applyMat4(matrix4);
		this.direction.sub(this.origin);
		this.direction.normalize2();

		return this;
	}
}

class Plane {
	public var normal = new Vec4(1.0, 0.0, 0.0);
	public var constant = 0.0;

	public function new() { }

	public function distanceToPoint(point:Vec4):Float {
		return normal.dot(point) + constant;
	}

	public function setFromNormalAndCoplanarPoint(normal:Vec4, point:Vec4):Plane {
		this.normal.copy2(normal);
		constant = -point.dot(this.normal);
		return this;
	}
}
