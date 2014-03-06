package wings.w3d.meshes;

class PlaneGeometry extends Geometry {
	
	public static inline var AXIS_X:Int = 0;
	public static inline var AXIS_Y:Int = 1;
	public static inline var AXIS_Z:Int = 2;

	public function new(w:Float, h:Float, segmentsX:Int = 2, segmentsY:Int = 2, uvsX:Int = 1, uvsY:Int = 1,
						heightData:Array<Int> = null, axis:Int = AXIS_Z) {

		var vertices = new Array<Float>();

		var stepX = w / (segmentsX - 1);
		var stepY = h / (segmentsY - 1);

		for (j in 0...segmentsY) {
			for (i in 0...segmentsX) {
				if (axis == AXIS_Z) {
					vertices.push(i * stepX - w / 2);
					vertices.push(j * stepY - h / 2);
					if (heightData == null) vertices.push(0);
					else vertices.push(heightData[j * segmentsX + i] / 3);
					
					vertices.push((i / segmentsX) * uvsX);
					vertices.push((j / segmentsY) * uvsY);

					vertices.push(0);
					vertices.push(0);
					vertices.push(1);
				}
				else {// if (axis == AXIS_Y) {
					vertices.push(i * stepX - w / 2);
					if (heightData == null) vertices.push(0);
					else vertices.push(heightData[j * segmentsX + i] / 3);
					vertices.push(j * stepY - h / 2);
					
					vertices.push((i / segmentsX) * uvsX);
					vertices.push((j / segmentsY) * uvsY);

					vertices.push(0);
					vertices.push(1);
					vertices.push(0);
				}
			}
		}

    	super(vertices, getIndices(segmentsX, segmentsY));
	}

	function getIndices(width:Int, height:Int):Array<Int> {

		/*var indices = new Array<Int>();

		//Generate indices
		for (y in 0...height)
		{
		    for (x in 0...width)
		    {
		        var curVertex:Int = (x + (y * (width + 1))); //Bottom left vertex ID

			    if (curVertex % 2 == 0)
			    {
			        indices.push((x)    + (y)   * (width + 1)); //Bottom Left
			        indices.push((x+1)  + (y)   * (width + 1)); //Bottom Right
			        indices.push((x+1)  + (y+1) * (width + 1)); //Top Right

			        indices.push((x+1)  + (y+1) * (width + 1)); //Top Right
			        indices.push((x)    + (y+1) * (width + 1)); //Top Left
			        indices.push((x)    + (y)   * (width + 1)); //Bottom Left
			    }
			    else //reverse triangle
			    {
			        indices.push((x+1)  + (y)   * (width + 1)); //Bottom Right
			        indices.push((x)    + (y)   * (width + 1)); //Bottom Left
			        indices.push((x)    + (y+1) * (width + 1)); //Top Left

			        indices.push((x)    + (y+1) * (width + 1)); //Top Left
			        indices.push((x+1)  + (y+1) * (width + 1)); //Top Right
			        indices.push((x+1)  + (y)   * (width + 1)); //Bottom Right
			    }
		    }
		}

		return indices;*/

		var n:Int = 0;
		var colSteps:Int = width * 2;
		var rowSteps:Int = height - 1;
		var indices = new Array<Int>();

		for (r in 0...rowSteps) {
		    for (c in 0...colSteps) {
		        var t:Int = c + r * colSteps;

		        if (c == colSteps - 1) {
		            indices.push(n);
		        }
		        else {
		            indices.push(n);

		            if (t % 2 == 0) {
		                n += width;
		            }
		            else {
		                (r % 2 == 0) ? n -= (width - 1) : n -= (width + 1);
		            }
		        }

		        if (t > 0 && t % (width * 2) == 0)  indices.pop();
		    }
		}

		var result:Array<Int> = new Array();

		for (i in 0...indices.length) {
			result.push(indices[i]);

			if (i > 1) {
				result.push(indices[i - 1]);
				result.push(indices[i]);
			}
		}

		return result;
	}
}
