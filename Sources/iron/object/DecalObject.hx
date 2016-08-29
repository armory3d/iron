package iron.object;

import kha.graphics4.Graphics;
import iron.data.MaterialData;
import iron.object.MeshObject;
import iron.Scene;

class DecalObject extends Object {

	public var material:MaterialData;
	var cachedContext:CachedMeshContext = null;

	public function new(material:MaterialData) {
		super();
		
		this.material = material;

		Scene.active.decals.push(this);
	}

	public override function remove() {
		Scene.active.decals.remove(this);
		super.remove();
	}
	
	// Called before rendering decal in render pipeline
	public function render(g:Graphics, context:String, camera:CameraObject, lamp:LampObject, bindParams:Array<String>) {
		
		if (cachedContext == null) {
			cachedContext = new CachedMeshContext();
			// Check context skip
			if (material.raw.skip_context != null &&
				material.raw.skip_context == context) {
				cachedContext.enabled = false;
			}
			if (cachedContext.enabled) {
				cachedContext.materialContexts = [];
				for (i in 0...material.raw.contexts.length) {
					if (material.raw.contexts[i].name == context) {
						cachedContext.materialContexts.push(material.contexts[i]);
						break;
					}
				}
				cachedContext.context = material.shader.getContext(context);
			}
		}
		if (!cachedContext.enabled) return;

		var materialContext = cachedContext.materialContexts[0]; // Single material decals
		var shaderContext = cachedContext.context;
		
		g.setPipeline(shaderContext.pipeState);
		
		MeshObject.setConstants(g, shaderContext, this, camera, lamp, bindParams);			
		MeshObject.setMaterialConstants(g, shaderContext, materialContext);
	}
}
