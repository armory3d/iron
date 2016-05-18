package lue.node;

import kha.graphics4.Graphics;
import lue.math.Mat4;
import lue.math.Vec4;
// import lue.resource.DecalResource;
import lue.resource.MaterialResource;
import lue.resource.ShaderResource;
import lue.node.ModelNode;
// import lue.resource.SceneFormat;

class DecalNode extends Node {

	// public var resource:DecalResource;
	public var material:MaterialResource;
	var cachedContext:CachedModelContext = null;

	public function new(material:MaterialResource) {
		super();
		
		// this.resource = resource;
		this.material = material;

		RootNode.decals.push(this);
	}
	
	// Called before rendering decal in render pipeline
	public function renderDecal(g:Graphics, context:String, camera:CameraNode, light:LightNode, bindParams:Array<String>) {
		
		if (cachedContext == null) {
			cachedContext = new CachedModelContext();
			// Check context skip
			if (material.resource.skip_context != null &&
				material.resource.skip_context == context) {
				cachedContext.enabled = false;
			}
			if (cachedContext.enabled) {
				cachedContext.materialContexts = [];
				for (i in 0...material.resource.contexts.length) {
					if (material.resource.contexts[i].id == context) {
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
		
		ModelNode.setConstants(g, shaderContext, this, camera, light, bindParams);			
		ModelNode.setMaterialConstants(g, shaderContext, materialContext);
	}
}
