package wings.sys.geometry;

class SphereGeometry extends Geometry {

	public function new(radius:Float, rings:Int, sectors:Int) {

		var R:Float = 1.0 / (rings - 1);
		var S:Float = 1.0 / (sectors - 1);

		var data:Array<Float> = new Array();
		var indices:Array<Int> = new Array();

	    for (r in 0...rings) {
	        for(s in 0...sectors) {
	        	var y:Float = Math.sin(-(Math.PI / 2) + Math.PI * r * R);
	        	var x:Float = Math.cos(2 * Math.PI * s * S) * Math.sin(Math.PI * r * R);
	            var z:Float = Math.sin(2 * Math.PI * s * S) * Math.sin(Math.PI * r * R);

	            data.push(x * radius);
	            data.push(y * radius);
	            data.push(z * radius);
	            data.push(s * S);
	            data.push(r * R);
	            data.push(x);
	            data.push(y);
	            data.push(z);

	            var curRow:Int = r * sectors;
			    var nextRow:Int = (r + 1) * sectors;

			    indices.push(curRow + s);
			    indices.push(nextRow + s);
			    indices.push(nextRow + (s + 1));

			    indices.push(curRow + s);
			    indices.push(nextRow + (s + 1));
			    indices.push(curRow + (s + 1));
	        }
	    }

	    super(data, indices);
	}
}
