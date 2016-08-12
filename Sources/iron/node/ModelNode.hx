package iron.node;

import kha.graphics4.Graphics;
import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.MipMapFilter;
import iron.math.Vec4;
import iron.math.Quat;
import iron.math.Mat4;
import iron.resource.ModelResource;
import iron.resource.MaterialResource;
import iron.resource.ShaderResource;
import iron.resource.SceneFormat;
import iron.resource.RenderPath;

class ModelNode extends Node {

	public var resource:ModelResource;
	public var materials:Array<MaterialResource>;

	public var particleSystem:ParticleSystem = null;

	// static var biasMat = new Mat4(
	// 	0.5, 0.0, 0.0, 0.0,
	// 	0.0, 0.5, 0.0, 0.0,
	// 	0.0, 0.0, 0.5, 0.0,
	// 	0.5, 0.5, 0.5, 1.0);
	static var helpMat = Mat4.identity();
	static var helpMat2 = Mat4.identity();
	static var helpVec = new Vec4();
	static var helpVec2 = new Vec4();
	static var helpQuat = new Quat(); // Keep at identity

	var cachedContexts:Map<String, CachedModelContext> = new Map();
	
	public var cameraDistance:Float;

#if WITH_VELOC
	var prevMatrix = Mat4.identity();
#end

	// public static var _u1:Float = 0.25;
	// public static var _u2:Float = 0.1;
	// public static var _u3:Float = 5;
	// public static var _u4:Float = 3.0;
	// public static var _u5:Float = 0.0;
	// public static var _u6:Float = 0.34;

	public function new(resource:ModelResource, materials:Array<MaterialResource>) {
		super();

		this.resource = resource;
		this.materials = materials;	
		RootNode.models.push(this);
	}

	public override function remove() {
		RootNode.models.remove(this);
		super.remove();
	}

	public override function setupAnimation(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>, speeds:Array<Float>, loops:Array<Bool>, reflects:Array<Bool>) {
		if (resource.isSkinned) {
			animation = Animation.setupBoneAnimation(resource, startTrack, names, starts, ends, speeds, loops, reflects);
		}
		else {
			super.setupAnimation(startTrack, names, starts, ends, speeds, loops, reflects);
		}
	}

	public function setupParticleSystem(sceneName:String, pref:TParticleReference) {
		particleSystem = new ParticleSystem(this, sceneName, pref);
	}

