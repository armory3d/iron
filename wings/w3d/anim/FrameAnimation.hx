package wings.w3d.anim;

// Adapted from H3D Engine
// https://github.com/ncannasse/h3d

import wings.w3d.anim.Animation;

class FrameObject extends AnimatedObject {
	public var frames : haxe.ds.Vector<wings.math.Mat4>;
	public var alphas : haxe.ds.Vector<Float>;
	public var uvs : haxe.ds.Vector<Float>;
	
	override function clone() : AnimatedObject {
		var o = new FrameObject(objectName);
		o.frames = frames;
		o.alphas = alphas;
		o.uvs = uvs;
		return o;
	}
}
	
class FrameAnimation extends Animation {

	var syncFrame : Int;

	public function new(name,frame,sampling) {
		super(name,frame,sampling);
		syncFrame = -1;
	}
	
	public function addCurve( objName, frames ) {
		var f = new FrameObject(objName);
		f.frames = frames;
		objects.push(f);
	}
	
	public function addAlphaCurve( objName, alphas ) {
		var f = new FrameObject(objName);
		f.alphas = alphas;
		objects.push(f);
	}

	public function addUVCurve( objName, uvs ) {
		var f = new FrameObject(objName);
		f.uvs = uvs;
		objects.push(f);
	}
	
	inline function getFrames() : Array<FrameObject> {
		return cast objects;
	}
	
	override function initInstance() {
		super.initInstance();
		//for( a in getFrames() )
			//if( a.alphas != null && (a.targetObject == null || !a.targetObject.isMesh()) )
			//	throw a.objectName + " should be a mesh";
	}
	
	override function clone(?a:Animation) {
		if( a == null )
			a = new FrameAnimation(name, frameCount, sampling);
		super.clone(a);
		return a;
	}
	
	@:access(wings.w3d.scene.Skin)
	override function sync( decompose = false ) {
		if( decompose ) throw "Decompose not supported on Frame Animation";
		var frame = Std.int(frame);
		if( frame < 0 ) frame = 0 else if( frame >= frameCount ) frame = frameCount - 1;
		if( frame == syncFrame )
			return;
		syncFrame = frame;
		for( o in getFrames() ) {
			if( o.alphas != null ) {
				/*var mat = o.targetObject.toMesh().material;
				if( mat.colorMul == null ) {
					mat.colorMul = new wings.w3d.fbx.Vector(1, 1, 1, 1);
					if( mat.blendDst == Zero )
						mat.blend(SrcAlpha, OneMinusSrcAlpha);
				}
				mat.colorMul.w = o.alphas[frame];*/
			} else if( o.targetSkin != null ) {
				o.targetSkin.currentRelPose[o.targetJoint] = o.frames[frame];
				o.targetSkin.jointsUpdated = true;
			} else
				o.targetObject.defaultTransform = o.frames[frame];
		}
	}
	
}