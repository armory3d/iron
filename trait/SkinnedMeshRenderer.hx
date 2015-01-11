package fox.trait;

import kha.graphics4.TextureFormat;
import kha.graphics4.Usage;
import fox.sys.mesh.SkinnedMesh;
import fox.math.Mat4;

class SkinnedMeshRenderer extends MeshRenderer {

	public var joints:Array<Transform> = [];

	var buffer:Array<Float> = [];
	var sampler:kha.Image;

	public var projectionMatrix:Mat4; // Camera copy

	public function new(mesh:SkinnedMesh) {
		super(mesh);

		projectionMatrix = new Mat4();

		for (i in 0...2048 * 4) {
			buffer.push(0);
		}

		sampler = kha.Image.create(1, 2048 * 4, TextureFormat.RGBA32, Usage.DynamicUsage);
	}

	public override function initConstants() {
		super.initConstants();

		setMat4(projectionMatrix);
	}

	override function render(g:kha.graphics4.Graphics) {

		var skm:SkinnedMesh = cast mesh;
		var k:Int = 0;
		var jm:kha.math.Matrix4;
		var bm:kha.math.Matrix4;		
		
		for (i in 0...joints.length) {

			var m = joints[i].matrix;
			jm = kha.math.Matrix4.identity();
			jm.matrix = m.getFloats();

			bm = skm.binds[i];

			for (j in 0...12) {
				buffer[k] = jm.matrix[j];
				buffer[k + 4096] = bm.matrix[j];
				k++;
			}
		}
		
		var bytes = sampler.lock();
		for (i in 0...Std.int(bytes.length / 4)) {

			var f = buffer[i];
		    var b3 = Math.floor(f / 256.0 / 256.0);
		    var b2 = Math.floor((f - b3 * 256.0 * 256.0) / 256.0);
		    var b1 = Math.floor(f - b3 * 256.0 * 256.0 - b2 * 256.0);

			bytes.set(i * 4 + 0, b1);
			bytes.set(i * 4 + 1, b2);
			bytes.set(i * 4 + 2, b3);
			bytes.set(i * 4 + 3, 0);
		}
		sampler.unlock();

		g.setTexture(mesh.material.shader.textures[2], sampler);

		projectionMatrix.load(scene.camera.P.getFloats());
		
		super.render(g);
	}
}
