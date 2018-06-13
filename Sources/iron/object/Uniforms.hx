package iron.object;

import kha.graphics4.Graphics;
import kha.graphics4.ConstantLocation;
import kha.graphics4.TextureAddressing;
import kha.graphics4.TextureFilter;
import kha.graphics4.MipMapFilter;
import iron.Scene;
import iron.RenderPath;
import iron.math.Vec4;
import iron.math.Quat;
import iron.math.Mat3;
import iron.math.Mat4;
import iron.data.WorldData;
import iron.data.LampData;
import iron.data.MaterialData;
import iron.data.ShaderData;
import iron.data.SceneFormat;

// Structure for setting shader uniforms
class Uniforms {

	#if (kha_opengl || kha_webgl)
	public static var biasMat = new Mat4(
		0.5, 0.0, 0.0, 0.5,
		0.0, 0.5, 0.0, 0.5,
		0.0, 0.0, 0.5, 0.5,
		0.0, 0.0, 0.0, 1.0);
	#else // d3d
	public static var biasMat = new Mat4(
		0.5, 0.0, 0.0, 0.5,
		0.0, -0.5, 0.0, 0.5,
		0.0, 0.0, 0.5, 0.5,
		0.0, 0.0, 0.0, 1.0);
	#end
	public static var helpMat = Mat4.identity();
	public static var helpMat2 = Mat4.identity();
	public static var helpMat3 = Mat3.identity();
	public static var helpVec = new Vec4();
	public static var helpVec2 = new Vec4();
	public static var helpQuat = new Quat(); // Keep at identity

	public static var externalTextureLinks:Array<Object->MaterialData->String->kha.Image> = null;
	public static var externalMat4Links:Array<Object->MaterialData->String->Mat4> = null;
	public static var externalVec4Links:Array<Object->MaterialData->String->Vec4> = null;
	public static var externalVec3Links:Array<Object->MaterialData->String->Vec4> = null;
	public static var externalVec2Links:Array<Object->MaterialData->String->Vec4> = null;
	public static var externalFloatLinks:Array<Object->MaterialData->String->Null<kha.FastFloat>> = null;
	public static var externalFloatsLinks:Array<Object->MaterialData->String->kha.arrays.Float32Array> = null;
	public static var externalIntLinks:Array<Object->MaterialData->String->Null<Int>> = null;

