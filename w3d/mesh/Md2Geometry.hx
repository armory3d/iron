package wings.w3d.mesh;

// Adapted from Foo3D Engine
// https://github.com/dazKind/foo3d

import kha.Sys;
import kha.graphics.VertexBuffer;
import kha.graphics.Usage;
import wings.math.Vec3;
import wings.w3d.importer.md2.Md2Parser;

class Md2Geometry extends Geometry {

	public var md2:Md2Model;

    public var vertexBuffers:Array<VertexBuffer>;

    var currentFrame:Int = 0;    
    var nextFrame:Int = 1;

	public function new(data:Md2Model) {

		// parse the modeldata
        md2 = data;

        // move all frames into individual VBOs
        vertexBuffers = [];

        var verts:Array<Float> = [];
        var norms:Array<Float> = [];

        // move the uvs into a VBO
        var uvs:Array<Float> = [];

        for (i in 0...md2.header.numTris) {

            uvs.push(md2.uv[md2.triangles[i].uvInds[0]].x);
            uvs.push(md2.uv[md2.triangles[i].uvInds[0]].y);
            uvs.push(md2.uv[md2.triangles[i].uvInds[1]].x);
            uvs.push(md2.uv[md2.triangles[i].uvInds[1]].y);
            uvs.push(md2.uv[md2.triangles[i].uvInds[2]].x);
            uvs.push(md2.uv[md2.triangles[i].uvInds[2]].y);
        }

        for (i in 0...md2.header.numFrames) {

            var f = md2.frames[i];
            var nf = (i < md2.header.numFrames - 1) ? md2.frames[i + 1] : md2.frames[0];
            
            verts = [];
            norms = [];

            for (j in 0...md2.header.numTris) {

                verts.push(f.verts[md2.triangles[j].vertInds[0]].x);
                verts.push(f.verts[md2.triangles[j].vertInds[0]].y);
                verts.push(f.verts[md2.triangles[j].vertInds[0]].z);

                verts.push(f.verts[md2.triangles[j].vertInds[1]].x);
                verts.push(f.verts[md2.triangles[j].vertInds[1]].y);
                verts.push(f.verts[md2.triangles[j].vertInds[1]].z);

                verts.push(f.verts[md2.triangles[j].vertInds[2]].x);
                verts.push(f.verts[md2.triangles[j].vertInds[2]].y);
                verts.push(f.verts[md2.triangles[j].vertInds[2]].z);

                // norms.push(f.normals[md2.triangles[j].vertInds[0]].x);
                // norms.push(f.normals[md2.triangles[j].vertInds[0]].y);
                // norms.push(f.normals[md2.triangles[j].vertInds[0]].z);

                // norms.push(f.normals[md2.triangles[j].vertInds[1]].x);
                // norms.push(f.normals[md2.triangles[j].vertInds[1]].y);
                // norms.push(f.normals[md2.triangles[j].vertInds[1]].z);

                // norms.push(f.normals[md2.triangles[j].vertInds[2]].x);
                // norms.push(f.normals[md2.triangles[j].vertInds[2]].y);
                // norms.push(f.normals[md2.triangles[j].vertInds[2]].z)

                norms.push(nf.verts[md2.triangles[j].vertInds[0]].x);
                norms.push(nf.verts[md2.triangles[j].vertInds[0]].y);
                norms.push(nf.verts[md2.triangles[j].vertInds[0]].z);

                norms.push(nf.verts[md2.triangles[j].vertInds[1]].x);
                norms.push(nf.verts[md2.triangles[j].vertInds[1]].y);
                norms.push(nf.verts[md2.triangles[j].vertInds[1]].z);

                norms.push(nf.verts[md2.triangles[j].vertInds[2]].x);
                norms.push(nf.verts[md2.triangles[j].vertInds[2]].y);
                norms.push(nf.verts[md2.triangles[j].vertInds[2]].z);
            }
            
            var data = buildData(verts, uvs, norms);

            // TODO: get struct
            //vertexBuffers.push(Sys.graphics.createVertexBuffer(Std.int(data.length / Geometry.structure.structureLength),
            //                                           Geometry.structure.structure, Usage.StaticUsage));


            var vertices = vertexBuffers[i].lock();

            for (j in 0...vertices.length) {
                vertices[j] = data[j];
            }
            vertexBuffers[i].unlock();
        }

        // make a simple IBO
        var ind:Array<Int> = [];

        for (i in 0...md2.header.numTris * 3) {
            ind.push(i);
        }

		super(buildData(verts, uvs, norms), ind);
	}

    function buildData(verts:Array<Float>, uvs:Array<Float>, norms:Array<Float>):Array<Float> {
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
    }
}