	public static function setConstants(g:Graphics, context:ShaderContext, node:Node, camera:CameraNode, light:LightNode, bindParams:Array<String>) {

		for (i in 0...context.resource.constants.length) {
			var c = context.resource.constants[i];
			setConstant(g, node, camera, light, context.constants[i], c);
		}

		if (bindParams != null) { // Bind targets
			for (i in 0...Std.int(bindParams.length / 2)) {
				var pos = i * 2; // bind params = [texture, samplerID]
				var rtID = bindParams[pos];
				
				var attachDepth = false; // Attach texture depth if '_' is prepended
				var char = rtID.charAt(0);
				if (char == "_") attachDepth = true;
				if (attachDepth) rtID = rtID.substr(1);
				
				var samplerID = bindParams[pos + 1];
				var pipe = camera.resource.pipeline;
				var rt = attachDepth ? pipe.depthToRenderTarget.get(rtID) : pipe.renderTargets.get(rtID);
				var tus = context.resource.texture_units;

				// Ping-pong
				if (rt.pong != null && !rt.pongState) rt = rt.pong;

				for (j in 0...tus.length) { // Set texture
					if (samplerID == tus[j].id) {
						// No filtering when sampling render targets
						// g.setTextureParameters(context.textureUnits[j], TextureAddressing.Clamp, TextureAddressing.Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
						if (attachDepth) g.setTextureDepth(context.textureUnits[j], rt.image);
						else g.setTexture(context.textureUnits[j], rt.image);
					}
				}
			}
		}
		
		// Texture links
		for (j in 0...context.resource.texture_units.length) {
			var tuid = context.resource.texture_units[j].id;
			var tulink = context.resource.texture_units[j].link;
			if (tulink == "_envmapRadiance") {
				g.setTexture(context.textureUnits[j], camera.world.getGlobalProbe().radiance);
				g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.LinearMipFilter);
			}
			else if (tulink == "_envmapBrdf") {
				g.setTexture(context.textureUnits[j], camera.world.brdf);
			}
			// Migrate to arm
			else if (tulink == "_smaaSearch") {
				g.setTexture(context.textureUnits[j], Reflect.field(kha.Assets.images, "smaa_search"));
			}
			else if (tulink == "_smaaArea") {
				g.setTexture(context.textureUnits[j], Reflect.field(kha.Assets.images, "smaa_area"));
			}
			else if (tulink == "_ltcMat") {
				if (iron.resource.ConstData.ltcMatTex == null) iron.resource.ConstData.initLTC();
				g.setTexture(context.textureUnits[j], iron.resource.ConstData.ltcMatTex);
			}
			else if (tulink == "_ltcMag") {
				if (iron.resource.ConstData.ltcMagTex == null) iron.resource.ConstData.initLTC();
				g.setTexture(context.textureUnits[j], iron.resource.ConstData.ltcMagTex);
			}
			//
			else if (tulink == "_noise8") {
				g.setTexture(context.textureUnits[j], Reflect.field(kha.Assets.images, "noise8"));
				g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.NoMipFilter);
			}
			else if (tulink == "_noise64") {
				g.setTexture(context.textureUnits[j], Reflect.field(kha.Assets.images, "noise64"));
				g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.NoMipFilter);
			}
			else if (tulink == "_noise256") {
				g.setTexture(context.textureUnits[j], Reflect.field(kha.Assets.images, "noise256"));
				g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.NoMipFilter);
			}
			else if (tulink == "_noise512") {
				g.setTexture(context.textureUnits[j], Reflect.field(kha.Assets.images, "noise512"));
				// g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.NoMipFilter);
			}
			// else if (tulink == "_checker") {
				// g.setTexture(context.textureUnits[j], kha.Assets.images.checker);
				// g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
			// }
		}
	}
	static function setConstant(g:Graphics, node:Node, camera:CameraNode, light:LightNode,
								location:ConstantLocation, c:TShaderConstant) {
		if (c.link == null) return;

		if (c.type == "mat4") {
			var m:Mat4 = null;
			if (c.link == "_modelMatrix") {
				m = node.transform.matrix;
			}
			else if (c.link == "_inverseModelMatrix") {
				helpMat.inverse2(node.transform.matrix);
				m = helpMat;
			}
			else if (c.link == "_normalMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(node.transform.matrix);
				// Non uniform anisotropic scaling, calculate normal matrix
				//if (!(node.transform.scale.x == node.transform.scale.y && node.transform.scale.x == node.transform.scale.z)) {
					helpMat.inverse2(helpMat);
					helpMat.transpose23x3();
				//}
				m = helpMat;
			}
			else if (c.link == "_viewNormalMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(node.transform.matrix);
				helpMat.mult2(camera.V); // View space
				helpMat.inverse2(helpMat);
				helpMat.transpose23x3();
				m = helpMat;
			}
			else if (c.link == "_viewMatrix") {
				m = camera.V;
			}
			else if (c.link == "_transposeInverseViewMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(camera.V);
				helpMat.inverse2(helpMat);
				helpMat.transpose2();
				m = helpMat;
			}
			else if (c.link == "_inverseViewMatrix") {
				helpMat.inverse2(camera.V);
				m = helpMat;
			}
			else if (c.link == "_transposeViewMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(camera.V);
				helpMat.transpose23x3();
				m = helpMat;
			}
			else if (c.link == "_projectionMatrix") {
				m = camera.P;
			}
			else if (c.link == "_inverseProjectionMatrix") {
				helpMat.inverse2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_inverseViewProjectionMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(camera.V);
				helpMat.mult2(camera.P);
				helpMat.inverse2(helpMat);
				m = helpMat;
			}
			else if (c.link == "_modelViewProjectionMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(node.transform.matrix);
				helpMat.mult2(camera.V);
				helpMat.mult2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_modelViewMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(node.transform.matrix);
				helpMat.mult2(camera.V);
				m = helpMat;
			}
			else if (c.link == "_viewProjectionMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(camera.V);
				helpMat.mult2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_prevViewProjectionMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(camera.prevV);
				helpMat.mult2(camera.P);
				m = helpMat;
			}
#if WITH_VELOC
			else if (c.link == "_prevModelViewProjectionMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(cast(node, ModelNode).prevMatrix);
				helpMat.mult2(camera.prevV);
				// helpMat.mult2(camera.prevP);
				helpMat.mult2(camera.P);
				m = helpMat;
			}
#end
			else if (c.link == "_lightModelViewProjectionMatrix") {
				helpMat.setIdentity();
				if (node != null) helpMat.mult2(node.transform.matrix); // node is null for DrawQuad
				helpMat.mult2(light.V);
				helpMat.mult2(light.resource.P);
				m = helpMat;
			}
			else if (c.link == "_lightVolumeModelViewProjectionMatrix") {
				var tr = light.transform;
				helpVec.set(tr.absx(), tr.absy(), tr.absz());
				helpVec2.set(light.farPlane, light.farPlane, light.farPlane);
				helpMat.compose(helpVec, helpQuat, helpVec2);
				helpMat.mult2(camera.V);
				helpMat.mult2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_biasLightModelViewProjectionMatrix") {
				helpMat.setIdentity();
				if (node != null) helpMat.mult2(node.transform.matrix); // node is null for DrawQuad
				helpMat.mult2(light.V);
				helpMat.mult2(light.resource.P);
				// helpMat.mult2(biasMat);
				m = helpMat;
			}
			else if (c.link == "_skydomeMatrix") {
				var tr = camera.transform;
				// helpVec.set(tr.absx(), tr.absy(), tr.absz() + 3.0); // Envtex
				helpVec.set(tr.absx(), tr.absy(), tr.absz() - 3.5); // Sky
				var bounds = camera.farPlane * 0.97;
				helpVec2.set(bounds, bounds, bounds);
				helpMat.compose(helpVec, helpQuat, helpVec2);
				helpMat.mult2(camera.V);
				helpMat.mult2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_lightViewMatrix") {
				m = light.V;
			}
			else if (c.link == "_lightProjectionMatrix") {
				m = light.resource.P;
			}
#if WITH_VR
			else if (c.link == "_undistortionMatrix") {
				m = iron.sys.VR.getUndistortionMatrix();
			}
#end
			if (m == null) return;
			g.setMatrix(location, m);
		}
		else if (c.type == "vec3") {
			var v:Vec4 = null;
			if (c.link == "_lightPosition") {
				helpVec.set(light.transform.absx(), light.transform.absy(), light.transform.absz());
				v = helpVec;
			}
			else if (c.link == "_lightDirection") {
				helpVec = light.look();
				v = helpVec;
			}
			else if (c.link == "_lightColor") {
				helpVec.set(light.resource.resource.color[0], light.resource.resource.color[1], light.resource.resource.color[2]);
				v = helpVec;
			}
			else if (c.link == "_cameraPosition") {
				helpVec.set(camera.transform.absx(), camera.transform.absy(), camera.transform.absz());
				v = helpVec;
			}
			else if (c.link == "_cameraLook") {
				helpVec = camera.look();
				v = helpVec;
			}
			else if (c.link == "_backgroundCol") {
				helpVec.set(camera.resource.resource.clear_color[0], camera.resource.resource.clear_color[1], camera.resource.resource.clear_color[2]);
				v = helpVec;
			}
			else if (c.link == "_probeVolumeCenter") { // Local probes
				v = camera.world.getProbeVolumeCenter(node.transform);
			}
			else if (c.link == "_probeVolumeSize") {
				v = camera.world.getProbeVolumeSize(node.transform);
			}
			
			else if (c.link == "_hosekA") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(camera.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.A.x;
				v.y = armory.renderpipeline.HosekWilkie.data.A.y;
				v.z = armory.renderpipeline.HosekWilkie.data.A.z;
			}
			else if (c.link == "_hosekB") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(camera.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.B.x;
				v.y = armory.renderpipeline.HosekWilkie.data.B.y;
				v.z = armory.renderpipeline.HosekWilkie.data.B.z;
			}
			else if (c.link == "_hosekC") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(camera.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.C.x;
				v.y = armory.renderpipeline.HosekWilkie.data.C.y;
				v.z = armory.renderpipeline.HosekWilkie.data.C.z;
			}
			else if (c.link == "_hosekD") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(camera.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.D.x;
				v.y = armory.renderpipeline.HosekWilkie.data.D.y;
				v.z = armory.renderpipeline.HosekWilkie.data.D.z;
			}
			else if (c.link == "_hosekE") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(camera.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.E.x;
				v.y = armory.renderpipeline.HosekWilkie.data.E.y;
				v.z = armory.renderpipeline.HosekWilkie.data.E.z;
			}
			else if (c.link == "_hosekF") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(camera.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.F.x;
				v.y = armory.renderpipeline.HosekWilkie.data.F.y;
				v.z = armory.renderpipeline.HosekWilkie.data.F.z;
			}
			else if (c.link == "_hosekG") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(camera.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.G.x;
				v.y = armory.renderpipeline.HosekWilkie.data.G.y;
				v.z = armory.renderpipeline.HosekWilkie.data.G.z;
			}
			else if (c.link == "_hosekH") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(camera.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.H.x;
				v.y = armory.renderpipeline.HosekWilkie.data.H.y;
				v.z = armory.renderpipeline.HosekWilkie.data.H.z;
			}
			else if (c.link == "_hosekI") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(camera.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.I.x;
				v.y = armory.renderpipeline.HosekWilkie.data.I.y;
				v.z = armory.renderpipeline.HosekWilkie.data.I.z;
			}
			else if (c.link == "_hosekZ") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(camera.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.Z.x;
				v.y = armory.renderpipeline.HosekWilkie.data.Z.y;
				v.z = armory.renderpipeline.HosekWilkie.data.Z.z;
			}
			
			if (v == null) return;
			g.setFloat3(location, v.x, v.y, v.z);
		}
		else if (c.type == "vec2") {
			var vx:Float = 0;
			var vy:Float = 0;
			if (c.link == "_vec2x") vx = 1.0;
			else if (c.link == "_vec2x2") vx = 2.0;
			else if (c.link == "_vec2y") vy = 1.0;
			else if (c.link == "_vec2y2") vy = 2.0;
			else if (c.link == "_vec2y3") vy = 3.0;
			else if (c.link == "_windowSize") {
				vx = App.w;
				vy = App.h;
			}
			else if (c.link == "_screenSize") {
				vx = camera.renderPath.currentRenderTargetW;
				vy = camera.renderPath.currentRenderTargetH;
			}
			else if (c.link == "_screenSizeInv") {
				vx = 1 / camera.renderPath.currentRenderTargetW;
				vy = 1 / camera.renderPath.currentRenderTargetH;
			}
			else if (c.link == "_aspectRatio") {
				vx = camera.renderPath.currentRenderTargetH / camera.renderPath.currentRenderTargetW;
				vy = camera.renderPath.currentRenderTargetW / camera.renderPath.currentRenderTargetH;
				vx = vx > 1 ? 1 : vx;
				vy = vy > 1 ? 1 : vy;
			}
			// else if (c.link == "_cameraPlane") {
				// vx = camera.resource.resource.near_plane;
				// vy = camera.resource.resource.far_plane;
			// }
			g.setFloat2(location, vx, vy);
		}
		else if (c.type == "float") {
			var f = 0.0;
			if (c.link == "_time") {
				f = kha.Scheduler.time();
			}
			else if (c.link == "_deltaTime") {
				f = iron.sys.Time.delta;
				// f = iron.sys.Time.realDelta;
			}
			else if (c.link == "_lightStrength") {
				f = light.resource.resource.strength;
			}
			else if (c.link == "_lightShadowsBias") {
				f = light.resource.resource.shadows_bias;
			}
			else if (c.link == "_spotlightCutoff") {
				f = light.resource.resource.spot_size;
			}
			else if (c.link == "_spotlightExponent") {
				f = light.resource.resource.spot_blend;
			}
			else if (c.link == "_envmapStrength") {
				f = camera.world.getGlobalProbe().strength;
			}
#if WITH_VR
			else if (c.link == "_maxRadiusSq") {
				f = iron.sys.VR.getMaxRadiusSq();
			}
#end
			// else if (c.link == "_u1") { f = ModelNode._u1; }
			// else if (c.link == "_u2") { f = ModelNode._u2; }
			// else if (c.link == "_u3") { f = ModelNode._u3; }
			// else if (c.link == "_u4") { f = ModelNode._u4; }
			// else if (c.link == "_u5") { f = ModelNode._u5; }
			// else if (c.link == "_u6") { f = ModelNode._u6; }
			g.setFloat(location, f);
		}
		else if (c.type == "floats") {
			var fa:haxe.ds.Vector<kha.FastFloat> = null;
			if (c.link == "_skinBones") {
				fa = cast(node, ModelNode).animation.skinBuffer;
			}
			else if (c.link == "_envmapIrradiance") {
				// fa = camera.world.getGlobalProbe().irradiance;
				fa = camera.world.getSHIrradiance();
			}
			g.setFloats(location, fa);
		}
		else if (c.type == "int") {
			var i = 0;
			if (c.link == "_uid") {
				i = node.uid;
			}
			if (c.link == "_lightType") {
				i = light.resource.lightType;
			}
			else if (c.link == "_lightIndex") {
				i = camera.renderPath.currentLightIndex;
			}
			else if (c.link == "_envmapNumMipmaps") {
				i = camera.world.getGlobalProbe().numMipmaps + 1; // Include basecolor
			}
			else if (c.link == "_probeID") { // Local probes
				i = camera.world.getProbeID(node.transform);
			}
			g.setInt(location, i);
		}
	}

	public static function setMaterialConstants(g:Graphics, context:ShaderContext, materialContext:MaterialContext) {
		if (materialContext.resource.bind_constants != null) {
			for (i in 0...materialContext.resource.bind_constants.length) {
				var matc = materialContext.resource.bind_constants[i];
				// TODO: cache
				var pos = -1;
				for (i in 0...context.resource.constants.length) {
					if (context.resource.constants[i].id == matc.id) {
						pos = i;
						break;
					}
				}
				if (pos == -1) continue;
				var c = context.resource.constants[pos];
				
				setMaterialConstant(g, context.constants[pos], c, matc);
			}
		}

		if (materialContext.textures != null) {
			for (i in 0...materialContext.textures.length) {
				var mid = materialContext.resource.bind_textures[i].id;

				// TODO: cache
				for (j in 0...context.textureUnits.length) {
					var sid = context.resource.texture_units[j].id;
					if (mid == sid) {
						g.setTexture(context.textureUnits[j], materialContext.textures[i]);
						// After texture sampler have been assigned, set texture parameters
						materialContext.setTextureParameters(g, i, context, j);
						break;
					}
				}
			}
		}
	}
	static function setMaterialConstant(g:Graphics, location:ConstantLocation, c:TShaderConstant, matc:TBindConstant) {

		if (c.type == "vec4") {
			g.setFloat4(location, matc.vec4[0], matc.vec4[1], matc.vec4[2], matc.vec4[3]);
		}
		else if (c.type == "vec3") {
			g.setFloat3(location, matc.vec3[0], matc.vec3[1], matc.vec3[2]);
		}
		else if (c.type == "vec2") {
			g.setFloat2(location, matc.vec2[0], matc.vec2[1]);
		}
		else if (c.type == "float") {
			g.setFloat(location, matc.float);
		}
		else if (c.type == "bool") {
			g.setBool(location, matc.bool);
		}
	}

	public function render(g:Graphics, context:String, camera:CameraNode, light:LightNode, bindParams:Array<String>) {
		// Skip render if material does not contain current context
		if (materials[0].getContext(context) == null) return;

		// Frustum culling
		if (camera.resource.resource.frustum_culling) {
			// Scale radius for skinned mesh
			// TODO: determine max skinned radius
			var radiusScale = resource.isSkinned ? 2.0 : 1.0;
			
			// Hard-coded for now
			var shadowsContext = camera.resource.pipeline.resource.shadows_context;
			var frustumPlanes = context == shadowsContext ? light.frustumPlanes : camera.frustumPlanes;

			// Instanced
			if (resource.geometry.instanced) {
				// Cull
				// TODO: per-instance culling
				var instanceInFrustum = false;
				for (v in resource.geometry.offsetVecs) {
					if (CameraNode.sphereInFrustum(frustumPlanes, transform, radiusScale, v.x, v.y, v.z)) {
						instanceInFrustum = true;
						break;
					}
				}
				if (!instanceInFrustum) return;

				// Sort - always front to back for now
				var camX = camera.transform.absx();
				var camY = camera.transform.absy();
				var camZ = camera.transform.absz();
				resource.geometry.sortInstanced(camX, camY, camZ);
			}
			// Non-instanced
			else {
				if (!CameraNode.sphereInFrustum(frustumPlanes, transform, radiusScale)) return;
			}
		}

		// Get context
		var cc = cachedContexts.get(context);
		if (cc == null) {
			cc = new CachedModelContext();
			// Check context skip
			for (mat in materials) {
				if (mat.resource.skip_context != null &&
					mat.resource.skip_context == context) {
					cc.enabled = false;
					break;
				}
			}
			if (cc.enabled) {
				cc.materialContexts = [];
				for (mat in materials) {
					for (i in 0...mat.resource.contexts.length) {
						if (mat.resource.contexts[i].id == context) {
							cc.materialContexts.push(mat.contexts[i]);
							break;
						}
					}
				}
				// TODO: only one shader per model
				cc.context = materials[0].shader.getContext(context);
				cachedContexts.set(context, cc);
			}
		}
		if (!cc.enabled) return;
		
		// TODO: move to update
		if (particleSystem != null) particleSystem.update();

		var materialContexts = cc.materialContexts;
		var shaderContext = cc.context;

		transform.update();
		
		// Render mesh
		g.setPipeline(shaderContext.pipeState);
		
		if (resource.geometry.instanced) {
			g.setVertexBuffers(resource.geometry.instancedVertexBuffers);
		}
		else {
#if WITH_DEINTERLEAVED
			g.setVertexBuffers(resource.geometry.vertexBuffers);
#else
			// var shadowsContext = camera.resource.pipeline.resource.shadows_context;
			// if (context == shadowsContext) { // Hard-coded for now
				// g.setVertexBuffer(resource.geometry.vertexBufferDepth);
			// }
			// else {
				g.setVertexBuffer(resource.geometry.vertexBuffer);
			// }
#end
		}

		setConstants(g, shaderContext, this, camera, light, bindParams);

		for (i in 0...resource.geometry.indexBuffers.length) {
			
			var mi = resource.geometry.materialIndices[i];
			if (materialContexts.length > mi) {
				setMaterialConstants(g, shaderContext, materialContexts[mi]);
			}

			g.setIndexBuffer(resource.geometry.indexBuffers[i]);

			if (resource.geometry.instanced) {
				g.drawIndexedVerticesInstanced(resource.geometry.instanceCount);
			}
			else {
				g.drawIndexedVertices();
			}
		}

#if WITH_PROFILE
		RenderPath.drawCalls++;
#end

#if WITH_VELOC
		prevMatrix.loadFrom(transform.matrix);
#end
	}

	public inline function computeCameraDistance(camX:Float, camY:Float, camZ:Float) {
		cameraDistance = iron.math.Math.distance3dRaw(camX, camY, camZ, transform.absx(), transform.absy(), transform.absz());
	}
}

class CachedModelContext {
	public var materialContexts:Array<MaterialContext>;
	public var context:ShaderContext;
	public var enabled = true;
	public function new() {}
}