	public static function setConstants(g:Graphics, context:ShaderContext, object:Object, camera:CameraObject, lamp:LampObject, bindParams:Array<String>) {

		if (context.raw.constants != null) {
			for (i in 0...context.raw.constants.length) {
				var c = context.raw.constants[i];
				setConstant(g, object, camera, lamp, context.constants[i], c);
			}
		}

		if (bindParams != null) { // Bind targets
			for (i in 0...Std.int(bindParams.length / 2)) {
				var pos = i * 2; // bind params = [texture, samplerID]
				var rtID = bindParams[pos];
				var samplerID = bindParams[pos + 1];
				var attachDepth = false; // Attach texture depth if '_' is prepended
				var char = rtID.charAt(0);
				if (char == "_") {
					attachDepth = true;
					rtID = rtID.substr(1);
				}
				var rt = attachDepth ? RenderPath.active.depthToRenderTarget.get(rtID) : RenderPath.active.renderTargets.get(rtID);
				bindRenderTarget(g, rt, context, samplerID, attachDepth);
			}
		}
		
		// Texture links
		if (context.raw.texture_units != null) {
			for (j in 0...context.raw.texture_units.length) {
				var tulink = context.raw.texture_units[j].link;
				if (tulink == null) continue;
				var tuid = context.raw.texture_units[j].name;

				if (tulink == "_envmapRadiance") {
					var w = Scene.active.world;
					if (w != null) {
						g.setTexture(context.textureUnits[j], w.getGlobalProbe().radiance);
						g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.LinearMipFilter);
					}
				}
				else if (tulink == "_envmap") {
					var w = Scene.active.world;
					if (w != null) g.setTexture(context.textureUnits[j], w.envmap);
				}
				else if (tulink == "_envmapBrdf") {
					g.setTexture(context.textureUnits[j], Scene.active.embedded.get('brdf.png'));
				}
				else if (tulink == "_noise8") {
					g.setTexture(context.textureUnits[j], Scene.active.embedded.get('noise8.png'));
					g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.NoMipFilter);
				}
				else if (tulink == "_noise64") {
					g.setTexture(context.textureUnits[j], Scene.active.embedded.get('noise64.png'));
					g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.NoMipFilter);
				}
				else if (tulink == "_blueNoise64") {
					g.setTexture(context.textureUnits[j], Scene.active.embedded.get('blue_noise64.png'));
					g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.NoMipFilter);
				}
				else if (tulink == "_noise256") {
					g.setTexture(context.textureUnits[j], Scene.active.embedded.get('noise256.png'));
					g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.NoMipFilter);
				}
				else if (tulink == "_lampColorTexture") {
					if (lamp != null) {
						g.setTexture(context.textureUnits[j], lamp.data.colorTexture);
						g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.NoMipFilter);
					}
				}
				else if (tulink == "_iesTexture") {
					g.setTexture(context.textureUnits[j], Scene.active.embedded.get('iestexture.png'));
					g.setTextureParameters(context.textureUnits[j], TextureAddressing.Repeat, TextureAddressing.Repeat, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.NoMipFilter);
				}
				else if (tulink == "_sdfTexture") {
					#if arm_sdf
					// g.setTexture3DParameters(context.textureUnits[j], TextureAddressing.Clamp, TextureAddressing.Clamp, TextureAddressing.Clamp, TextureFilter.LinearFilter, TextureFilter.PointFilter, MipMapFilter.LinearMipFilter);
					g.setTexture3DParameters(context.textureUnits[j], TextureAddressing.Clamp, TextureAddressing.Clamp, TextureAddressing.Clamp, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.NoMipFilter);

					// g.setTexture(context.textureUnits[j], cast(object, MeshObject).data.sdfTex);
					g.setTexture(context.textureUnits[j], iron.data.MeshData.sdfTex); // Use as global volume for now
					#end
				}
				// External
				else if (externalTextureLinks != null) {
					for (f in externalTextureLinks) {
						var image = f(object, currentMat(object), tulink);
						if (image != null) {
							g.setTexture(context.textureUnits[j], image);
							// g.setTextureParameters(context.textureUnits[j], TextureAddressing.Clamp, TextureAddressing.Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
							break;
						}
					}
				}
			}
		}
	}

	static function bindRenderTarget(g:Graphics, rt:RenderTarget, context:ShaderContext, samplerID:String, attachDepth:Bool) {
		if (rt != null) {
			var tus = context.raw.texture_units;

			for (j in 0...tus.length) { // Set texture
				if (samplerID == tus[j].name) {
					var isImage = tus[j].is_image != null && tus[j].is_image;

					if (rt.raw.depth > 1) { // sampler3D
						g.setTexture3DParameters(context.textureUnits[j], TextureAddressing.Clamp, TextureAddressing.Clamp, TextureAddressing.Clamp, TextureFilter.LinearFilter, TextureFilter.PointFilter, MipMapFilter.LinearMipFilter);
						context.paramsSet[j] = true;
					}

					if (isImage) {
						g.setImageTexture(context.textureUnits[j], rt.image); // image2D/3D

						// Multiple voxel volumes, always set params
						// if (!context.paramsSet[j]) {
							g.setTexture3DParameters(context.textureUnits[j], TextureAddressing.Clamp, TextureAddressing.Clamp, TextureAddressing.Clamp, TextureFilter.LinearFilter, TextureFilter.PointFilter, MipMapFilter.LinearMipFilter);
							context.paramsSet[j] = true;

						// }
					}
					else if (rt.isCubeMap) {
						if (attachDepth) g.setCubeMapDepth(context.textureUnits[j], rt.cubeMap); // samplerCube
						else g.setCubeMap(context.textureUnits[j], rt.cubeMap); // samplerCube
					}
					else {
						if (attachDepth) g.setTextureDepth(context.textureUnits[j], rt.image); // sampler2D
						else g.setTexture(context.textureUnits[j], rt.image); // sampler2D
					}


					if (!context.paramsSet[j] && rt.raw.mipmaps != null && rt.raw.mipmaps == true && !isImage) {
						g.setTextureParameters(context.textureUnits[j], TextureAddressing.Clamp, TextureAddressing.Clamp, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.LinearMipFilter);
						context.paramsSet[j] = true;
					}

					#if kha_webgl
					if (!context.paramsSet[j]) {
						// if (samplerID == "shadowMap" || samplerID == "shadowMapCube" || attachDepth) {
						if (samplerID == "shadowMap" || attachDepth) {
							g.setTextureParameters(context.textureUnits[j], TextureAddressing.Clamp, TextureAddressing.Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
							context.paramsSet[j] = true;
						}
						if (samplerID == "shadowMapCube") {
							context.paramsSet[j] = true;
						}
					}
					#end

					if (!context.paramsSet[j]) {
						// No filtering when sampling render targets
						#if (rp_resolution_filter == "Point")
						g.setTextureParameters(context.textureUnits[j], TextureAddressing.Clamp, TextureAddressing.Clamp, TextureFilter.PointFilter, TextureFilter.PointFilter, MipMapFilter.NoMipFilter);
						#else
						g.setTextureParameters(context.textureUnits[j], TextureAddressing.Clamp, TextureAddressing.Clamp, TextureFilter.LinearFilter, TextureFilter.LinearFilter, MipMapFilter.NoMipFilter);
						#end
						context.paramsSet[j] = true;
					}
				}
			}
		}
	}

	static function setConstant(g:Graphics, object:Object, camera:CameraObject, lamp:LampObject,
								location:ConstantLocation, c:TShaderConstant) {
		if (c.link == null) return;

		if (c.type == "mat4") {
			var m:Mat4 = null;
			if (c.link == "_worldMatrix") {
				m = object.transform.world;
			}
			else if (c.link == "_inverseWorldMatrix") {
				helpMat.getInverse(object.transform.world);
				m = helpMat;
			}
			else if (c.link == "_viewMatrix") {
				m = camera.V;
			}
			else if (c.link == "_transposeInverseViewMatrix") {
				helpMat.setFrom(camera.V);
				helpMat.getInverse(helpMat);
				helpMat.transpose();
				m = helpMat;
			}
			else if (c.link == "_inverseViewMatrix") {
				helpMat.getInverse(camera.V);
				m = helpMat;
			}
			else if (c.link == "_transposeViewMatrix") {
				helpMat.setFrom(camera.V);
				helpMat.transpose3x3();
				m = helpMat;
			}
			else if (c.link == "_projectionMatrix") {
				m = camera.P;
			}
			else if (c.link == "_inverseProjectionMatrix") {
				helpMat.getInverse(camera.P);
				m = helpMat;
			}
			else if (c.link == "_inverseViewProjectionMatrix") {
				helpMat.setFrom(camera.V);
				helpMat.multmat2(camera.P);
				helpMat.getInverse(helpMat);
				m = helpMat;
			}
			else if (c.link == "_worldViewProjectionMatrix") {
				helpMat.setFrom(object.transform.world);
				helpMat.multmat2(camera.V);
				helpMat.multmat2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_worldViewProjectionMatrixSphere") { // Billboard
				helpMat.setFrom(object.transform.world);
				helpMat.multmat2(camera.V);
				helpMat._00 = 1.0; helpMat._10 = 0.0; helpMat._20 = 0.0;
				helpMat._01 = 0.0; helpMat._11 = 1.0; helpMat._21 = 0.0;
				helpMat._02 = 0.0; helpMat._12 = 0.0; helpMat._22 = 1.0;
				helpMat.multmat2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_worldViewProjectionMatrixCylinder") { // Billboard - x rot 90deg
				helpMat.setFrom(object.transform.world);
				helpMat.multmat2(camera.V);
				helpMat._00 = 1.0;  helpMat._20 = 0.0;
				helpMat._01 = 0.0;  helpMat._21 = 0.0;
				helpMat._02 = 0.0;  helpMat._22 = 1.0;
				helpMat.multmat2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_worldViewMatrix") {
				helpMat.setFrom(object.transform.world);
				helpMat.multmat2(camera.V);
				m = helpMat;
			}
			else if (c.link == "_viewProjectionMatrix") {
				m = camera.VP;
			}
			else if (c.link == "_prevViewProjectionMatrix") {
				helpMat.setFrom(camera.prevV);
				helpMat.multmat2(camera.P);
				m = helpMat;
			}
			#if arm_veloc
			else if (c.link == "_prevWorldViewProjectionMatrix") {
				helpMat.setFrom(cast(object, MeshObject).prevMatrix);
				helpMat.multmat2(camera.prevV);
				// helpMat.multmat2(camera.prevP);
				helpMat.multmat2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_prevWorldMatrix") {
				m = cast(object, MeshObject).prevMatrix;
			}
			#end
			else if (c.link == "_lampWorldViewProjectionMatrix") {
				if (lamp != null) {
					// object is null for DrawQuad
					object == null ? helpMat.setIdentity() : helpMat.setFrom(object.transform.world);
					helpMat.multmat2(lamp.VP);
					m = helpMat;
				}
			}
			else if (c.link == "_lampWorldViewProjectionMatrixSphere") {
				if (lamp != null) {
					helpMat.setFrom(object.transform.world);
					
					// Align to camera..
					helpMat.multmat2(camera.V);
					helpMat._00 = 1.0; helpMat._10 = 0.0; helpMat._20 = 0.0;
					helpMat._01 = 0.0; helpMat._11 = 1.0; helpMat._21 = 0.0;
					helpMat._02 = 0.0; helpMat._12 = 0.0; helpMat._22 = 1.0;
					helpMat2.getInverse(camera.V);
					helpMat.multmat2(helpMat2);

					helpMat.multmat2(lamp.VP);
					m = helpMat;
				}
			}
			else if (c.link == "_lampWorldViewProjectionMatrixCylinder") {
				if (lamp != null) {
					helpMat.setFrom(object.transform.world);
					
					// Align to camera..
					helpMat.multmat2(camera.V);
					helpMat._00 = 1.0;  helpMat._20 = 0.0;
					helpMat._01 = 0.0;  helpMat._21 = 0.0;
					helpMat._02 = 0.0;  helpMat._22 = 1.0;
					helpMat2.getInverse(camera.V);
					helpMat.multmat2(helpMat2);

					helpMat.multmat2(lamp.VP);
					m = helpMat;
				}
			}
			else if (c.link == "_biasLampWorldViewProjectionMatrix") {
				if (lamp != null)  {
					// object is null for DrawQuad
					object == null ? helpMat.setIdentity() : helpMat.setFrom(object.transform.world);
					helpMat.multmat2(lamp.VP);
					helpMat.multmat2(biasMat);
					m = helpMat;
				}
			}
			else if (c.link == "_lampViewProjectionMatrix") {
				if (lamp != null) {
					m = lamp.VP;
				}
			}
			else if (c.link == "_biasLampViewProjectionMatrix") {
				if (lamp != null) {
					helpMat.setFrom(lamp.VP);
					helpMat.multmat2(biasMat);
					m = helpMat;
				}
			}
			else if (c.link == "_lampVolumeWorldViewProjectionMatrix") {
				if (lamp != null) {
					var tr = lamp.transform;
					var type = lamp.data.raw.type;
					if (type == "spot") { // Oriented cone
						// helpMat.setIdentity();
						// var f = lamp.data.raw.spot_size * lamp.data.raw.far_plane * 1.05;
						// helpVec2.set(f, f, lamp.data.raw.far_plane);
						// helpMat.scale(helpVec2);
						// helpMat2.setFrom(tr.world);
						// helpMat2.toRotation();
						// helpMat.multmat2(helpMat2);
						// helpMat.translate(tr.worldx(), tr.worldy(), tr.worldz());
						helpVec.set(tr.worldx(), tr.worldy(), tr.worldz());
						var f2:kha.FastFloat = 2.0;
						helpVec2.set(lamp.data.raw.far_plane, lamp.data.raw.far_plane * f2, lamp.data.raw.far_plane * f2);
						helpMat.compose(helpVec, helpQuat, helpVec2);
					}
					else if (type == "point" || type == "area") { // Sphere
						helpVec.set(tr.worldx(), tr.worldy(), tr.worldz());
						var f2:kha.FastFloat = 2.0;
						helpVec2.set(lamp.data.raw.far_plane, lamp.data.raw.far_plane * f2, lamp.data.raw.far_plane * f2);
						helpMat.compose(helpVec, helpQuat, helpVec2);
					}
					
					helpMat.multmat2(camera.V);
					helpMat.multmat2(camera.P);
					m = helpMat;
				}
			}
			else if (c.link == "_skydomeMatrix") {
				var tr = camera.transform;
				// helpVec.set(tr.worldx(), tr.worldy(), tr.worldz() + 3.0); // Envtex
				helpVec.set(tr.worldx(), tr.worldy(), tr.worldz() - 3.5); // Sky
				var bounds = camera.farPlane * 0.95;
				helpVec2.set(bounds, bounds, bounds);
				helpMat.compose(helpVec, helpQuat, helpVec2);
				helpMat.multmat2(camera.V);
				helpMat.multmat2(camera.P);
				m = helpMat;
			}
			else if (c.link == "_lampViewMatrix") {
				if (lamp != null) m = lamp.V;
			}
			else if (c.link == "_lampProjectionMatrix") {
				if (lamp != null) m = lamp.P;
			}
			else if (c.link == "_particleData") {
				var mo = cast(object, MeshObject);
				if (mo.particleOwner != null && mo.particleOwner.particleSystems != null) {
					m = mo.particleOwner.particleSystems[mo.particleIndex].getData();
				}
			}
			#if arm_vr
			else if (c.link == "_undistortionMatrix") {
				m = iron.system.VR.getUndistortionMatrix();
			}
			#end
			// External
			else if (externalMat4Links != null) {
				for (fn in externalMat4Links) {
					m = fn(object, currentMat(object), c.link);
					if (m != null) break;
				}
			}

			if (m == null) return;
			g.setMatrix(location, m.self);
		}
		else if (c.type == "mat3") {
			var m:Mat3 = null;
			if (c.link == "_normalMatrix") {
				helpMat.setFrom(object.transform.world);
				// Non uniform anisotropic scaling, calculate normal matrix
				//if (!(object.transform.scale.x == object.transform.scale.y && object.transform.scale.x == object.transform.scale.z)) {
					helpMat.getInverse(helpMat);
					helpMat.transpose3x3();
				//}
				helpMat3.setFrom4(helpMat);
				m = helpMat3;
			}

			if (m == null) return;
			g.setMatrix3(location, m.self);
		}
		else if (c.type == "vec4") {
			var v:Vec4 = null;
			helpVec.set(0, 0, 0);
			if (c.link == "_input") {
				helpVec.set(iron.system.Input.getMouse().x / iron.App.w(), iron.system.Input.getMouse().y / iron.App.h(), iron.system.Input.getMouse().down() ? 1.0 : 0.0, 0.0);
				v = helpVec;
			}
			// External
			else if (externalVec4Links != null) {
				for (fn in externalVec4Links) {
					v = fn(object, currentMat(object), c.link);
					if (v != null) break;
				}
			}

			if (v == null) return;
			g.setFloat4(location, v.x, v.y, v.z, v.w);
		}
		else if (c.type == "vec3") {
			var v:Vec4 = null;
			helpVec.set(0, 0, 0);
			if (c.link == "_lampPosition") {
				if (lamp != null) helpVec.set(lamp.transform.worldx(), lamp.transform.worldy(), lamp.transform.worldz());
				v = helpVec;
			}
			else if (c.link == "_lampDirection") {
				if (lamp != null) helpVec = lamp.look();
				v = helpVec;
			}
			else if (c.link == "_lampColor") {
				if (lamp != null) {
					var str = lamp.data.raw.strength; // Merge with strength
					helpVec.set(lamp.data.raw.color[0] * str, lamp.data.raw.color[1] * str, lamp.data.raw.color[2] * str);
				}
				v = helpVec;
			}
			else if (c.link == "_lampArea0") {
				if (lamp != null && lamp.data.raw.size != null) {
					var f2:kha.FastFloat = 0.5;
					var sx:kha.FastFloat = lamp.data.raw.size * f2;
					var sy:kha.FastFloat = lamp.data.raw.size_y * f2;
					helpVec.set(-sx, sy, 0.0);
					helpVec.applymat(lamp.transform.world);
					v = helpVec;
				}
			}
			else if (c.link == "_lampArea1") {
				if (lamp != null && lamp.data.raw.size != null) {
					var f2:kha.FastFloat = 0.5;
					var sx:kha.FastFloat = lamp.data.raw.size * f2;
					var sy:kha.FastFloat = lamp.data.raw.size_y * f2;
					helpVec.set(sx, sy, 0.0);
					helpVec.applymat(lamp.transform.world);
					v = helpVec;
				}
			}
			else if (c.link == "_lampArea2") {
				if (lamp != null && lamp.data.raw.size != null) {
					var f2:kha.FastFloat = 0.5;
					var sx:kha.FastFloat = lamp.data.raw.size * f2;
					var sy:kha.FastFloat = lamp.data.raw.size_y * f2;
					helpVec.set(sx, -sy, 0.0);
					helpVec.applymat(lamp.transform.world);
					v = helpVec;
				}
			}
			else if (c.link == "_lampArea3") {
				if (lamp != null && lamp.data.raw.size != null) {
					var f2:kha.FastFloat = 0.5;
					var sx:kha.FastFloat = lamp.data.raw.size * f2;
					var sy:kha.FastFloat = lamp.data.raw.size_y * f2;
					helpVec.set(-sx, -sy, 0.0);
					helpVec.applymat(lamp.transform.world);
					v = helpVec;
				}
			}
			else if (c.link == "_cameraPosition") {
				helpVec.set(camera.transform.worldx(), camera.transform.worldy(), camera.transform.worldz());
				v = helpVec;
			}
			else if (c.link == "_cameraLook") {
				helpVec = camera.lookWorld();
				v = helpVec;
			}
			else if (c.link == "_cameraUp") {
				helpVec = camera.upWorld();
				v = helpVec;
			}
			else if (c.link == "_cameraRight") {
				helpVec = camera.rightWorld();
				v = helpVec;
			}
			else if (c.link == "_dim") { // Model space
				var d = object.transform.dim;
				var s = object.transform.scale;
				helpVec.set((d.x / s.x), (d.y / s.y), (d.z / s.z));
				v = helpVec;
			}
			else if (c.link == "_halfDim") { // Model space
				var d = object.transform.dim;
				var s = object.transform.scale;
				helpVec.set((d.x / s.x) / 2, (d.y / s.y) / 2, (d.z / s.z) / 2);
				v = helpVec;
			}
			else if (c.link == "_backgroundCol") {
				if (camera.data.raw.clear_color != null) helpVec.set(camera.data.raw.clear_color[0], camera.data.raw.clear_color[1], camera.data.raw.clear_color[2]);
				v = helpVec;
			}
			else if (c.link == "_probeVolumeCenter") { // Local probes
				v = Scene.active.world.getProbeVolumeCenter(object.transform);
			}
			else if (c.link == "_probeVolumeSize") {
				v = Scene.active.world.getProbeVolumeSize(object.transform);
			}
			else if (c.link == "_sunDirection") {
				var w = Scene.active.world;
				if (w != null) {
					helpVec.set(w.raw.sun_direction[0], w.raw.sun_direction[1], w.raw.sun_direction[2]);
					v = helpVec;
				}
			}
			// External
			else if (externalVec3Links != null) {
				for (f in externalVec3Links) {
					v = f(object, currentMat(object), c.link);
					if (v != null) break;
				}
			}
			
			if (v == null) return;
			g.setFloat3(location, v.x, v.y, v.z);
		}
		else if (c.type == "vec2") {
			var vx:kha.FastFloat = 0;
			var vy:kha.FastFloat = 0;
			if (c.link == "_vec2x") vx = 1.0;
			else if (c.link == "_vec2xInv") vx = 1.0 / RenderPath.active.currentW;
			else if (c.link == "_vec2x2") vx = 2.0;
			else if (c.link == "_vec2x2Inv") vx = 2.0 / RenderPath.active.currentW;
			else if (c.link == "_vec2y") vy = 1.0;
			else if (c.link == "_vec2yInv") vy = 1.0 / RenderPath.active.currentH;
			else if (c.link == "_vec2y2") vy = 2.0;
			else if (c.link == "_vec2y2Inv") vy = 2.0 / RenderPath.active.currentH;
			else if (c.link == "_vec2y3") vy = 3.0;
			else if (c.link == "_vec2y3Inv") vy = 3.0 / RenderPath.active.currentH;

			else if (c.link == "_windowSize") {
				vx = App.w();
				vy = App.h();
			}
			else if (c.link == "_windowSizeInv") {
				vx = 1.0 / App.w();
				vy = 1.0 / App.h();
			}
			else if (c.link == "_screenSize") {
				vx = RenderPath.active.currentW;
				vy = RenderPath.active.currentH;
			}
			else if (c.link == "_screenSizeInv") {
				vx = 1.0 / RenderPath.active.currentW;
				vy = 1.0 / RenderPath.active.currentH;
			}
			else if (c.link == "_aspectRatio") {
				vx = RenderPath.active.currentH / RenderPath.active.currentW;
				vy = RenderPath.active.currentW / RenderPath.active.currentH;
				vx = vx > 1.0 ? 1.0 : vx;
				vy = vy > 1.0 ? 1.0 : vy;
			}
			else if (c.link == "_cameraPlane") {
				vx = camera.data.raw.near_plane;
				vy = camera.data.raw.far_plane;
			}
			else if (c.link == "_cameraPlaneProj") {
				var near = camera.data.raw.near_plane;
				var far = camera.data.raw.far_plane;
				vx = far / (far - near);
				vy = (-far * near) / (far - near);
			}
			else if (c.link == "_lampPlane") {
				vx = lamp == null ? 0.0 : lamp.data.raw.near_plane;
				vy = lamp == null ? 0.0 : lamp.data.raw.far_plane;
			}
			else if (c.link == "_lampPlaneProj") { // shadowCube
				if (lamp != null) {
					var near:kha.FastFloat = lamp.data.raw.near_plane;
					var far:kha.FastFloat = lamp.data.raw.far_plane;
					var a:kha.FastFloat = far + near;
					var b:kha.FastFloat = far - near;
					var f2:kha.FastFloat = 2.0;
					var c = f2 * far * near;
					vx = a / b;
					vy = c / b;
				}
			}
			else if (c.link == "_spotlampData") {
				// cutoff, cutoff - exponent
				vx = lamp == null ? 0.0 : lamp.data.raw.spot_size;
				vy = lamp == null ? 0.0 : vx - lamp.data.raw.spot_blend;
			}
			else if (c.link == "_tilesheetOffset") {
				var ts = cast(object, MeshObject).tilesheet;
				vx = ts.tileX;
				vy = ts.tileY;
			}
			// External
			else if (externalVec2Links != null) {
				for (fn in externalVec2Links) {
					var v = fn(object, currentMat(object), c.link);
					if (v != null) {
						vx = v.x;
						vy = v.y;
						break;
					}
				}
			}

			g.setFloat2(location, vx, vy);
		}
		else if (c.type == "float") {
			var f:kha.FastFloat = 0.0;
			if (c.link == "_time") {
				f = iron.system.Time.time();
			}
			else if (c.link == "_deltaTime") {
				f = iron.system.Time.delta;
			}
			else if (c.link == "_lampRadius") {
				f = lamp == null ? 0.0 : lamp.data.raw.far_plane;
			}
			else if (c.link == "_lampShadowsBias") {
				f = lamp == null ? 0.0 : lamp.data.raw.shadows_bias;
			}
			else if (c.link == "_lampSize") {
				if (lamp != null && lamp.data.raw.lamp_size != null) f = lamp.data.raw.lamp_size;
			}
			// else if (c.link == "_lampSizeUV") {
				// if (lamp != null && lamp.data.raw.lamp_size != null) f = lamp.data.raw.lamp_size / lamp.data.raw.fov;
			// }
			else if (c.link == "_envmapStrength") {
				if (Scene.active.world == null) f = 0.0;
				else f = Scene.active.world.getGlobalProbe().raw.strength;
			}
			else if (c.link == "_probeStrength") {
				f = Scene.active.world.getProbeStrength(object.transform);
			}
			else if (c.link == "_probeBlending") {
				f = Scene.active.world.getProbeBlending(object.transform);
			}
			else if (c.link == "_aspectRatioF") {
				f = RenderPath.active.currentW / RenderPath.active.currentH;
			}
			else if (c.link == "_aspectRatioWindowF") {
				f = iron.App.w() / iron.App.h();
			}
			else if (c.link == "_objectInfoIndex") {
				f = object.uid;
			}
			else if (c.link == "_objectInfoMaterialIndex") {
				f = currentMat(object).uid;
			}
			else if (c.link == "_objectInfoRandom") {
				f = object.urandom;
			}
			else if (c.link == "_frameScale") {
				f = RenderPath.active.frameTime / iron.system.Time.delta;
			}
			#if arm_vr
			else if (c.link == "_maxRadiusSq") {
				f = iron.system.VR.getMaxRadiusSq();
			}
			#end
			#if arm_voxelgi
			else if (c.link == "_voxelBlend") { // Blend current and last voxels
				var freq = armory.renderpath.RenderPathCreator.voxelFreq;
				f = (armory.renderpath.RenderPathCreator.voxelFrame % freq) / freq;
			}
			#end
			// External
			else if (externalFloatLinks != null) {
				for (fn in externalFloatLinks) {
					var res = fn(object, currentMat(object), c.link);
					if (res != null) {
						f = res;
						break;
					}
				}
			}

			g.setFloat(location, f);
		}
		else if (c.type == "floats") {
			var fa:kha.arrays.Float32Array = null;
			if (c.link == "_skinBones") {
				if (object.animation != null) fa = cast(object.animation, BoneAnimation).skinBuffer;
			}
			else if (c.link == "_envmapIrradiance") {
				if (Scene.active.world == null) fa = WorldData.getEmptyIrradiance();
				else fa = Scene.active.world.getSHIrradiance();
			}
			#if arm_csm
			if (c.link == "_cascadeData") {
				if (lamp != null) fa = lamp.getCascadeData();
			}
			#end
			// External
			else if (externalFloatsLinks != null) {
				for (fn in externalFloatsLinks) {
					fa = fn(object, currentMat(object), c.link);
					if (fa != null) break;
				}
			}

			if (fa != null) g.setFloats(location, fa);
		}
		else if (c.type == "int") {
			var i = 0;
			if (c.link == "_uid") {
				i = object.uid;
			}
			if (c.link == "_lampType") {
				i = lamp == null ? 0 : LampData.typeToInt(lamp.data.raw.type);
			}
			else if (c.link == "_lampIndex") {
				i = RenderPath.active.currentLampIndex;
			}
			else if (c.link == "_lampCastShadow") {
				if (lamp != null && lamp.data.raw.cast_shadow) {
					i = lamp.data.raw.shadowmap_cube ? 2 : 1;
				}
			}
			else if (c.link == "_envmapNumMipmaps") {
				var w = Scene.active.world;
				i = w != null ? w.getGlobalProbe().raw.radiance_mipmaps + 1 - 2 : 1; // Include basecolor and exclude 2 scaled mips
			}
			// else if (c.link == "_probeID") { // Local probes
				// var w = Scene.active.world;
				// i = w != null ? w.getProbeID(object.transform) : 0;
			// }
			// External
			else if (externalIntLinks != null) {
				for (fn in externalIntLinks) {
					var res = fn(object, currentMat(object), c.link);
					if (res != null) {
						i = res;
						break;
					}
				}
			}

			g.setInt(location, i);
		}
	}

	public static function setMaterialConstants(g:Graphics, context:ShaderContext, materialContext:MaterialContext) {
		if (materialContext.raw.bind_constants != null) {
			for (i in 0...materialContext.raw.bind_constants.length) {
				var matc = materialContext.raw.bind_constants[i];
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

	static function currentMat(object:Object):MaterialData {
		var rp = RenderPath.active;
		if (rp.currentMaterial != null) return rp.currentMaterial;
		if (object != null && Std.is(object, iron.object.MeshObject)) return cast(object, MeshObject).materials[0];
		return null;
	}

	static function setMaterialConstant(g:Graphics, location:ConstantLocation, c:TShaderConstant, matc:TBindConstant) {
		switch (c.type) {
		case "vec4": g.setFloat4(location, matc.vec4[0], matc.vec4[1], matc.vec4[2], matc.vec4[3]);
		case "vec3": g.setFloat3(location, matc.vec3[0], matc.vec3[1], matc.vec3[2]);
		case "vec2": g.setFloat2(location, matc.vec2[0], matc.vec2[1]);
		case "float": g.setFloat(location,  matc.float);
		case "bool": g.setBool(location, matc.bool);
		case "int": g.setInt(location, matc.int);
		}
	}
}
