package wings.w3d.mesh;

import wings.math.Vec3;

class FbxGeometry extends Geometry {

	public var library:wings.w3d.importer.fbx.Library;
	public var geom(default, null):wings.w3d.importer.fbx.Geometry;
	public var skin:wings.w3d.anim.Skin;
	public var multiMaterial:Bool;

	public function new(data:String, geometry:wings.w3d.importer.fbx.Geometry = null) {

		library = new wings.w3d.importer.fbx.Library();

		if (geometry == null) {
			library.loadTextFile(data);

			geom = library.getGeometry();
		}
		else {
			geom = geometry;
		}

		var verts = geom.getVertices();
		var norms = geom.getNormals();
		var tuvs = geom.getUVs()[0];
		var colors = geom.getColors();
		var mats = multiMaterial ? geom.getMaterials() : null;
		
		var gt = geom.getGeomTranslate();
		if( gt == null ) gt = new wings.w3d.importer.fbx.Point();
		
		var idx:Array<Int> = new Array();// hxd.IndexBuffer();
		var midx = new Array<Array<Int>>(); //Array<hxd.IndexBuffer>();
		var pbuf:Array<Float> = new Array();    //new hxd.FloatBuffer();
		var nbuf:Array<Float> = (norms == null ? null : new Array());// hxd.FloatBuffer());
		var sbuf = (skin == null ? null : new Array<Float>());//new haxe.io.BytesOutput());// hxd.BytesBuffer());
		var tbuf:Array<Float> = (tuvs == null ? null : new Array());//hxd.FloatBuffer());
		var cbuf = (colors == null ? null : new Array<Float>());//hxd.FloatBuffer());
		
		// skin split
		var sidx = null, stri = 0;
		if( skin != null && skin.isSplit() ) {
			if( multiMaterial ) throw "Multimaterial not supported with skin split";
			sidx = [for( _ in skin.splitJoints ) new Array<Int>()];// hxd.IndexBuffer()];
		}
		
		// triangulize indexes : format is  A,B,...,-X : negative values mark the end of the polygon
		var count = 0, pos = 0, matPos = 0;
		var index = geom.getPolygons();
		for( i in index ) {
			count++;
			if( i < 0 ) {
				index[pos] = -i - 1;
				var start = pos - count + 1;
				for( n in 0...count ) {
					var k = n + start;
					var vidx = index[k];
					
					var x = verts[vidx * 3] + gt.x;
					var y = verts[vidx * 3 + 1] + gt.y;
					var z = verts[vidx * 3 + 2] + gt.z;
					pbuf.push(x);
					pbuf.push(y);
					pbuf.push(z);

					if( nbuf != null ) {
						nbuf.push(norms[k*3]);
						nbuf.push(norms[k*3 + 1]);
						nbuf.push(norms[k*3 + 2]);
					}

					if( tbuf != null ) {
						var iuv = tuvs.index[k];
						tbuf.push(tuvs.values[iuv * 2]);
						tbuf.push(1 - tuvs.values[iuv * 2 + 1]);
					}
					
					if( sbuf != null ) {
						var p = vidx * skin.bonesPerVertex;
						var idx = 0;
						for( i in 0...skin.bonesPerVertex ) {
							//sbuf.writeFloat(skin.vertexWeights[p + i]);
							sbuf.push(skin.vertexWeights[p + i]);
							idx = (skin.vertexJoints[p + i] << (8*i)) | idx;
						}
						//sbuf.writeInt32(idx);
						sbuf.push(idx);
					}
					
					if( cbuf != null ) {
						var icol = colors.index[k];
						cbuf.push(colors.values[icol * 4]);
						cbuf.push(colors.values[icol * 4 + 1]);
						cbuf.push(colors.values[icol * 4 + 2]);
					}
				}
				// polygons are actually triangle fans
				for( n in 0...count - 2 ) {
					idx.push(start + n);
					idx.push(start + count - 1);
					idx.push(start + n + 1);
				}
				// by-skin-group index
				if( skin != null && skin.isSplit() ) {
					for( n in 0...count - 2 ) {
						var idx = sidx[skin.triangleGroups[stri++]];
						idx.push(start + n);
						idx.push(start + count - 1);
						idx.push(start + n + 1);
					}
				}
				// by-material index
				if( mats != null ) {
					var mid = mats[matPos++];
					var idx = midx[mid];
					if( idx == null ) {
						idx = new Array<Int>();//hxd.IndexBuffer();
						midx[mid] = idx;
					}
					for( n in 0...count - 2 ) {
						idx.push(start + n);
						idx.push(start + count - 1);
						idx.push(start + n + 1);
					}
				}
				index[pos] = i; // restore
				count = 0;
			}
			pos++;
		}

		var data:Array<Float> = new Array();
		for (i in 0...Std.int(pbuf.length / 3)) {
			data.push(pbuf[i * 3]);
			data.push(pbuf[i * 3 + 1]);
			data.push(pbuf[i * 3 + 2]);
			data.push(tbuf[i * 2]);
			data.push(tbuf[i * 2 + 1]);
			data.push(nbuf[i * 3]);
			data.push(nbuf[i * 3 + 1]);
			data.push(nbuf[i * 3 + 2]);

			data.push(sbuf[i * 3]);
			data.push(sbuf[i * 3 + 1]);
			data.push(sbuf[i * 3 + 2]);

			data.push(sidx[i * 3][0]);
			data.push(sidx[i * 3 + 1][0]);
			data.push(sidx[i * 3 + 2][0]);
		}

		super(data, idx);
	}
}
