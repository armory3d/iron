package iron.math;

/**
 * @author bhouston / http://exocortex.com
 * @haxeport Krtolica Vujadin - GameStudioHx.com
 */

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
	
	public function recast(t:Float):Ray	{
		var v1 = new Vec4();
		this.origin.copy2(this.at(t, v1));
		return this;
	}	
	
	public function closestPointToPoint(point:Vec4, optionalTarget:Vec4 = null):Vec4 {
		var result = optionalTarget == null ? new Vec4() : optionalTarget;
		result.subVectors(point, this.origin);
		var directionDistance = result.dot(this.direction);
		if (directionDistance < 0) {
			return result.copy2(this.origin);
		}

		return result.copy2(this.direction).multiplyScalar(directionDistance).add(this.origin);
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
	
	public function distanceSqToSegment(v0:Vec4, v1:Vec4, optionalPointOnRay:Vec4 = null, optionalPointOnSegment:Vec4 = null) {
		// from http://www.geometrictools.com/LibMathematics/Distance/Wm5DistRay3Segment3.cpp
		// It returns the min distance between the ray and the segment
		// defined by v0 and v1
		// It can also set two optional targets :
		// - The closest point on the ray
		// - The closest point on the segment
		var segCenter = v0.clone().add(v1).multiplyScalar(0.5);
		var segDir = v1.clone().sub(v0).normalize2();
		var segExtent = v0.distanceTo(v1) * 0.5;
		var diff = this.origin.clone().sub(segCenter);
		var a01 = -this.direction.dot(segDir);
		var b0 = diff.dot(this.direction);
		var b1 = -diff.dot(segDir);
		var c = diff.lengthSq();
		var det = Math.abs(1 - a01 * a01);
		var s0, s1, sqrDist, extDet;

		if (det >= 0) {
			// The ray and segment are not parallel.
			s0 = a01 * b1 - b0;
			s1 = a01 * b0 - b1;
			extDet = segExtent * det;
			if (s0 >= 0) {
				if (s1 >= -extDet) {
					if (s1 <= extDet) {
						// region 0
						// Minimum at interior points of ray and segment.
						var invDet = 1 / det;
						s0 *= invDet;
						s1 *= invDet;
						sqrDist = s0 * (s0 + a01 * s1 + 2 * b0) + s1 * (a01 * s0 + s1 + 2 * b1) + c;
					} else {
						// region 1
						s1 = segExtent;
						s0 = Math.max(0, - (a01 * s1 + b0));
						sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
					}
				} else {
					// region 5
					s1 = - segExtent;
					s0 = Math.max(0, - (a01 * s1 + b0));
					sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
				}
			} else {
				if (s1 <= -extDet) {
					// region 4
					s0 = Math.max(0, - (-a01 * segExtent + b0));
					s1 = (s0 > 0) ? -segExtent : Math.min(Math.max(-segExtent, -b1), segExtent);
					sqrDist = - s0 * s0 + s1 * (s1 + 2 * b1) + c;
				} else if (s1 <= extDet) {
					// region 3
					s0 = 0;
					s1 = Math.min(Math.max(-segExtent, -b1), segExtent);
					sqrDist = s1 * (s1 + 2 * b1) + c;
				} else {
					// region 2
					s0 = Math.max(0, - (a01 * segExtent + b0));
					s1 = (s0 > 0) ? segExtent : Math.min(Math.max(-segExtent, -b1), segExtent);
					sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
				}
			}
		} else {
			// Ray and segment are parallel.
			s1 = (a01 > 0) ? -segExtent : segExtent;
			s0 = Math.max(0, - (a01 * s1 + b0));
			sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
		}

		if (optionalPointOnRay != null) {
			optionalPointOnRay.copy2(this.direction.clone().multiplyScalar(s0).add(this.origin));
		}

		if (optionalPointOnSegment != null) {
			optionalPointOnSegment.copy2(segDir.clone().multiplyScalar(s1).add(segCenter));
		}

		return sqrDist;
	}
	
	public function isIntersectionSphere(sphere:Sphere):Bool {
		return distanceToPoint(sphere.center) <= sphere.radius;
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
			if(plane.distanceToPoint(this.origin) == 0) {
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
	
	public function isIntersectionBox(box:Box3):Bool {
		var v = new Vec4();
		return this.intersectBox(box, v) != null;
	}
	
	public function intersectBox(box:Box3, optionalTarget:Vec4 = null):Vec4 {
		// http://www.scratchapixel.com/lessons/3d-basic-lessons/lesson-7-intersecting-simple-shapes/ray-box-intersection/
		var tmin,tmax,tymin,tymax,tzmin,tzmax;

		var invdirx = 1 / this.direction.x;
		var	invdiry = 1 / this.direction.y;
		var invdirz = 1 / this.direction.z;

		var origin = this.origin;

		if (invdirx >= 0) {				
			tmin = (box.min.x - origin.x) * invdirx;
			tmax = (box.max.x - origin.x) * invdirx;
		}
		else { 
			tmin = (box.max.x - origin.x) * invdirx;
			tmax = (box.min.x - origin.x) * invdirx;
		}			

		if (invdiry >= 0) {		
			tymin = (box.min.y - origin.y) * invdiry;
			tymax = (box.max.y - origin.y) * invdiry;
		}
		else {
			tymin = (box.max.y - origin.y) * invdiry;
			tymax = (box.min.y - origin.y) * invdiry;
		}

		if ((tmin > tymax) || (tymin > tmax)) return null;

		// These lines also handle the case where tmin or tmax is NaN
		// (result of 0 * Infinity). x !== x returns true if x is NaN		
		if (tymin > tmin || tmin != tmin) tmin = tymin;
		if (tymax < tmax || tmax != tmax) tmax = tymax;

		if (invdirz >= 0) {		
			tzmin = (box.min.z - origin.z) * invdirz;
			tzmax = (box.max.z - origin.z) * invdirz;
		}
		else {
			tzmin = (box.max.z - origin.z) * invdirz;
			tzmax = (box.min.z - origin.z) * invdirz;
		}

		if ((tmin > tzmax) || (tzmin > tmax)) return null;
		if (tzmin > tmin || tmin != tmin ) tmin = tzmin;
		if (tzmax < tmax || tmax != tmax ) tmax = tzmax;

		//return point closest to the ray (positive side)
		if (tmax < 0) return null;

		return this.at(tmin >= 0 ? tmin : tmax, optionalTarget);
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

	public function equals(ray:Ray):Bool {
		return ray.origin.equals(this.origin) && ray.direction.equals(this.direction);
	}

	public function clone():Ray {
		return new Ray().copy2(this);
	}
}
