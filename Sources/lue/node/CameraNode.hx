package lue.node;

import kha.Color;
import kha.graphics4.Graphics;
import kha.graphics4.VertexBuffer;
import kha.graphics4.IndexBuffer;
import kha.graphics4.Usage;
import kha.graphics4.CompareMode;
import kha.graphics4.CullMode;
import lue.math.Mat4;
import lue.math.Vec3;
import lue.math.Quat;
import lue.math.Plane;
import lue.resource.Resource;
import lue.resource.CameraResource;
import lue.resource.ShaderResource;
import lue.resource.MaterialResource;

class CameraNode extends Node {

	public var resource:CameraResource;
	var clearColor:Color;

	public var P:Mat4; // Matrices
	public var V:Mat4;
	public var VP:Mat4;

	var frustumPlanes:Array<Plane> = null;

	var frameRenderTarget:Graphics;
	var currentRenderTarget:Graphics;
	var bindParams:Array<String>;

	static var screenAlignedVB:VertexBuffer = null;
	static var screenAlignedIB:IndexBuffer = null;

	var stageCommands:Array<Array<String>->Node->LightNode->Void>;
	var stageParams:Array<Array<String>>;

	var cachedQuadContexts:Map<String, CachedQuadContext> = new Map();

	public function new(resource:CameraResource) {
		super();

		this.resource = resource;
		cacheStageCommands();

		clearColor = Color.fromFloats(resource.resource.clear_color[0], resource.resource.clear_color[1], resource.resource.clear_color[2], resource.resource.clear_color[3]);

		if (resource.resource.type == "perspective") {
			P = Mat4.perspective(45, App.w / App.h, resource.resource.near_plane, resource.resource.far_plane);
		}
		else if (resource.resource.type == "orthographic") {
			P = Mat4.orthogonal(-10, 10, -6, 6, -resource.resource.far_plane, resource.resource.far_plane, 2);
		}
		V = Mat4.identity();
		VP = Mat4.identity();

		if (resource.resource.frustum_culling) {
			frustumPlanes = [];
			for (i in 0...6) {
				frustumPlanes.push(new Plane());
			}
		}

		Node.cameras.push(this);

		if (screenAlignedVB == null) createScreenAlignedData();
	}

	static function createScreenAlignedData() {
		var data = [-1.0, -1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0];
		var indices = [0, 1, 2, 0, 2, 3];

		// TODO: Mandatory vertex data names and sizes
		// pos=2
		screenAlignedVB = new VertexBuffer(Std.int(data.length / ShaderResource.getScreenAlignedQuadStructureLength()),
										   ShaderResource.createScreenAlignedQuadStructure(), Usage.StaticUsage);
		var vertices = screenAlignedVB.lock();
		
		for (i in 0...vertices.length) {
			vertices.set(i, data[i]);
		}
		screenAlignedVB.unlock();

		screenAlignedIB = new IndexBuffer(indices.length, Usage.StaticUsage);
		var id = screenAlignedIB.lock();

		for (i in 0...id.length) {
			id[i] = indices[i];
		}
		screenAlignedIB.unlock();
	}

	public function renderFrame(g:Graphics, root:Node, lights:Array<LightNode>) {
		updateMatrix(); // TODO: only when dirty

		frameRenderTarget = g;
		currentRenderTarget = g;

		var light = lights[0];
		if (light.V == null) { light.buildMatrices(); }

		for (i in 0...stageCommands.length) {
			stageCommands[i](stageParams[i], root, light);
		}
	}

	function setTarget(params:Array<String>, root:Node, light:LightNode) {
    	var target = params[0];
    	if (target == "") {
    		currentRenderTarget = frameRenderTarget;
    		begin(currentRenderTarget);
    	}
		else {
			var rt = resource.pipeline.renderTargets.get(target);
			currentRenderTarget = rt.image.g4;
			begin(currentRenderTarget, rt.additionalImages);
		}
		bindParams = null;
    }

    function clearTarget(params:Array<String>, root:Node, light:LightNode) {
    	currentRenderTarget.clear(clearColor, 1, null);
    }

    function drawGeometry(params:Array<String>, root:Node, light:LightNode) {
		var context = params[0];
		var g = currentRenderTarget;
		root.render(g, context, this, light, bindParams);
		end(g);
    }

    function bindTarget(params:Array<String>, root:Node, light:LightNode) {
    	bindParams = params;
    }

