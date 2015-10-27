package lue.node;

import kha.Color;
import kha.graphics4.Graphics;
import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import lue.math.Mat4;
import lue.math.Vec3;
import lue.math.Quat;
import lue.math.Plane;
import lue.resource.Resource;
import lue.resource.CameraResource;
import lue.resource.ShaderResource;

class CameraNode extends Node {

	public var resource:CameraResource;
	var clearColor:Color;

	public var P:Mat4; // Matrices
	public var V:Mat4;
	public var VP:Mat4;

	public var up:Vec3;
	public var look:Vec3;
	public var right:Vec3;

	var frustumPlanes:Array<Plane> = [];

	var frameRenderTarget:Graphics;
	var currentRenderTarget:Graphics;
	var bindParams:Array<String>;

	static var screenAlignedVB:VertexBuffer = null;
	static var screenAlignedIB:IndexBuffer = null;

	public function new(resource:CameraResource) {
		super();

		this.resource = resource;

		clearColor = Color.fromFloats(resource.resource.clear_color[0], resource.resource.clear_color[1], resource.resource.clear_color[2], resource.resource.clear_color[3]);

		P = Mat4.perspective(45, App.w / App.h, resource.resource.near_plane, resource.resource.far_plane);
		V = new Mat4();

		up = new Vec3(0, 0, 1);
		look = new Vec3(0, 1, 0);
		right = new Vec3(1, 0, 0);

		VP = new Mat4();

		for (i in 0...6) {
			frustumPlanes.push(new Plane());
		}

		Node.cameras.push(this);

		if (screenAlignedVB == null) createScreenAlignedData();
	}

	static function createScreenAlignedData() {
		var data = [-1.0, -1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0];
		var indices = [0, 1, 2, 0, 2, 3];

		screenAlignedVB = new VertexBuffer(Std.int(data.length / ShaderResource.getScreenAlignedQuadStructureLength()),
										ShaderResource.createScreenAlignedQuadStructure(), kha.graphics4.Usage.StaticUsage);
		var vertices = screenAlignedVB.lock();
		
		for (i in 0...vertices.length) {
			vertices.set(i, data[i]);
		}
		screenAlignedVB.unlock();

		screenAlignedIB = new IndexBuffer(indices.length, kha.graphics4.Usage.StaticUsage);
		var id = screenAlignedIB.lock();

		for (i in 0...id.length) {
			id[i] = indices[i];
		}
		screenAlignedIB.unlock();
	}

	public function renderFrame(g:Graphics, root:Node, light:LightNode) {
		updateMatrix();

		frameRenderTarget = g;
		currentRenderTarget = g;

		if (light.V == null) { light.buildMatrices(); }

		for (stage in resource.pipeline.resource.stages) {
			if (stage.command == "set_target") {
				setTarget(stage.params[0]);
				begin(currentRenderTarget);
			}
			else if (stage.command == "clear_target") {
				clearTarget(currentRenderTarget);
			}
			else if (stage.command == "draw_geometry") {
				drawGeometry(currentRenderTarget, stage.params[0], root, light, bindParams);
				end(currentRenderTarget);
			}
			else if (stage.command == "bind_target") {
				bindTarget(currentRenderTarget, stage.params);
			}
			else if (stage.command == "draw_quad") {
				drawQuad(currentRenderTarget, stage.params, bindParams);
				end(currentRenderTarget);
			}
		}
	}

	function begin(g:Graphics) {
		g.begin();
	}

	function end(g:Graphics) {
		g.end();
	}

	function setTarget(target:String) {
		if (target == "") currentRenderTarget = frameRenderTarget;
		else currentRenderTarget = resource.pipeline.renderTargets.get(target).g4;
		bindParams = null;
	}

	function clearTarget(g:Graphics) {
		g.clear(clearColor, 1, null);
	}

	function drawGeometry(g:Graphics, context:String, root:Node, light:LightNode, bindParams:Array<String>) {
		g.setDepthMode(true, kha.graphics4.CompareMode.Less);
		g.setCullMode(kha.graphics4.CullMode.CounterClockwise);
		root.render(g, context, this, light, bindParams);
	}

	function bindTarget(g:Graphics, params:Array<String>) {
		bindParams = params;
	}

	function drawQuad(g:Graphics, params:Array<String>, bindParams:Array<String>) {
		var context = Resource.getShader(params[0], params[1]).getContext(params[2]);
		
		g.setProgram(context.program);
		if (bindParams != null) {
			for (i in 0...Std.int(bindParams.length / 2)) {
				var pos = i * 2 + 1;
				for (j in 0...context.resource.texture_units.length) {
					if (bindParams[pos] == context.resource.texture_units[j].id) {
						g.setTexture(context.textureUnits[j], resource.pipeline.renderTargets.get(bindParams[pos - 1]));
					}
				}
			}
		}
		g.setVertexBuffer(screenAlignedVB);
		g.setIndexBuffer(screenAlignedIB);
		g.drawIndexedVertices();
	}

