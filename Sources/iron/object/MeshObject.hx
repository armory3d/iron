package iron.object;

import kha.graphics4.Graphics;
import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.MipMapFilter;
import iron.Scene;
import iron.math.Vec4;
import iron.math.Quat;
import iron.math.Mat4;
import iron.data.MeshData;
import iron.data.MaterialData;
import iron.data.ShaderData;
import iron.data.SceneFormat;
import iron.data.RenderPath;

class MeshObject extends Object {

	public var data:MeshData;
	public var materials:Array<MaterialData>;

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

	var cachedContexts:Map<String, CachedMeshContext> = new Map();
	
	public var cameraDistance:Float;

#if WITH_VELOC
	var prevMatrix = Mat4.identity();
#end

	public function new(data:MeshData, materials:Array<MaterialData>) {
		super();

		this.data = data;
		this.materials = materials;	
		Scene.active.meshes.push(this);
	}

	public override function remove() {
		Scene.active.meshes.remove(this);
		super.remove();
	}

	public override function setupAnimation(startTrack:String, names:Array<String>, starts:Array<Int>, ends:Array<Int>, speeds:Array<Float>, loops:Array<Bool>, reflects:Array<Bool>, maxBones = 50) {
		if (data.isSkinned) {
			animation = Animation.setupBoneAnimation(data, startTrack, names, starts, ends, speeds, loops, reflects, maxBones);
		}
		else {
			super.setupAnimation(startTrack, names, starts, ends, speeds, loops, reflects);
		}
	}

	public function setupParticleSystem(sceneName:String, pref:TParticleReference) {
		particleSystem = new ParticleSystem(this, sceneName, pref);
	}

	public static function setConstants(g:Graphics, context:ShaderContext, object:Object, camera:CameraObject, lamp:LampObject, bindParams:Array<String>) {

		for (i in 0...context.raw.constants.length) {
			var c = context.raw.constants[i];
			setConstant(g, object, camera, lamp, context.constants[i], c);
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
				var pipe = camera.data.pipeline;
				var rt = attachDepth ? pipe.depthToRenderTarget.get(rtID) : pipe.renderTargets.get(rtID);
				var tus = context.raw.texture_units;

				// Ping-pong
				if (rt.pong != null && !rt.pongState) rt = rt.pong;

				for (j in 0...tus.length) { // Set texture
					if (samplerID == tus[j].name) {
						// No filtering when sampling render targets
						// g.setTextureParameters(context.textureUnits[j], TextureAddressing.Clamp, TextureAddressing.Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
						if (attachDepth) g.setTextureDepth(context.textureUnits[j], rt.image);
						else g.setTexture(context.textureUnits[j], rt.image);
					}
				}
			}
		}
		