    function drawQuad(params:Array<String>, root:Node, light:LightNode) {
    	var handle = params[0] + params[1] + params[2];
    	var cc:CachedQuadContext = cachedQuadContexts.get(handle);
		if (cc == null) {
			var res = Resource.getMaterial(params[0], params[1]);
			cc = new CachedQuadContext();
			cc.materialContext = res.getContext(params[2]);
			cc.context = res.shader.getContext(params[2]);
			cachedQuadContexts.set(handle, cc);
		}

		var materialContext = cc.materialContext;
		var context = cc.context;
		
		var g = currentRenderTarget;		
		g.setPipeline(context.pipeState);

		ModelNode.setConstants(g, context, null, this, light, bindParams);
		ModelNode.setMaterialConstants(g, context, materialContext);

		g.setVertexBuffer(screenAlignedVB);
		g.setIndexBuffer(screenAlignedIB);
		g.drawIndexedVertices();
		
		end(g);
    }

	inline function begin(g:Graphics, additionalRenderTargets:Array<kha.Canvas> = null) {
		#if !python
		g.begin(additionalRenderTargets);
		#end
	}

	inline function end(g:Graphics) {
		#if !python
		g.end();
		#end
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

	    var trans = Mat4.identity();
	    trans.translate(-transform.absx(), -transform.absy(), -transform.absz());
	    V.multiply(trans, V);

		transform.buildMatrix();

		if (resource.resource.frustum_culling) {
			buildViewFrustum();
		}
	}

	function buildViewFrustum() {
		VP.setIdentity();
    	VP.mult(V);
    	VP.mult(P);

	    // Left plane
	    frustumPlanes[0].setComponents(
	    	VP._03 + VP._00,
	    	VP._13 + VP._10,
	    	VP._23 + VP._20,
	    	VP._33 + VP._30
	    );
	 
	    // Right plane
	    frustumPlanes[1].setComponents(
	    	VP._03 - VP._00,
	    	VP._13 - VP._10,
	    	VP._23 - VP._20,
	    	VP._33 - VP._30
	    );
	 
	    // Top plane
	    frustumPlanes[2].setComponents(
	    	VP._03 - VP._01,
	    	VP._13 - VP._11,
	    	VP._23 - VP._21,
	    	VP._33 - VP._31
	    );
	 
	    // Bottom plane
	    frustumPlanes[3].setComponents(
	    	VP._03 + VP._01,
	    	VP._13 + VP._11,
	    	VP._23 + VP._21,
	    	VP._33 + VP._31
	    );
	 
	    // Near plane
	    frustumPlanes[4].setComponents(
	    	VP._02,
	    	VP._12,
	    	VP._22,
	    	VP._32
	    );
	 
	    // Far plane
	    frustumPlanes[5].setComponents(
	    	VP._03 - VP._02,
	    	VP._13 - VP._12,
	    	VP._23 - VP._22,
	    	VP._33 - VP._32
	    );
	 
	    // Normalize planes
	    for (plane in frustumPlanes) {
	    	plane.normalize();
	    }
	}

	static var sphere = new lue.math.Sphere();
	public function sphereInFrustum(t:Transform, radius:Float):Bool {
		for (plane in frustumPlanes) {	
			sphere.set(t.pos, radius);
			// Outside the frustum
			// TODO: *3 to be safe
			if (plane.distanceToSphere(sphere) + radius * 3 < 0) {
			//if (plane.distanceToSphere(sphere) + radius * 2 < 0) {
				return false;
			}
	    }
	    return true;
	}

	public function rotate(axis:Vec3, f:Float) {
		var q = new Quat();
		q.setFromAxisAngle(axis, f);
		transform.rot.multiply(transform.rot, q);

		updateMatrix();
	}

	public function move(axis:Vec3, f:Float) {
        axis.mult(-f, axis);

		transform.pos.vadd(axis, transform.pos);
		transform.dirty = true;
		transform.update();
		updateMatrix();
	}

	public function right():Vec3 {
        return new Vec3(V._00, V._10, V._20);
    }

    public function look():Vec3 {
        return new Vec3(V._02, V._12, V._22);
    }

    public function up():Vec3 {
        return new Vec3(V._01, V._11, V._21);
    }

    function cacheStageCommands() {
    	stageCommands = [];
    	stageParams = [];
    	for (stage in resource.pipeline.resource.stages) {
    		
    		stageParams.push(stage.params);
			
			if (stage.command == "set_target") {
				stageCommands.push(setTarget);
			}
			else if (stage.command == "clear_target") {
				stageCommands.push(clearTarget);
			}
			else if (stage.command == "draw_geometry") {
				stageCommands.push(drawGeometry);
			}
			else if (stage.command == "bind_target") {
				stageCommands.push(bindTarget);
			}
			else if (stage.command == "draw_quad") {
				stageCommands.push(drawQuad);
			}
		}
    }
}

class CachedQuadContext {
	public var materialContext:MaterialContext;
	public var context:ShaderContext;
	public function new() {}
}