	public function updateMatrix() {
		var q = new Quat(); // Camera parent
		if (parent != null) {
			var rot = parent.transform.rot;
			q.set(rot.x, rot.y, rot.z, rot.w);
			q = q.inverse(q);
		}

		q.multiply(transform.rot, q); // Camera transform
	    V = q.toMatrix();

	    var trans = new Mat4();
	    trans.translate(-transform.absx(), -transform.absy(), -transform.absz());
	    V.multiply(trans, V);

	    buildViewFrustum();

	    // TODO: do only once per frame
		transform.buildMatrix();
	}

	function buildViewFrustum() {

		VP.identity();
    	VP.mult(V);
    	VP.mult(P);

	    // Left plane
	    frustumPlanes[0].setComponents(
	    	VP._14 + VP._11,
	    	VP._24 + VP._21,
	    	VP._34 + VP._31,
	    	VP._44 + VP._41
	    );
	 
	    // Right plane
	    frustumPlanes[1].setComponents(
	    	VP._14 - VP._11,
	    	VP._24 - VP._21,
	    	VP._34 - VP._31,
	    	VP._44 - VP._41
	    );
	 
	    // Top plane
	    frustumPlanes[2].setComponents(
	    	VP._14 - VP._12,
	    	VP._24 - VP._22,
	    	VP._34 - VP._32,
	    	VP._44 - VP._42
	    );
	 
	    // Bottom plane
	    frustumPlanes[3].setComponents(
	    	VP._14 + VP._12,
	    	VP._24 + VP._22,
	    	VP._34 + VP._32,
	    	VP._44 + VP._42
	    );
	 
	    // Near plane
	    frustumPlanes[4].setComponents(
	    	VP._13,
	    	VP._23,
	    	VP._33,
	    	VP._43
	    );
	 
	    // Far plane
	    frustumPlanes[5].setComponents(
	    	VP._14 - VP._13,
	    	VP._24 - VP._23,
	    	VP._34 - VP._33,
	    	VP._44 - VP._43
	    );
	 
	    // Normalize planes
	    for (i in 0...6) {
	    	frustumPlanes[i].normalize();
	    }
	}

	public function sphereInFrustum(t:Transform, radius:Float):Bool {
		
		for (i in 0...6) {
			
			var vpos = new lue.math.Vec3(t.pos.x, t.pos.y, t.pos.z);
			//var vpos = new lue.math.Vec3(t.absx, t.absy, t.absz);
			//var pos = new lue.math.Vec3(t.absx, t.absy, t.absz);

			//var fn = frustumPlanes[i].normal;
			//var vn = new lue.math.Vec3(fn.x, fn.y, fn.z);

			//var dist = frustumPlanes[i].distanceToPoint(vpos);

			// Outside the frustum, reject it
			var sphere = new lue.math.Sphere(vpos, radius);
			if (frustumPlanes[i].distanceToSphere(sphere) + radius * 2 < 0) {
			//if (lue.math.Math.planeDotCoord(vn, pos, dist) + radius < 0) {
				return false;
			}
	    }

	    return true;
	}

	public function getLook():Vec3 {
	    var mRot:Mat4 = transform.rot.toMatrix();

	    return new Vec3(mRot._13, mRot._23, mRot._33);
	    //return new Vec3(mRot.matrix[2], mRot.matrix[6], mRot.matrix[10]);
	}

	public function getRight():Vec3 {
	    var mRot:Mat4 = transform.rot.toMatrix();

	    return new Vec3(mRot._11, mRot._21, mRot._31);
	    //return new Vec3(mRot.matrix[0], mRot.matrix[4], mRot.matrix[8]);
	}

	public function getUp():Vec3 {
	    var mRot:Mat4 = transform.rot.toMatrix();

	    return new Vec3(mRot._12, mRot._22, mRot._32);
	    //return new Vec3(mRot.matrix[1], mRot.matrix[5], mRot.matrix[9]);
	}

	public function pitch(f:Float) {
		var q = new Quat();
		q.setFromAxisAngle(right, -f);
		transform.rot.multiply(q, transform.rot);

		updateMatrix();
	}

	public function yaw(f:Float) {
		var q = new Quat();
		q.setFromAxisAngle(up, -f);
		transform.rot.multiply(q, transform.rot);

		updateMatrix();
	}

	public function roll(f:Float) {
		var q = new Quat();
		q.setFromAxisAngle(look, -f);
		transform.rot.multiply(q, transform.rot);

		updateMatrix();
	}

	public function moveForward(f:Float):Vec3 {
		var v3Move = getLook();
        v3Move.mult(-f, v3Move);
        moveCamera(v3Move);
        return v3Move;
	}

	public function moveRight(f:Float):Vec3 {
		var v3Move = getRight();
        v3Move.mult(-f, v3Move);
        moveCamera(v3Move);
        return v3Move;
	}

	public function moveUp(f:Float):Vec3 {
		var v3Move = getUp();
        v3Move.mult(-f, v3Move);
        moveCamera(v3Move);
        return v3Move;
	}

	public function moveCamera(vec:Vec3) {
		transform.pos.vadd(vec, transform.pos);
		transform.dirty = true;
		transform.update();
		updateMatrix();
	}

	public function viewMatrixForward():Vec3 {
        return new Vec3(-V._13, -V._23, -V._33);
    }

    public function viewMatrixBackward():Vec3 {
        return new Vec3(V._13, V._23, V._33);
    }
}