		// Texture links
		for (j in 0...context.raw.texture_units.length) {
			var tuid = context.raw.texture_units[j].name;
			var tulink = context.raw.texture_units[j].link;
			if (tulink == "_envmapRadiance") {
				g.setTexture(context.textureUnits[j], Scene.active.world.getGlobalProbe().radiance);
				g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.LinearMipFilter);
			}
			else if (tulink == "_envmapBrdf") {
				g.setTexture(context.textureUnits[j], Scene.active.world.brdf);
			}
			// Migrate to arm
			else if (tulink == "_smaaSearch") {
				g.setTexture(context.textureUnits[j], Reflect.field(kha.Assets.images, "smaa_search"));
			}
			else if (tulink == "_smaaArea") {
				g.setTexture(context.textureUnits[j], Reflect.field(kha.Assets.images, "smaa_area"));
			}
			else if (tulink == "_ltcMat") {
				if (iron.data.ConstData.ltcMatTex == null) iron.data.ConstData.initLTC();
				g.setTexture(context.textureUnits[j], iron.data.ConstData.ltcMatTex);
			}
			else if (tulink == "_ltcMag") {
				if (iron.data.ConstData.ltcMagTex == null) iron.data.ConstData.initLTC();
				g.setTexture(context.textureUnits[j], iron.data.ConstData.ltcMagTex);
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
		}
	}
	static function setConstant(g:Graphics, object:Object, camera:CameraObject, lamp:LampObject,
								location:ConstantLocation, c:TShaderConstant) {
		if (c.link == null) return;

		if (c.type == "mat4") {
			var m:Mat4 = null;
			if (c.link == "_worldMatrix") {
				m = object.transform.matrix;
			}
			else if (c.link == "_inverseWorldMatrix") {
				helpMat.inverse2(object.transform.matrix);
				m = helpMat;
			}
			else if (c.link == "_normalMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(object.transform.matrix);
				// Non uniform anisotropic scaling, calculate normal matrix
				//if (!(object.transform.scale.x == object.transform.scale.y && object.transform.scale.x == object.transform.scale.z)) {
					helpMat.inverse2(helpMat);
					helpMat.transpose23x3();
				//}
				m = helpMat;
			}
			else if (c.link == "_viewNormalMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(object.transform.matrix);
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
			else if (c.link == "_worldViewProjectionMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(object.transform.matrix);
				helpMat.mult2(camera.V);
				helpMat.mult2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_worldViewMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(object.transform.matrix);
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
			else if (c.link == "_prevWorldViewProjectionMatrix") {
				helpMat.setIdentity();
				helpMat.mult2(cast(object, MeshObject).prevMatrix);
				helpMat.mult2(camera.prevV);
				// helpMat.mult2(camera.prevP);
				helpMat.mult2(camera.P);
				m = helpMat;
			}
#end
			else if (c.link == "_lampWorldViewProjectionMatrix") {
				helpMat.setIdentity();
				if (object != null) helpMat.mult2(object.transform.matrix); // object is null for DrawQuad
				helpMat.mult2(lamp.V);
				helpMat.mult2(lamp.data.P);
				m = helpMat;
			}
			else if (c.link == "_lampVolumeWorldViewProjectionMatrix") {
				var tr = lamp.transform;
				helpVec.set(tr.absx(), tr.absy(), tr.absz());
				helpVec2.set(lamp.farPlane, lamp.farPlane, lamp.farPlane);
				helpMat.compose(helpVec, helpQuat, helpVec2);
				helpMat.mult2(camera.V);
				helpMat.mult2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_biasLampWorldViewProjectionMatrix") {
				helpMat.setIdentity();
				if (object != null) helpMat.mult2(object.transform.matrix); // object is null for DrawQuad
				helpMat.mult2(lamp.V);
				helpMat.mult2(lamp.data.P);
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
			else if (c.link == "_lampViewMatrix") {
				m = lamp.V;
			}
			else if (c.link == "_lampProjectionMatrix") {
				m = lamp.data.P;
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
			if (c.link == "_lampPosition") {
				helpVec.set(lamp.transform.absx(), lamp.transform.absy(), lamp.transform.absz());
				v = helpVec;
			}
			else if (c.link == "_lampDirection") {
				helpVec = lamp.look();
				v = helpVec;
			}
			else if (c.link == "_lampColor") {
				helpVec.set(lamp.data.raw.color[0], lamp.data.raw.color[1], lamp.data.raw.color[2]);
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
				helpVec.set(camera.data.raw.clear_color[0], camera.data.raw.clear_color[1], camera.data.raw.clear_color[2]);
				v = helpVec;
			}
			else if (c.link == "_probeVolumeCenter") { // Local probes
				v = Scene.active.world.getProbeVolumeCenter(object.transform);
			}
			else if (c.link == "_probeVolumeSize") {
				v = Scene.active.world.getProbeVolumeSize(object.transform);
			}
			
			else if (c.link == "_hosekA") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(Scene.active.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.A.x;
				v.y = armory.renderpipeline.HosekWilkie.data.A.y;
				v.z = armory.renderpipeline.HosekWilkie.data.A.z;
			}
			else if (c.link == "_hosekB") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(Scene.active.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.B.x;
				v.y = armory.renderpipeline.HosekWilkie.data.B.y;
				v.z = armory.renderpipeline.HosekWilkie.data.B.z;
			}
			else if (c.link == "_hosekC") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(Scene.active.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.C.x;
				v.y = armory.renderpipeline.HosekWilkie.data.C.y;
				v.z = armory.renderpipeline.HosekWilkie.data.C.z;
			}
			else if (c.link == "_hosekD") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(Scene.active.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.D.x;
				v.y = armory.renderpipeline.HosekWilkie.data.D.y;
				v.z = armory.renderpipeline.HosekWilkie.data.D.z;
			}
			else if (c.link == "_hosekE") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(Scene.active.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.E.x;
				v.y = armory.renderpipeline.HosekWilkie.data.E.y;
				v.z = armory.renderpipeline.HosekWilkie.data.E.z;
			}
			else if (c.link == "_hosekF") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(Scene.active.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.F.x;
				v.y = armory.renderpipeline.HosekWilkie.data.F.y;
				v.z = armory.renderpipeline.HosekWilkie.data.F.z;
			}
			else if (c.link == "_hosekG") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(Scene.active.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.G.x;
				v.y = armory.renderpipeline.HosekWilkie.data.G.y;
				v.z = armory.renderpipeline.HosekWilkie.data.G.z;
			}
			else if (c.link == "_hosekH") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(Scene.active.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.H.x;
				v.y = armory.renderpipeline.HosekWilkie.data.H.y;
				v.z = armory.renderpipeline.HosekWilkie.data.H.z;
			}
			else if (c.link == "_hosekI") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(Scene.active.world);
				}
				v = helpVec;
				v.x = armory.renderpipeline.HosekWilkie.data.I.x;
				v.y = armory.renderpipeline.HosekWilkie.data.I.y;
				v.z = armory.renderpipeline.HosekWilkie.data.I.z;
			}
			else if (c.link == "_hosekZ") {
				if (armory.renderpipeline.HosekWilkie.data == null) {
					armory.renderpipeline.HosekWilkie.init(Scene.active.world);
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
			else if (c.link == "_cameraPlane") {
				vx = camera.data.raw.near_plane;
				vy = camera.data.raw.far_plane;
			}
			g.setFloat2(location, vx, vy);
		}
		else if (c.type == "float") {
			var f = 0.0;
			if (c.link == "_time") {
				f = kha.Scheduler.time();
			}
			else if (c.link == "_deltaTime") {
				f = iron.sys.Time.delta;
			}
			else if (c.link == "_lampStrength") {
				f = lamp.data.raw.strength;
			}
			else if (c.link == "_lampShadowsBias") {
				f = lamp.data.raw.shadows_bias;
			}
			else if (c.link == "_spotlampCutoff") {
				f = lamp.data.raw.spot_size;
			}
			else if (c.link == "_spotlampExponent") {
				f = lamp.data.raw.spot_blend;
			}
			else if (c.link == "_envmapStrength") {
				f = Scene.active.world.getGlobalProbe().strength;
			}
#if WITH_VR
			else if (c.link == "_maxRadiusSq") {
				f = iron.sys.VR.getMaxRadiusSq();
			}
#end
			g.setFloat(location, f);
		}
		else if (c.type == "floats") {
			var fa:haxe.ds.Vector<kha.FastFloat> = null;
			if (c.link == "_skinBones") {
				fa = cast(object, MeshObject).animation.skinBuffer;
			}
			else if (c.link == "_envmapIrradiance") {
				// fa = Scene.active.world.getGlobalProbe().irradiance;
				fa = Scene.active.world.getSHIrradiance();
			}
			g.setFloats(location, fa);
		}
		else if (c.type == "int") {
			var i = 0;
			if (c.link == "_uid") {
				i = object.uid;
			}
			if (c.link == "_lampType") {
				i = lamp.data.lampType;
			}
			else if (c.link == "_lampIndex") {
				i = camera.renderPath.currentLampIndex;
			}
			else if (c.link == "_envmapNumMipmaps") {
				i = Scene.active.world.getGlobalProbe().numMipmaps + 1; // Include basecolor
			}
			else if (c.link == "_probeID") { // Local probes
				i = Scene.active.world.getProbeID(object.transform);
			}
			g.setInt(location, i);
		}
	}

	public static function setMaterialConstants(g:Graphics, context:ShaderContext, materialContext:MaterialContext) {
		if (materialContext.raw.bind_constants != null) {
			for (i in 0...materialContext.raw.bind_constants.length) {
				var matc = materialContext.raw.bind_constants[i];
				// TODO: cache
				var pos = -1;
				for (i in 0...context.raw.constants.length) {
					if (context.raw.constants[i].name == matc.name) {
						pos = i;
						break;
					}
				}
				if (pos == -1) continue;
				var c = context.raw.constants[pos];
				
				setMaterialConstant(g, context.constants[pos], c, matc);
			}
		}

		if (materialContext.textures != null) {
			for (i in 0...materialContext.textures.length) {
				var mname = materialContext.raw.bind_textures[i].name;

				// TODO: cache
				for (j in 0...context.textureUnits.length) {
					var sname = context.raw.texture_units[j].name;
					if (mname == sname) {
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

	public function render(g:Graphics, context:String, camera:CameraObject, lamp:LampObject, bindParams:Array<String>) {
		// Skip render if material does not contain current context
		if (materials[0].getContext(context) == null) return;

		// Skip render if object or lamp is hidden
		if (!visible || !lamp.visible) return;

		// Frustum culling
		culled = false;
		if (camera.data.raw.frustum_culling) {
			// Scale radius for skinned mesh
			// TODO: determine max skinned radius
			var radiusScale = data.isSkinned ? 2.0 : 1.0;
			
			// Hard-coded for now
			var shadowsContext = camera.data.pipeline.raw.shadows_context;
			var frustumPlanes = context == shadowsContext ? lamp.frustumPlanes : camera.frustumPlanes;

			// Instanced
			if (data.mesh.instanced) {
				// Cull
				// TODO: per-instance culling
				var instanceInFrustum = false;
				for (v in data.mesh.offsetVecs) {
					if (CameraObject.sphereInFrustum(frustumPlanes, transform, radiusScale, v.x, v.y, v.z)) {
						instanceInFrustum = true;
						break;
					}
				}
				if (!instanceInFrustum) {
					culled = true;
					return;
				}

				// Sort - always front to back for now
				var camX = camera.transform.absx();
				var camY = camera.transform.absy();
				var camZ = camera.transform.absz();
				data.mesh.sortInstanced(camX, camY, camZ);
			}
			// Non-instanced
			else {
				if (!CameraObject.sphereInFrustum(frustumPlanes, transform, radiusScale)) {
					culled = true;
					return;
				}
			}
		}

		// Get context
		var cc = cachedContexts.get(context);
		if (cc == null) {
			cc = new CachedMeshContext();
			// Check context skip
			for (mat in materials) {
				if (mat.raw.skip_context != null &&
					mat.raw.skip_context == context) {
					cc.enabled = false;
					break;
				}
			}
			if (cc.enabled) {
				cc.materialContexts = [];
				for (mat in materials) {
					for (i in 0...mat.raw.contexts.length) {
						if (mat.raw.contexts[i].name == context) {
							cc.materialContexts.push(mat.contexts[i]);
							break;
						}
					}
				}
				// TODO: only one shader per mesh
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
		
		if (data.mesh.instanced) {
			g.setVertexBuffers(data.mesh.instancedVertexBuffers);
		}
		else {
#if WITH_DEINTERLEAVED
			g.setVertexBuffers(data.mesh.vertexBuffers);
#else
			// var shadowsContext = camera.data.pipeline.raw.shadows_context;
			// if (context == shadowsContext) { // Hard-coded for now
				// g.setVertexBuffer(data.mesh.vertexBufferDepth);
			// }
			// else {
				g.setVertexBuffer(data.mesh.vertexBuffer);
			// }
#end
		}

		setConstants(g, shaderContext, this, camera, lamp, bindParams);

		for (i in 0...data.mesh.indexBuffers.length) {
			
			var mi = data.mesh.materialIndices[i];
			if (materialContexts.length > mi) {
				setMaterialConstants(g, shaderContext, materialContexts[mi]);
			}

			g.setIndexBuffer(data.mesh.indexBuffers[i]);

			if (data.mesh.instanced) {
				g.drawIndexedVerticesInstanced(data.mesh.instanceCount);
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
		cameraDistance = iron.math.Vec4.distance3dRaw(camX, camY, camZ, transform.absx(), transform.absy(), transform.absz());
	}
}

class CachedMeshContext {
	public var materialContexts:Array<MaterialContext>;
	public var context:ShaderContext;
	public var enabled = true;
	public function new() {}
}
