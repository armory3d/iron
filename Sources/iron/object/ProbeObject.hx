package iron.object;

import kha.graphics4.Graphics;
import kha.graphics4.TextureFormat;
import kha.graphics4.DepthStencilFormat;
import iron.data.ProbeData;
import iron.data.CameraData;
import iron.data.SceneFormat;
import iron.Scene;

class ProbeObject extends Object {

#if rp_probes

	public var data:ProbeData;
	public var renderTarget:kha.Image = null;
	public var camera:CameraObject = null;

	public function new(data:ProbeData) {
		super();
		this.data = data;
		Scene.active.probes.push(this);

		if (data.raw.type == "planar") {
			var raw:TCameraData = { name: data.raw.name, near_plane: 0.1, far_plane: 100.0, fov: 1.0 };
			new CameraData(raw, function(cdata:CameraData) {
				camera = new CameraObject(cdata);
				camera.renderTarget = kha.Image.createRenderTarget(
					1024, 1024,
					TextureFormat.RGBA32,
					DepthStencilFormat.NoDepthAndStencil);
				camera.name = raw.name;
				camera.transform = transform;
				Scene.active.root.addChild(camera);
				// Show target in debug console
				#if arm_debug
				iron.App.notifyOnInit(function() {
					var rt = new iron.RenderPath.RenderTarget(new iron.RenderPath.RenderTargetRaw());
					rt.raw.name = raw.name;
					rt.image = camera.renderTarget;
					iron.RenderPath.active.renderTargets.set(raw.name, rt);
				});
				#end
			});
		}
	}

	public override function remove() {
		if (Scene.active != null) Scene.active.probes.remove(this);
		super.remove();
	}

	var init = true;
	public function render(g:Graphics) {
		if (camera == null) return;

		if (data.raw.type == "planar") {

			// Invert look
			if (init) {
				init = false;
				transform.rot.fromAxisAngle(transform.right(), Math.PI);
				transform.buildMatrix();
			}

			Scene.active.camera = camera;
			camera.renderFrame(g);
		}
	}

#end
}
