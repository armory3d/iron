package wings.w3d.scene;

import kha.Sys;
import kha.Painter;

import wings.math.Vec3;
import wings.w3d.meshes.Mesh;
import wings.w3d.meshes.Md2Geometry;

class Md2Model extends Model {

	public var interp:Vec3;

	public function new(mesh:Mesh, parent:Object = null) {
		super(mesh, parent);
		skip = true;

		interp = new Vec3();
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


	var animTime:Int = 0;
	var curFrame = 0;
	var nextFrame = 1;
	function animate() {

		var animFPS = 100;

        animTime += wings.wxd.Time.delta;
        if (animTime >= animFPS) {

            curFrame = (curFrame + 1 >= cast(mesh.geometry, Md2Geometry).md2.header.numFrames) ? 0 : curFrame + 1;
            nextFrame = (nextFrame + 1 >= cast(mesh.geometry, Md2Geometry).md2.header.numFrames) ? 0 : nextFrame + 1;
            animTime -= animFPS;
        }

        var t:Float = animTime / animFPS;
        if (t < 0) t = 0.0;
        if (t > 1) t = 1.0;

        interp.x = t;
    }
}
