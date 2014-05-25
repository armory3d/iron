package wings.w3d.scene;

// Adapted from H3D Engine

class Joint extends wings.w3d.Object {
	public var skin : Skin;
	public var index : Int;
	
	public function new(skin, j : wings.w3d.anim.Skin.Joint ) {
		super();
		name = j.name;
		this.skin = skin;
		// fake parent
		this.parent = skin;
		this.index = j.index;
	}
	
	@:access(wings.w3d.scene.Skin)
	override function syncPos() {
		// check if one of our parents has changed
		// we don't have a posChanged flag since the Joint
		// is not actualy part of the hierarchy
		var p = parent;
		while( p != null ) {
			//if( p.rebuildMatrix ) {
				// save the inverse absPos that was used to build the joints absPos
				if( skin.jointsAbsPosInv == null ) {
					skin.jointsAbsPosInv = new wings.math.Mat4();
					skin.jointsAbsPosInv.zero();
				}
				if( skin.jointsAbsPosInv._44 == 0 )
					skin.jointsAbsPosInv.inverse3x4(parent.modelMatrix);
				parent.syncPos();
				//lastFrame = -1;
				break;
			//}
			p = p.parent;
		}
		//if( lastFrame != skin.lastFrame ) {
		//	lastFrame = skin.lastFrame;
			modelMatrix.loadFrom(skin.currentAbsPose[index]);
			if( skin.jointsAbsPosInv != null && skin.jointsAbsPosInv._44 != 0 ) {
				modelMatrix.multiply3x4(modelMatrix, skin.jointsAbsPosInv);
				modelMatrix.multiply3x4(modelMatrix, parent.modelMatrix);
			}
		//}
	}
}

class Skin extends wings.w3d.scene.Model {
	
	var skinData : wings.w3d.anim.Skin;
	var currentRelPose : Array<wings.math.Mat4>;
	var currentAbsPose : Array<wings.math.Mat4>;
	var currentPalette : Array<wings.math.Mat4>;
	var splitPalette : Array<Array<wings.math.Mat4>>;
	var jointsUpdated : Bool;
	var jointsAbsPosInv : wings.math.Mat4;
	var paletteChanged : Bool;

	public var showJoints : Bool;
	public var syncIfHidden : Bool = true;
	
	public function new(s, mat:wings.w3d.material.Material, parent) {
		super(new wings.w3d.mesh.Mesh(null, [mat]), parent);
		if( s != null )
			setSkinData(s);
	}
	
	/*override function clone( ?o : wings.w3d.Object ) {
		var s = o == null ? new Skin(null,material.copy()) : cast o;
		super.clone(s);
		s.setSkinData(skinData);
		s.currentRelPose = currentRelPose.copy(); // copy current pose
		return s;
	}*/
	
	
	/*override function getBounds( ?b : h3d.col.Bounds ) {
		b = super.getBounds(b);
		var tmp = primitive.getBounds().clone();
		var b0 = skinData.allJoints[0];
		// not sure if that's the good joint
		if( b0 != null && b0.parent == null ) {
			var mtmp = modelMatrix.clone();
			var r = currentRelPose[b0.index];
			if( r != null )
				mtmp.multiply3x4(r, mtmp);
			else
				mtmp.multiply3x4(b0.defMat, mtmp);
			if( b0.transPos != null )
				mtmp.multiply3x4(b0.transPos, mtmp);
			tmp.transform3x4(mtmp);
		} else
			tmp.transform3x4(modelMatrix);
		b.add(tmp);
		return b;
	}*/

	override function getObjectByName( name : String ) {
		var o = super.getObjectByName(name);
		if( o != null ) return o;
		// create a fake object targeted at the bone, not persistant but matrixes are shared
		if( skinData != null ) {
			var j = skinData.namedJoints.get(name);
			if( j != null )
				return new Joint(this, j);
		}
		return null;
	}
	
	override function buildMatrix() {
		super.buildMatrix();
		// if we update our absolute position, rebuild the matrixes
		jointsUpdated = true;
	}
	
	public function setSkinData( s ) {
		skinData = s;
		jointsUpdated = true;
		mesh.geometries[0] = s.primitive;
		//for( m in materials )
		//	if( m != null )
		//		m.hasSkin = true;
		currentRelPose = [];
		currentAbsPose = [];
		currentPalette = [];
		paletteChanged = true;
		for( j in skinData.allJoints )
			currentAbsPose.push(wings.math.Mat4.I());
		for( i in 0...skinData.boundJoints.length )
			currentPalette.push(wings.math.Mat4.I());
		if( skinData.splitJoints != null ) {
			splitPalette = [];
			for( a in skinData.splitJoints )
				splitPalette.push([for( j in a ) currentPalette[j.bindIndex]]);
		} else
			splitPalette = null;
	}

	override function sync() {
		//if( !(visible || syncIfHidden) )
		//	return;
		if( jointsUpdated || rebuildMatrix ) {
			super.sync();
			for( j in skinData.allJoints ) {
				var id = j.index;
				var m = currentAbsPose[id];
				var r = currentRelPose[id];
				if( r == null ) r = j.defMat;
				if( j.parent == null )
					m.multiply3x4(r, modelMatrix);
				else
					m.multiply3x4(r, currentAbsPose[j.parent.index]);
				var bid = j.bindIndex;
				if( bid >= 0 )
					currentPalette[bid].multiply3x4(j.transPos, m);
			}
			paletteChanged = true;
			if( jointsAbsPosInv != null ) jointsAbsPosInv._44 = 0; // mark as invalid
			jointsUpdated = false;
		} else
			super.sync();
	}
	
	override function render( painter:kha.Painter ) {
		// TODO: assign skinMatrixes to corrent joints
		//super.render(painter);
		if( splitPalette == null ) {
			if( paletteChanged ) {
				paletteChanged = false;
		//		for( m in materials )
		//			if( m != null )
		//				m.skinMatrixes = currentPalette;
				skinMatrixes = currentPalette;
			}
			super.render(painter);
		} else {
			for( i in 0...splitPalette.length ) {
				//material.skinMatrixes = splitPalette[i];
				//primitive.selectMaterial(i);
				skinMatrixes = splitPalette[i];

				super.render(painter);
			}
		}

		//if( showJoints )
		//	ctx.addPass(drawJoints);
	}
	
	/*function drawJoints( ctx : RenderContext ) {
		for( j in skinData.allJoints ) {
			var m = currentAbsPose[j.index];
			var mp = j.parent == null ? modelMatrix : currentAbsPose[j.parent.index];
			ctx.engine.line(mp._41, mp._42, mp._43, m._41, m._42, m._43, j.parent == null ? 0xFF0000FF : 0xFFFFFF00);
			
			var dz = new h3d.Vector(0, 0.01, 0);
			dz.transform(m);
			ctx.engine.line(m._41, m._42, m._43, dz.x, dz.y, dz.z, 0xFF00FF00);
			
			ctx.engine.point(m._41, m._42, m._43, j.bindIndex < 0 ? 0xFF0000FF : 0xFFFF0000);
		}
	}*/
		
}
