package iron.math;

import iron.App;
import iron.object.CameraObject;
import iron.object.MeshObject;
import iron.object.Transform;
import iron.math.Ray.Plane;

class RayCaster {

	public static function getRay(inputX:Float, inputY:Float, camera:CameraObject):Ray {

		var start = new Vec4();
		var end = new Vec4();

		getDirection(start, end, inputX, inputY, camera);

		return new Ray(start, end);
	}


	public static function getDirection(start:Vec4, end:Vec4, inputX:Float, inputY:Float, camera:CameraObject) {
		// TODO: return end only
		// TODO: speed up using http://halogenica.net/ray-casting-and-picking-using-bullet-physics/

		// Get 3D point form screen coords
		start.x =  (inputX / App.w()) * 2 - 1;
		start.y = -(inputY / App.h()) * 2 + 1;

		// Set two vectors with opposing z values
		start.z = -1.0;
		end.x = start.x;
		end.y = start.y;
		end.z = 0.0;

		start.unproject(camera.P, camera.V);
		end.unproject(camera.P, camera.V);

		// Find direction from start to end
		end.sub(start);
		end.normalize();

		end.x *= camera.data.raw.far_plane;
		end.y *= camera.data.raw.far_plane;
		end.z *= camera.data.raw.far_plane;
	}

	public static function boxIntersect(transform:Transform, inputX:Float, inputY:Float, camera:CameraObject):Vec4 {
		var ray = getRay(inputX, inputY, camera);

		var t = transform;
		var c = new Vec4(t.absx(), t.absy(), t.absz());
		var s = new Vec4(t.size.x, t.size.y, t.size.z);
		return ray.intersectBox(c, s);
	}

	public static function getClosestBoxIntersect(transforms:Array<Transform>, inputX:Float, inputY:Float, camera:CameraObject):Transform {
		var intersects:Array<Transform> = [];

		// Get intersects
		for (t in transforms) {
			var intersect = boxIntersect(t, inputX, inputY, camera);
			if (intersect != null) intersects.push(t);
		}

		// No intersects
		if (intersects.length == 0) return null;

		// Get closest intersect
		var closest:Transform = null;
		var minDist:Float = std.Math.POSITIVE_INFINITY;
		for (t in intersects) {
			var dist = Vec4.distance3d(t.loc, camera.transform.loc);
			if (dist < minDist) {
				minDist = dist;
				closest = t;
			}
		}

		return closest;
	}

	public static function planeIntersect(normal:Vec4, a:Vec4, inputX:Float, inputY:Float, camera:CameraObject):Vec4 {
		var ray = getRay(inputX, inputY, camera);

		var plane = new Plane();
		plane.setFromNormalAndCoplanarPoint(normal, a);

		return ray.intersectPlane(plane);
	}
	
	// Project screen-space point onto 3D plane
	static var loc = new Vec4();
	static var nor = new Vec4();
	static var m = Mat4.identity();
	public static function getPlaneUV(obj:MeshObject, screenX:Float, screenY:Float, camera:CameraObject):Vec2 {
		// Get normal from data
		var normals = obj.data.geom.normals;
		nor.set(normals[0], normals[1], normals[2]);
		
		// Rotate by world rotation matrix
		m.setFrom(obj.transform.matrix);
		// m.toRotation();
		m.getInverse(m);
		m.transpose3x3();
		m._30 = m._31 = m._32 = 0;
		nor.applymat(m);
		nor.normalize();
	
		// Plane intersection
		loc.set(obj.transform.absx(), obj.transform.absy(), obj.transform.absz());
		var hit = RayCaster.planeIntersect(nor, loc, screenX, screenY, camera);
		
		// Convert to uv
		if (hit != null) {
			var a = nor.x;
			var b = nor.y;
			var c = nor.z;
			var e = 0.0001;
			var u = a >= e && b >= e ? new Vec4(b, -a, 0) : new Vec4(c, -a, 0);
			u.normalize();
			var v = nor.clone();
			v.cross(u);
			
			hit.sub(loc); // Center
			var uCoord = u.dot(hit);
			var vCoord = v.dot(hit);
			
			var size = obj.transform.size;
			var hx = size.x / 2;
			// TODO: depends on plane facing normal, do not use size of lenght 0
			var hy = size.z > size.y ? size.z / 2 : size.y / 2;
			
			// Screen spance
			var ix = uCoord / hx * (-1) * 0.5 + 0.5;
			var iy = vCoord / hy * 0.5 + 0.5;
			
			return new Vec2(ix, iy);
		}
		return null;
	}
}
