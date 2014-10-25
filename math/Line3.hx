package fox.math;

/**
 * @author bhouston / http://exocortex.com
 */

/**
 * 
 * @haxeport Krtolica Vujadin - GameStudioHx.com
 */

class Line3 {
	
	public var start:Vector3;
	public var end:Vector3;	
	
	public function new(start:Vector3 = null, end:Vector3 = null) {
		this.start = start != null ? start : new Vector3();
		this.end = end != null ? end : new Vector3();
	}	
	
	public function set(start:Vector3, end:Vector3):Line3 {
		this.start.copy(start);
		this.end.copy(end);
		return this;
	}	
	
	public function copy(line:Line3):Line3 {
		this.start.copy(line.start);
		this.end.copy(line.end);
		return this;
	}	
	
	public function center(optionalTarget:Vector3 = null):Vector3 {
		var result = optionalTarget != null ? optionalTarget : new Vector3();
		return result.addVectors(this.start, this.end).multiplyScalar(0.5);
	}	
	
	public function delta(optionalTarget:Vector3 = null):Vector3 {
		var result = optionalTarget != null ? optionalTarget : new Vector3();
		return result.subVectors(this.end, this.start);
	}	
	
	public function distanceSq():Float {
		return this.start.distanceToSquared(end);
	}	
	
	public function distance():Float {
		return start.distanceTo(end);
	}	
	
	public function at(t:Float, optionalTarget:Vector3 = null):Vector3 {
		var result = (optionalTarget != null ? optionalTarget : new Vector3());
		return delta(result).multiplyScalar(t).add(start);
	}	
	
	public function closestPointToPointParameter(point:Vector3, clampToLine:Bool):Float {
		var startP = new Vector3();
		var startEnd = new Vector3();

		startP.subVectors(point, this.start);
		startEnd.subVectors(this.end, this.start);

		var startEnd2 = startEnd.dot(startEnd);
		var startEnd_startP = startEnd.dot(startP);

		var t = startEnd_startP / startEnd2;

		if (clampToLine) {
			t = fox.math.Math.clamp(t, 0, 1);
		}

		return t;
	}	
	
	public function closestPointToPoint(point:Vector3, clampToLine:Bool, optionalTarget:Vector3 = null) {
		var t = this.closestPointToPointParameter(point, clampToLine);
		var result = optionalTarget == null ? new Vector3() : optionalTarget;
		return this.delta(result).multiplyScalar(t).add(this.start);
	}
	
	public function applyMatrix4(m:Matrix4):Line3 {
		start.applyMatrix4(m);
		end.applyMatrix4(m);
		return this;
	}	
	
	public function equals(line:Line3):Bool	{
		return line.start.equals(this.start) && line.end.equals(this.end);
	}	
	
	public function clone():Line3 {
		return new Line3().copy(this);
	}
	
}
