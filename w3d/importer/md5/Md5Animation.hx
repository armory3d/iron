package wings.w3d.importer.md5;

import haxe.io.StringInput;
import wings.math.Vec3;
import wings.math.Vec2;
import wings.math.Quat;
import wings.math.Mat4;
import wings.wxd.Time;
using StringTools;

class JointInfo {
	public var name:String;
	public var parentID:Int;
	public var flags:Int;
	public var startIndex:Int;

	public function new() { }
}

class Bound {
	public var min:Vec3;
	public var max:Vec3;

	public function new() {
		min = new Vec3();
		max = new Vec3();
	}
}

class BaseFrame {
	public var pos:Vec3;
	public var orient:Quat;

	public function new() {
		pos = new Vec3();
		orient = new Quat();
	}
}

class FrameData {
	public var frameID:Int;
	public var frameData:Array<Float> = [];

	public function new() { }
}

class SkeletonJoint {
	public var parent:Int;
	public var pos:Vec3;
	public var orient:Quat;

	public function new(frame:BaseFrame = null) {
		parent = -1;
		pos = new Vec3();
		orient = new Quat();

		if (frame != null) {
			pos = frame.pos.copy(null);
			frame.orient.copy(orient);
		}
	}
}

class FrameSkeleton {
	public var joints:Array<SkeletonJoint> = [];

	public function new() { }
}

class Md5Animation {
	var md5Version:Int = 0;
	var numFrames:Int = 0;
	var numJoints:Int = 0;
	var frameRate:Int = 0;
	var numAnimatedComponents:Int = 0;
	var animDuration:Float = 0;
	var frameDuration:Float = 0;
	var animTime:Float = 0;

	var jointInfos:Array<JointInfo>;
	var bounds:Array<Bound>;
	var baseFrames:Array<BaseFrame>;
	var frames:Array<FrameData>;
	var skeletons:Array<FrameSkeleton> = [];

	var animatedSkeleton:FrameSkeleton;

	var file:StringInput;
	var str:Array<String>;

	public function new() {

	}

	public function getSkeleton():FrameSkeleton {
		return animatedSkeleton;
	}

	public function getNumJoints():Int {
		return numJoints;
	}

	public function getJointInfo(index:Int) {
		return jointInfos[index];
	}

	public function loadAnimation(data:String) {
		jointInfos = [];
		bounds = [];
		baseFrames = [];
		frames = [];
		animatedSkeleton = new FrameSkeleton();
		numFrames = 0;

		file = new StringInput(data);

		try {
			while (true) {
				str = Md5Parser.readLine(file);

				if (str[0] == "MD5Version") {
					md5Version = Std.parseInt(str[1]);
					if (md5Version != 10) throw "Unsupported Md5 version";
				}
				else if (str[0] == "commandline") {
					continue;
				}
				else if (str[0] == "numFrames") {
					numFrames = Std.parseInt(str[1]);
				}
				else if (str[0] == "numJoints") {
					numJoints = Std.parseInt(str[1]);
				}
				else if (str[0] == "frameRate") {
					frameRate = Std.parseInt(str[1]);
				}
				else if (str[0] == "numAnimatedComponents") {
					numAnimatedComponents = Std.parseInt(str[1]);
				}
				else if (str[0] == "hierarchy") {
					for (i in 0...numJoints) {
						str = Md5Parser.readLine(file);

						var joint = new JointInfo();
						joint.name = str[0];
						joint.parentID = Std.parseInt(str[1]);
						joint.flags = Std.parseInt(str[2]);
						joint.startIndex = Std.parseInt(str[3]);
						joint.name = joint.name.substring(1, joint.name.length - 1);
						jointInfos.push(joint);
					}
				}
				else if (str[0] == "bounds") {
					for (i in 0...numFrames) {
						str = Md5Parser.readLine(file);

						var bound = new Bound();
						bound.min.x = Std.parseFloat(str[1]);
						bound.min.y = Std.parseFloat(str[2]);
						bound.min.z = Std.parseFloat(str[3]);
						bound.max.x = Std.parseFloat(str[6]);
						bound.max.y = Std.parseFloat(str[7]);
						bound.max.z = Std.parseFloat(str[8]);

						bounds.push(bound);
					}
				}
				else if (str[0] == "baseframe") {
					for (i in 0...numJoints) {
						str = Md5Parser.readLine(file);

						var baseFrame = new BaseFrame();
						baseFrame.pos.x = Std.parseFloat(str[1]);
						baseFrame.pos.y = Std.parseFloat(str[2]);
						baseFrame.pos.z = Std.parseFloat(str[3]);
						baseFrame.orient.x = Std.parseFloat(str[6]);
						baseFrame.orient.y = Std.parseFloat(str[7]);
						baseFrame.orient.z = Std.parseFloat(str[8]);

						baseFrames.push(baseFrame);
					}
				}
				else if (str[0] == "frame") {
					var frame = new FrameData();
					frame.frameID = Std.parseInt(str[1]);

					var i = 0;
					while (i < numAnimatedComponents) {
						str = Md5Parser.readLine(file);

						for (j in 0...str.length) {
							i++;
							var frameData:Float = Std.parseFloat(str[j]);
							frame.frameData.push(frameData);
						}
					}

					frames.push(frame);

					buildFrameSkeleton(skeletons, jointInfos, baseFrames, frame);
				}
			}
		}
		catch(ex:haxe.io.Eof) { }

		file.close();

		for (i in 0...numJoints) {
			animatedSkeleton.joints.push(new SkeletonJoint());
		}

		frameDuration = 1 / frameRate;
		animDuration = frameDuration * numFrames;
		animTime = 0;
	}

