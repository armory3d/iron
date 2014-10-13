package wings.trait;

import wings.sys.mesh.SkinnedMesh;
import wings.math.Mat4;

class SkinnedMeshRenderer extends MeshRenderer {

	public var joints:Array<Transform> = [];

	var buffer:Array<Float> = [];

	var sampler0:kha.Image;
	var sampler:kha.Image;

	public var viewMatrix:Mat4;
	public var projectionMatrix:Mat4;

	public function new(mesh:SkinnedMesh) {
		super(mesh);

		viewMatrix = new Mat4();
		projectionMatrix = new Mat4();

		for (i in 0...8192) {
			buffer.push(0);
		}

		sampler0 = kha.Image.create(128, 128, kha.graphics4.TextureFormat.RGBA32, kha.graphics4.Usage.StaticUsage);
		sampler = kha.Image.create(1, 2048 * 4, kha.graphics4.TextureFormat.RGBA32, kha.graphics4.Usage.DynamicUsage);

		var bytes = sampler0.lock();

		for (i in 0...Std.int(bytes.length / 4)) {
			bytes.set(i * 4, 255);
			bytes.set(i * 4 + 1, 0);
			bytes.set(i * 4 + 2, 0);
			bytes.set(i * 4 + 3, 255);
		}
		sampler0.unlock();
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
			var b1:Int, b2:Int, b3:Int;
		    b3 = Math.floor(f / 256.0 / 256.0);
		    b2 = Math.floor((f - b3 * 256.0 * 256.0) / 256.0);
		    b1 = Math.floor(f - b3 * 256.0 * 256.0 - b2 * 256.0);

			bytes.set(i * 4 + 0, b1);
			bytes.set(i * 4 + 1, b2);
			bytes.set(i * 4 + 2, b3);
			bytes.set(i * 4 + 3, 0);
		}
		sampler.unlock();

		g.setTexture(mesh.material.shader.textures[1], sampler);
		g.setTexture(mesh.material.shader.textures[0], sampler0);

		viewMatrix.load(scene.camera.viewMatrix.getFloats());
		projectionMatrix.load(scene.camera.projectionMatrix.getFloats());
		
		super.render(g);
	}
}
