package wings.w3d.mesh;

class Md5Geometry extends Geometry {

	

	public function new() {

		//super(buildData(verts, uvs, norms), ind);
	}

    /*function buildData(verts:Array<Float>, uvs:Array<Float>, norms:Array<Float>):Array<Float> {
        var data = new Array<Float>();

        for (i in 0...md2.header.numTris * 3) {
            data.push(verts[i * 3]);
            data.push(verts[i * 3 + 1]);
            data.push(verts[i * 3 + 2]);
            data.push(uvs[i * 2]);
            data.push(uvs[i * 2 + 1]);
            data.push(norms[i * 3]);
            data.push(norms[i * 3 + 1]);
            data.push(norms[i * 3 + 2]);
        }

        return data;
    }*/
}
