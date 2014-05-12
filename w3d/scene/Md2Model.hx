package wings.w3d.scene;

import kha.Sys;
import kha.Painter;

import wings.math.Vec3;
import wings.w3d.mesh.Mesh;
import wings.w3d.mesh.Md2Geometry;

class Md2Animation {

	public var startFrame:Int;
	public var endFrame:Int;

	public function new(startFrame:Int, endFrame:Int) {
		this.startFrame = startFrame;
		this.endFrame = endFrame;
	}
}

class Md2Model extends Model {

	public var interp:Vec3;

	var animTime:Int = 0;
	var curFrame = 0;
	var nextFrame = 1;

	var animations:Array<Md2Animation>;
	var currentAnim:Int = 0;

	public function new(mesh:Mesh, parent:Object = null) {
		super(mesh, parent);
		skip = true;

		interp = new Vec3();

		animations = [];
	}

	public function addAnimation(anim:Md2Animation) {
		animations.push(anim);
	}

	public function setAnimation(pos:Int) {
		currentAnim = pos;
	}

	public override function render(painter:Painter) {
		super.render(painter);

		animate();
		
		Sys.graphics.setVertexBuffer(cast(mesh.geometry, Md2Geometry).vertexBuffers[curFrame]);
		Sys.graphics.setIndexBuffer(mesh.geometry.indexBuffer);
		Sys.graphics.setProgram(mesh.material.shader.program);
		
		Sys.graphics.setTexture(mesh.material.shader.textures[0], textures[0]);
		
		setConstants();

		Sys.graphics.drawIndexedVertices();
	}

	function animate() {

		var animFPS = 100;

        animTime += wings.wxd.Time.delta;
        if (animTime >= animFPS) {

            curFrame = (curFrame + 1);
            if (curFrame >= cast(mesh.geometry, Md2Geometry).md2.header.numFrames) curFrame = 0;//animations[currentAnim].startFrame;
            //else if (curFrame > animations[currentAnim].endFrame) curFrame = animations[currentAnim].startFrame;
            
            nextFrame = (nextFrame + 1);
            if (nextFrame >= cast(mesh.geometry, Md2Geometry).md2.header.numFrames) nextFrame = 0;//animations[currentAnim].startFrame;
            //else if (nextFrame > animations[currentAnim].endFrame) nextFrame = animations[currentAnim].startFrame;
            
            animTime -= animFPS;
        }

        var t:Float = animTime / animFPS;
        if (t < 0) t = 0.0;
        if (t > 1) t = 1.0;

        interp.x = t;
    }
}
