package iron.object;

import iron.math.Mat4;
import iron.math.Vec4;
import iron.math.Quat;
import iron.data.LampData;
import iron.object.CameraObject.FrustumPlane;
import iron.Scene;

class LampObject extends Object {

	public static var cascadeCount = 1;
	public static var cascadeSplitFactor = 0.8;
	public static var cascadeBounds = 1.0;
	#if arm_csm
	var cascadeData:kha.arrays.Float32Array = null;
	var cascadeVP:Array<Mat4>;
	var camSlicedP:Array<Mat4> = null;
	var cascadeSplit:Array<Float>;
	#else
	var camSlicedP:Mat4 = null;
	#end

	public var data:LampData;

	public var V:Mat4 = Mat4.identity();
	public var P:Mat4 = null;
	public var VP:Mat4 = Mat4.identity();

	public var frustumPlanes:Array<FrustumPlane> = null;
	static var corners:Array<Vec4> = null;

	public function new(data:LampData) {
		super();
		
		this.data = data;

		var type = data.raw.type;
		var fov = data.raw.fov;
		
		if (type == "sun") {
			if (corners == null) {
				corners = [];
				for (i in 0...8) corners.push(new Vec4());
			}
			P = Mat4.identity();
		}
		else if (type == "point" || type == "area") {
			P = Mat4.persp(fov, 1, data.raw.near_plane, data.raw.far_plane);
		}
		else if (type == "spot") {
			P = Mat4.persp(fov, 1, data.raw.near_plane, data.raw.far_plane);
		}

		Scene.active.lamps.push(this);
	}

	public override function remove() {
		if (Scene.active != null) Scene.active.lamps.remove(this);
		super.remove();
	}

	static function setCorners() {
		corners[0].set(-1.0, -1.0, 1.0);
		corners[1].set(-1.0, -1.0, -1.0);
		corners[2].set(-1.0, 1.0, 1.0);
		corners[3].set(-1.0, 1.0, -1.0);
		corners[4].set(1.0, -1.0, 1.0);
		corners[5].set(1.0, -1.0, -1.0);
		corners[6].set(1.0, 1.0, 1.0);
		corners[7].set(1.0, 1.0, -1.0);
	}

	static var m = Mat4.identity();
	public function buildMatrices(camera:CameraObject) {
		transform.buildMatrix();
		if (data.raw.type == "sun") { // Cover camera frustum
			#if (!arm_csm) // Otherwise set cascades on mesh draw
			setCascade(camera, 0);
			#end
		}
		else { // Point, spot, area
			V.getInverse(transform.world);
			updateViewFrustum(camera);
		}
	}

	static inline function mix(a:Float, b:Float, f:Float):Float { return a * (1 - f) + b * f; }

	public function setCascade(camera:CameraObject, cascade:Int) {

		#if arm_vr
		m.setFrom(camera.leftV);
		#else
		m.setFrom(camera.V);
		#end

		#if ((!arm_voxelgi_revox) && (rp_gi == "Voxel GI"))
		// Cover the voxelization volume if revoxelization is turned off
		m.setLookAt(new Vec4(0, 0, Main.voxelgiHalfExtents), new Vec4(0, 0, 0), new Vec4(0, 1, 0));
		#end

		#if arm_csm
		if (camSlicedP == null) {
			camSlicedP = [];
			cascadeSplit = [];
			var aspect = camera.data.raw.aspect != null ? camera.data.raw.aspect : iron.App.w() / iron.App.h();
			var fov = camera.data.raw.fov;
			var near = camera.data.raw.near_plane;
			var far = camera.data.raw.far_plane;
			var factor = cascadeCount > 2 ? cascadeSplitFactor : cascadeSplitFactor * 0.25;
			for (i in 0...cascadeCount) {
				var f = i + 1.0;
				var cfar = mix(
					near + (f / cascadeCount) * (far - near),
					near * Math.pow(far / near, f / cascadeCount),
					factor);
				cascadeSplit.push(cfar);
				camSlicedP.push(Mat4.persp(fov, aspect, near, cfar));
			}
		}
		m.multmat2(camSlicedP[cascade]);
		#else
		if (camSlicedP == null) { // Fit to lamp far plane
			var fov = camera.data.raw.fov;
			var near = data.raw.near_plane;
			var far = data.raw.far_plane;
			var aspect = camera.data.raw.aspect != null ? camera.data.raw.aspect : iron.App.w() / iron.App.h();
			camSlicedP = Mat4.persp(fov, aspect, near, far);
		}
		m.multmat2(camSlicedP);
		#end
		
		m.getInverse(m);
		V.getInverse(transform.world);
		V.toRotation();
		m.multmat2(V);
		setCorners();
		for (v in corners) {
			v.applymat4(m);
			v.set(v.x / v.w, v.y / v.w, v.z / v.w);
		}
		
		var minx = corners[0].x;
		var miny = corners[0].y;
		var minz = corners[0].z;
		var maxx = corners[0].x;
		var maxy = corners[0].y;
		var maxz = corners[0].z;
		for (v in corners) {
			if (v.x < minx) minx = v.x;
			if (v.x > maxx) maxx = v.x;
			if (v.y < miny) miny = v.y;
			if (v.y > maxy) maxy = v.y;
			if (v.z < minz) minz = v.z;
			if (v.z > maxz) maxz = v.z;
		}

		// Adjust frustum size by longest diagonal - fix rotation swim
		var diag0 = Vec4.distance(corners[0], corners[7]);
		var offx = (diag0 - (maxx - minx)) * 0.5;
		var offy = (diag0 - (maxy - miny)) * 0.5;
		minx -= offx;
		maxx += offx;
		miny -= offy;
		maxy += offy;

		// Snap to texel coords - fix translation swim
		var smsize = data.raw.shadowmap_size;
		#if arm_csm // Cascades
		smsize = Std.int(smsize / 4);
		#end
		var worldPerTexelX = (maxx - minx) / smsize;
		var worldPerTexelY = (maxy - miny) / smsize;
		var worldPerTexelZ = (maxz - minz) / smsize;
		minx = Math.floor(minx / worldPerTexelX) * worldPerTexelX;
		miny = Math.floor(miny / worldPerTexelY) * worldPerTexelY;
		minz = Math.floor(minz / worldPerTexelZ) * worldPerTexelZ;
		maxx = Math.floor(maxx / worldPerTexelX) * worldPerTexelX;
		maxy = Math.floor(maxy / worldPerTexelY) * worldPerTexelY;
		maxz = Math.floor(maxz / worldPerTexelZ) * worldPerTexelZ;

		var hx = ((maxx - minx) / 2) * cascadeBounds;
		var hy = ((maxy - miny) / 2) * cascadeBounds;
		var hz = ((maxz - minz) / 2) * cascadeBounds;
		V._30 = -(minx + hx);
		V._31 = -(miny + hy);
		V._32 = -(minz + hz);

		// -hz * 4 - include shadow casters out of view frustum
		m = Mat4.ortho(-hx, hx, -hy, hy, -hz * 4, hz);
		P.setFrom(m);

		updateViewFrustum(camera);

		#if arm_csm
		if (cascadeVP == null) {
			cascadeVP = [];
			for (i in 0...cascadeCount) {
				cascadeVP.push(Mat4.identity());
			}
		}
		cascadeVP[cascade].setFrom(VP);
		#end
	}