	public function update() {
		if (numFrames < 1) return;

		animTime += Time.delta / 1000;

		while (animTime > animDuration) animTime -= animDuration;
		while (animTime < 0) animTime += animDuration;

		var frameNum = animTime * frameRate;
		var frame0 = Std.int(Math.ffloor(frameNum));
		var frame1 = Std.int(Math.fceil(frameNum));
		frame0 = frame0 % numFrames;
		frame1 = frame1 % numFrames;

		var interpolate = (animTime % frameDuration) / frameDuration;

		interpolateSkeletons(animatedSkeleton, skeletons[frame0], skeletons[frame1], interpolate);
	}

	function buildFrameSkeleton(skeletons:Array<FrameSkeleton>, jointInfo:Array<JointInfo>, baseFrames:Array<BaseFrame>, frameData:FrameData) {
		var skeleton = new FrameSkeleton();

		for (i in 0...jointInfos.length) {
			var j = 0;

			var jointInfo = jointInfos[i];
			var animatedJoint = new SkeletonJoint(baseFrames[i]);
			animatedJoint.parent = jointInfo.parentID;

			if (jointInfo.flags & 1 == 1) {
				animatedJoint.pos.x = frameData.frameData[jointInfo.startIndex + j++];
			}
			if (jointInfo.flags & 2 == 2) {
				animatedJoint.pos.y = frameData.frameData[jointInfo.startIndex + j++];
			}
			if (jointInfo.flags & 4 == 4) {
				animatedJoint.pos.z = frameData.frameData[jointInfo.startIndex + j++];
			}
			if (jointInfo.flags & 8 == 8) {
				animatedJoint.orient.x = frameData.frameData[jointInfo.startIndex + j++];
			}
			if (jointInfo.flags & 16 == 16) {
				animatedJoint.orient.y = frameData.frameData[jointInfo.startIndex + j++];
			}
			if (jointInfo.flags & 32 == 32) {
				animatedJoint.orient.z = frameData.frameData[jointInfo.startIndex + j++];
			}

			Md5Parser.computeQuatW(animatedJoint.orient);

			if (animatedJoint.parent >= 0) {
				var parentJoint = skeleton.joints[animatedJoint.parent];
			
            	var rotPos = new Vec3();
            	rotPos = parentJoint.orient.vmult(animatedJoint.pos, rotPos);

				animatedJoint.pos = parentJoint.pos.copy(null);
				animatedJoint.pos = animatedJoint.pos.vadd(rotPos, animatedJoint.pos);
				
				animatedJoint.orient = animatedJoint.orient.mult(parentJoint.orient, animatedJoint.orient);

				animatedJoint.orient.normalize();
			}

			skeleton.joints.push(animatedJoint);
		}

		skeletons.push(skeleton);
	}

	function interpolateSkeletons(finalSkeleton:FrameSkeleton, skeleton0:FrameSkeleton, skeleton1:FrameSkeleton, interpolate:Float) {
		for (i in 0...numJoints) {
			var finalJoint = finalSkeleton.joints[i];
			var joint0 = skeleton0.joints[i];
			var joint1 = skeleton1.joints[i];

			finalJoint.parent = joint0.parent;

			finalJoint.pos = joint0.pos.copy(null);
			finalJoint.pos.lerp(joint1.pos, interpolate, finalJoint.pos);
			
			joint0.orient.copy(finalJoint.orient);
			finalJoint.orient.slerp(joint1.orient, interpolate);
		}
	}
}
