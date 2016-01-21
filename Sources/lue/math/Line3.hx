package lue.math;

/**
 * @author bhouston / http://exocortex.com
 * @haxeport Krtolica Vujadin - GameStudioHx.com
 */

class Line3 {
	
	public var start:Vec4;
	public var end:Vec4;	
	
	public function new(start:Vec4 = null, end:Vec4 = null) {
		this.start = start != null ? start : new Vec4();
		this.end = end != null ? end : new Vec4();
	}	
	
	public function set(start:Vec4, end:Vec4):Line3 {
		this.start.copy2(start);
		this.end.copy2(end);
		return this;
	}	
	
	public function copy(line:Line3):Line3 {
		this.start.copy2(line.start);
		this.end.copy2(line.end);
		return this;
	}	
	
	public function center(optionalTarget:Vec4 = null):Vec4 {
		var result = optionalTarget != null ? optionalTarget : new Vec4();
		return result.addVectors(this.start, this.end).multiplyScalar(0.5);
	}	
	
	public function delta(optionalTarget:Vec4 = null):Vec4 {
		var result = optionalTarget != null ? optionalTarget : new Vec4();
		return result.subVectors(this.end, this.start);
	}	
	
	public function distanceSq():Float {
		return this.start.distanceToSquared(end);
	}	
	
	public function distance():Float {
		return start.distanceTo(end);
	}	
	
	public function at(t:Float, optionalTarget:Vec4 = null):Vec4 {
		var result = (optionalTarget != null ? optionalTarget : new Vec4());
		return delta(result).multiplyScalar(t).add(start);
	}	
	
	public function closestPointToPointParameter(point:Vec4, clampToLine:Bool):Float {
		var startP = new Vec4();
		var startEnd = new Vec4();

		startP.subVectors(point, this.start);
		startEnd.subVectors(this.end, this.start);

		var startEnd2 = startEnd.dot(startEnd);
		var startEnd_startP = startEnd.dot(startP);

		var t = startEnd_startP / startEnd2;

		if (clampToLine) {
			t = lue.math.Math.clamp(t, 0, 1);
		}

		return t;
	}	
	
	public function closestPointToPoint(point:Vec4, clampToLine:Bool, optionalTarget:Vec4 = null) {
		var t = this.closestPointToPointParameter(point, clampToLine);
		var result = optionalTarget == null ? new Vec4() : optionalTarget;
		return this.delta(result).multiplyScalar(t).add(this.start);
	}
	
	public function applyMatrix4(m:Mat4):Line3 {
		start.applyMat4(m);
		end.applyMat4(m);
		return this;
	}	
	
	public function equals(line:Line3):Bool	{
		return line.start.equals(this.start) && line.end.equals(this.end);
	}	
	
	public function clone():Line3 {
		return new Line3().copy(this);
	}
}