	function updateViewFrustum(camera:CameraObject) {
		VP.multmats(P, V);

		// Frustum culling enabled
		if (camera.data.raw.frustum_culling) {
			if (frustumPlanes == null) {
				frustumPlanes = [];
				for (i in 0...6) frustumPlanes.push(new FrustumPlane());
			}
			CameraObject.buildViewFrustum(VP, frustumPlanes);
		}
	}

	static var p1 = new Vec4();
	static var p2 = new Vec4();
	static var p3 = new Vec4();
	public function setCubeFace(face:Int, camera:CameraObject) {
		// Set matrix to match cubemap face
		p1.set(transform.worldx(), transform.worldy(), transform.worldz());
		p2.setFrom(p1);

		switch (face) {
		case 0: // x+
			p2.addf(1.0, 0.0, 0.0);
			p3.set(0.0, -1.0, 0.0);
		case 1: // x-
			p2.addf(-1.0, 0.0, 0.0);
			p3.set(0.0, -1.0, 0.0);
		case 2: // y+
			p2.addf(0.0, 1.0, 0.0);
			p3.set(0.0, 0.0, 1.0);
		case 3: // y-
			p2.addf(0.0, -1.0, 0.0);
			p3.set(0.0, 0.0, -1.0);
		case 4: // z+
			p2.addf(0.0, 0.0, 1.0);
			p3.set(0.0, -1.0, 0.0);
		case 5: // z-
			p2.addf(0.0, 0.0, -1.0);
			p3.set(0.0, -1.0, 0.0);
		}

		V.setLookAt(p1, p2, p3);
		updateViewFrustum(camera);
	}

	#if arm_csm
	var bias = Mat4.identity();
	public function getCascadeData():kha.arrays.Float32Array {
		// Cascade mats + split distances
		if (cascadeData == null) {
			cascadeData = new kha.arrays.Float32Array(cascadeCount * 16 + 4);
		}
		if (cascadeVP == null) return cascadeData;

		// 4 cascade mats + split distances
		for (i in 0...cascadeCount) {
			m.setFrom(cascadeVP[i]);
			bias.setFrom(Uniforms.biasMat);
			bias._00 /= cascadeCount; // Atlas offset
			bias._30 /= cascadeCount;
			bias._30 += i * (1 / cascadeCount);
			m.multmat2(bias);
			cascadeData[i * 16] = m._00;
			cascadeData[i * 16 + 1] = m._01;
			cascadeData[i * 16 + 2] = m._02;
			cascadeData[i * 16 + 3] = m._03;
			cascadeData[i * 16 + 4] = m._10;
			cascadeData[i * 16 + 5] = m._11;
			cascadeData[i * 16 + 6] = m._12;
			cascadeData[i * 16 + 7] = m._13;
			cascadeData[i * 16 + 8] = m._20;
			cascadeData[i * 16 + 9] = m._21;
			cascadeData[i * 16 + 10] = m._22;
			cascadeData[i * 16 + 11] = m._23;
			cascadeData[i * 16 + 12] = m._30;
			cascadeData[i * 16 + 13] = m._31;
			cascadeData[i * 16 + 14] = m._32;
			cascadeData[i * 16 + 15] = m._33;
		}
		cascadeData[cascadeCount * 16 + 0] = cascadeSplit[0];
		cascadeData[cascadeCount * 16 + 1] = cascadeSplit[1];
		cascadeData[cascadeCount * 16 + 2] = cascadeSplit[2];
		cascadeData[cascadeCount * 16 + 3] = cascadeSplit[3];
		return cascadeData;
	}
	#end

	public inline function right():Vec4 { return new Vec4(V._00, V._10, V._20); }
	public inline function up():Vec4 { return new Vec4(V._01, V._11, V._21); }
	public inline function look():Vec4 { return new Vec4(V._02, V._12, V._22); }

	public override function toString():String { return "Lamp Object " + name; }
}
