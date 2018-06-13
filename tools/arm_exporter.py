#  Armory Mesh Exporter
#  http://armory3d.org/
#
#  Based on Open Game Engine Exchange
#  http://opengex.org/
#  Export plugin for Blender by Eric Lengyel
#  Copyright 2015, Terathon Software LLC
# 
#  This software is licensed under the Creative Commons
#  Attribution-ShareAlike 3.0 Unported License:
#  http://creativecommons.org/licenses/by-sa/3.0/deed.en_US

bl_info = {
    "name": "Armory Mesh Exporter",
    "category": "Import-Export",
    "location": "File -> Export",
    "description": "Armory mesh data",
    "author": "Armory3D.org",
    "version": (14, 0, 0),
    "blender": (2, 79, 0),
    "wiki_url": "http://armory3d.org/iron",
    "tracker_url": "https://github.com/armory3d/iron/issues"
}

from bpy_extras.io_utils import ExportHelper
import os
import bpy
import math
import time
import json
from mathutils import *

NodeTypeNode = 0
NodeTypeBone = 1
NodeTypeMesh = 2
NodeTypeLamp = 3
NodeTypeCamera = 4
NodeTypeSpeaker = 5
NodeTypeDecal = 6
AnimationTypeSampled = 0
AnimationTypeLinear = 1
AnimationTypeBezier = 2
ExportEpsilon = 1.0e-6

structIdentifier = ["object", "bone_object", "mesh_object", "lamp_object", "camera_object", "speaker_object", "decal_object"]

subtranslationName = ["xloc", "yloc", "zloc"]
subrotationName = ["xrot", "yrot", "zrot"]
subscaleName = ["xscl", "yscl", "zscl"]
deltaSubtranslationName = ["dxloc", "dyloc", "dzloc"]
deltaSubrotationName = ["dxrot", "dyrot", "dzrot"]
deltaSubscaleName = ["dxscl", "dyscl", "dzscl"]
axisName = ["x", "y", "z"]

class Vertex:
    # Based on https://github.com/Kupoman/blendergltf/blob/master/blendergltf.py
    __slots__ = ("co", "normal", "uvs", "col", "loop_indices", "index", "bone_weights", "bone_indices", "bone_count", "vertex_index")
    def __init__(self, mesh, loop):
        self.vertex_index = loop.vertex_index
        loop_idx = loop.index
        self.co = mesh.vertices[self.vertex_index].co[:]
        self.normal = loop.normal[:]
        self.uvs = tuple(layer.data[loop_idx].uv[:] for layer in mesh.uv_layers)
        self.col = [0.0, 0.0, 0.0]
        if len(mesh.vertex_colors) > 0:
            self.col = mesh.vertex_colors[0].data[loop_idx].color[:]
        # self.colors = tuple(layer.data[loop_idx].color[:] for layer in mesh.vertex_colors)
        self.loop_indices = [loop_idx]

        # Take the four most influential groups
        # groups = sorted(mesh.vertices[self.vertex_index].groups, key=lambda group: group.weight, reverse=True)
        # if len(groups) > 4:
            # groups = groups[:4]

        # self.bone_weights = [group.weight for group in groups]
        # self.bone_indices = [group.group for group in groups]
        # self.bone_count = len(self.bone_weights)

        self.index = 0

    def __hash__(self):
        return hash((self.co, self.normal, self.uvs))

    def __eq__(self, other):
        eq = (
            (self.co == other.co) and
            (self.normal == other.normal) and
            (self.uvs == other.uvs) and
            (self.col == other.col)
            )

        if eq:
            indices = self.loop_indices + other.loop_indices
            self.loop_indices = indices
            other.loop_indices = indices
        return eq

class ArmoryExporter(bpy.types.Operator, ExportHelper):
    '''Export to Armory format'''

    bl_idname = "export_scene.arm"
    bl_label = "Export Armory"
    filename_ext = ".arm"

    def write_matrix(self, matrix):
        return [matrix[0][0], matrix[0][1], matrix[0][2], matrix[0][3],
                matrix[1][0], matrix[1][1], matrix[1][2], matrix[1][3],
                matrix[2][0], matrix[2][1], matrix[2][2], matrix[2][3],
                matrix[3][0], matrix[3][1], matrix[3][2], matrix[3][3]]

    @staticmethod
    def calc_tangent(v0, v1, v2, uv0, uv1, uv2):
        deltaPos1 = v1 - v0
        deltaPos2 = v2 - v0
        deltaUV1 = uv1 - uv0
        deltaUV2 = uv2 - uv0
        
        d = (deltaUV1.x * deltaUV2.y - deltaUV1.y * deltaUV2.x)
        if d != 0:
            r = 1.0 / d
        else:
            r = 1.0
        tangent = (deltaPos1 * deltaUV2.y - deltaPos2 * deltaUV1.y) * r
        # bitangent = (deltaPos2 * deltaUV1.x - deltaPos1 * deltaUV2.x) * r
        return tangent

    def calc_tangents(self, posa, nora, uva, ias):
        vertex_count = int(len(posa) / 3)
        tangents = [0] * vertex_count * 3
        # bitangents = [0] * vertex_count * 3
        for ar in ias:
            ia = ar['values']
            triangle_count = int(len(ia) / 3)
            for i in range(0, triangle_count):
                i0 = ia[i * 3 + 0]
                i1 = ia[i * 3 + 1]
                i2 = ia[i * 3 + 2]
                # TODO: Slow
                v0 = Vector((posa[i0 * 3 + 0], posa[i0 * 3 + 1], posa[i0 * 3 + 2]))
                v1 = Vector((posa[i1 * 3 + 0], posa[i1 * 3 + 1], posa[i1 * 3 + 2]))
                v2 = Vector((posa[i2 * 3 + 0], posa[i2 * 3 + 1], posa[i2 * 3 + 2]))
                uv0 = Vector((uva[i0 * 2 + 0], uva[i0 * 2 + 1]))
                uv1 = Vector((uva[i1 * 2 + 0], uva[i1 * 2 + 1]))
                uv2 = Vector((uva[i2 * 2 + 0], uva[i2 * 2 + 1]))

                tangent = ArmoryExporter.calc_tangent(v0, v1, v2, uv0, uv1, uv2)

                tangents[i0 * 3 + 0] += tangent.x
                tangents[i0 * 3 + 1] += tangent.y
                tangents[i0 * 3 + 2] += tangent.z
                tangents[i1 * 3 + 0] += tangent.x
                tangents[i1 * 3 + 1] += tangent.y
                tangents[i1 * 3 + 2] += tangent.z
                tangents[i2 * 3 + 0] += tangent.x
                tangents[i2 * 3 + 1] += tangent.y
                tangents[i2 * 3 + 2] += tangent.z
                # bitangents[i0 * 3 + 0] += bitangent.x
                # bitangents[i0 * 3 + 1] += bitangent.y
                # bitangents[i0 * 3 + 2] += bitangent.z
                # bitangents[i1 * 3 + 0] += bitangent.x
                # bitangents[i1 * 3 + 1] += bitangent.y
                # bitangents[i1 * 3 + 2] += bitangent.z
                # bitangents[i2 * 3 + 0] += bitangent.x
                # bitangents[i2 * 3 + 1] += bitangent.y
                # bitangents[i2 * 3 + 2] += bitangent.z

        # Orthogonalize
        for i in range(0, vertex_count):
            # Slow
            t = Vector((tangents[i * 3], tangents[i * 3 + 1], tangents[i * 3 + 2]))
            # b = Vector((bitangents[i * 3], bitangents[i * 3 + 1], bitangents[i * 3 + 2]))
            n = Vector((nora[i * 3], nora[i * 3 + 1], nora[i * 3 + 2]))
            v = t - n * n.dot(t)
            v.normalize()
            # Calculate handedness
            # cnv = n.cross(v)
            # if cnv.dot(b) < 0.0:
                # v = v * -1.0
            tangents[i * 3] = v.x
            tangents[i * 3 + 1] = v.y
            tangents[i * 3 + 2] = v.z
        return tangents

    def write_mesh(self, bobject, o):
        self.output['mesh_datas'].append(o)

    def make_va(self, attrib, size, values):
        va = {}
        va['attrib'] = attrib
        va['size'] = size
        va['values'] = values
        return va

    def export_mesh_data(self, exportMesh, bobject, o):
        exportMesh.calc_normals_split()
        exportMesh.calc_tessface() # free_mpoly=True
        vert_list = { Vertex(exportMesh, loop) : 0 for loop in exportMesh.loops}.keys()
        num_verts = len(vert_list)
        num_uv_layers = len(exportMesh.uv_layers)
        has_tex = num_uv_layers > 0
        num_colors = len(exportMesh.vertex_colors)
        has_col = num_colors > 0
        has_tang = has_tex

        vdata = [0] * num_verts * 3
        ndata = [0] * num_verts * 3
        if has_tex:
            # Get active uvmap
            t0map = 0
            if bpy.app.version >= (2, 80, 1):
                uv_layers = exportMesh.uv_layers
            else:
                uv_layers = exportMesh.uv_textures
            if uv_layers != None:
                if 'UVMap_baked' in uv_layers:
                    for i in range(0, len(uv_layers)):
                        if uv_layers[i].name == 'UVMap_baked':
                            t0map = i
                            break
                else:
                    for i in range(0, len(uv_layers)):
                        if uv_layers[i].active_render:
                            t0map = i
                            break
            t1map = 1 if t0map == 0 else 0
            # Alloc data
            t0data = [0] * num_verts * 2
            if has_tex1:
                t1data = [0] * num_verts * 2
        if has_col:
            cdata = [0] * num_verts * 3


        # va_stride = 3 + 3 # pos + nor
        # va_name = 'pos_nor'
        # if has_tex:
        #     va_stride += 2
        #     va_name += '_tex'
        #     if has_tex1:
        #         va_stride += 2
        #         va_name += '_tex1'
        # if has_col > 0:
        #     va_stride += 3
        #     va_name += '_col'
        # if has_tang:
        #     va_stride += 3
        #     va_name += '_tang'
        # vdata = [0] * num_verts * va_stride

        # Make arrays
        for i, vtx in enumerate(vert_list):
            vtx.index = i
            co = vtx.co
            normal = vtx.normal
            for j in range(3):
                vdata[(i * 3) + j] = co[j]
                ndata[(i * 3) + j] = normal[j]
            if has_tex:
                t0data[i * 2] = vtx.uvs[t0map][0]
                t0data[i * 2 + 1] = 1.0 - vtx.uvs[t0map][1] # Reverse TCY
                if has_tex1:
                    t1data[i * 2] = vtx.uvs[t1map][0]
                    t1data[i * 2 + 1] = 1.0 - vtx.uvs[t1map][1]
            if has_col > 0:
                cdata[i * 3] = pow(vtx.col[0], 2.2)
                cdata[i * 3 + 1] = pow(vtx.col[1], 2.2)
                cdata[i * 3 + 2] = pow(vtx.col[2], 2.2)

        # Output
        o['vertex_arrays'] = []
        pa = self.make_va('pos', 3, vdata)
        o['vertex_arrays'].append(pa)
        na = self.make_va('nor', 3, ndata)
        o['vertex_arrays'].append(na)

        if has_tex:
            ta = self.make_va('tex', 2, t0data)
            o['vertex_arrays'].append(ta)
            if has_tex1:
                ta1 = self.make_va('tex1', 2, t1data)
                o['vertex_arrays'].append(ta1)

        if has_col:
            ca = self.make_va('col', 3, cdata)
            o['vertex_arrays'].append(ca)

        # Indices
        prims = {ma.name if ma else '': [] for ma in exportMesh.materials}
        if not prims:
            prims = {'': []}

        vert_dict = {i : v for v in vert_list for i in v.loop_indices}
        for poly in exportMesh.polygons:
            first = poly.loop_start
            if len(exportMesh.materials) == 0:
                prim = prims['']
            else:
                mat = exportMesh.materials[min(poly.material_index, len(exportMesh.materials) - 1)]
                prim = prims[mat.name if mat else '']
            indices = [vert_dict[i].index for i in range(first, first+poly.loop_total)]

            if poly.loop_total == 3:
                prim += indices
            elif poly.loop_total > 3:
                for i in range(poly.loop_total-2):
                    prim += (indices[-1], indices[i], indices[i + 1])

        # Write indices
        o['index_arrays'] = []
        for mat, prim in prims.items():
            idata = [0] * len(prim)
            for i, v in enumerate(prim):
                idata[i] = v
            if len(idata) == 0: # No face assigned
                continue
            ia = {}
            ia['values'] = idata
            ia['material'] = 0
            # Find material index for multi-mat mesh
            if len(exportMesh.materials) > 1:
                for i in range(0, len(exportMesh.materials)):
                    if (exportMesh.materials[i] != None and mat == exportMesh.materials[i].name) or \
                       (exportMesh.materials[i] == None and mat == ''): # Default material for empty slots
                        ia['material'] = i
                        break
            o['index_arrays'].append(ia)
        # Sort by material index
        # o['index_arrays'] = sorted(o['index_arrays'], key=lambda k: k['material']) 

        # Make tangents
        if has_tang:
            tanga_vals = self.calc_tangents(pa['values'], na['values'], ta['values'], o['index_arrays'])
            tanga = self.make_va('tang', 3, tanga_vals)
            o['vertex_arrays'].append(tanga)

        return vert_list

    def export_mesh(self, bobject, scene):
        # This function exports a single mesh object

        print('Exporting mesh ' + bobject.data.name)

        o = {}
        o['name'] = oid = bobject.name
        mesh = bobject.data
        structFlag = False;

        armature = bobject.find_armature()
        apply_modifiers = not armature

        # Apply all modifiers to create a new mesh with tessfaces
        if bpy.app.version >= (2, 80, 1):
            exportMesh = bobject.to_mesh(bpy.context.depsgraph, apply_modifiers, True, False)
        else:
            exportMesh = bobject.to_mesh(scene, apply_modifiers, "RENDER", True, False)

        # Process meshes
        vert_list = self.export_mesh_data(exportMesh, bobject, o)
        # if armature:
            # self.export_skin(bobject, armature, vert_list, o)

        self.write_mesh(bobject, o)

    def export_objects(self, scene):
        meshes = []
        self.output['mesh_datas'] = [];
        for o in scene.objects:
            if o.type == 'MESH' and o.data != None and o.data not in meshes:
                meshes.append(o.data)
                self.export_mesh(o, scene)

    def write_arm(self, filepath, output):
        with open(filepath, 'wb') as f:
            f.write(packb(output))
        # with open(filepath, 'w') as f:
            # f.write(json.dumps(output, sort_keys=True, indent=4))

    def execute(self, context):
        profile_time = time.time()
        self.output = {}
        self.export_objects(context.scene)
        self.write_arm(self.filepath, self.output)
        print('Scene exported in ' + str(time.time() - profile_time))
        return {'FINISHED'}

def menu_func(self, context):
    self.layout.operator(ArmoryExporter.bl_idname, text="Armory (.arm)")

def register():
    bpy.utils.register_class(ArmoryExporter)
    bpy.types.INFO_MT_file_export.append(menu_func)

def unregister():
    bpy.types.INFO_MT_file_export.remove(menu_func)
    bpy.utils.unregister_class(ArmoryExporter)

if __name__ == "__main__":
    register()

# Msgpack parser with typed arrays
# Based on u-msgpack-python v2.4.1 - v at sergeev.io
# https://github.com/vsergeev/u-msgpack-python
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
import struct
import io

def _pack_integer(obj, fp):
    if obj < 0:
        if obj >= -32:
            fp.write(struct.pack("b", obj))
        elif obj >= -2**(8 - 1):
            fp.write(b"\xd0" + struct.pack("b", obj))
        elif obj >= -2**(16 - 1):
            fp.write(b"\xd1" + struct.pack(">h", obj))
        elif obj >= -2**(32 - 1):
            fp.write(b"\xd2" + struct.pack(">i", obj))
        elif obj >= -2**(64 - 1):
            fp.write(b"\xd3" + struct.pack(">q", obj))
        else:
            raise Exception("huge signed int")
    else:
        if obj <= 127:
            fp.write(struct.pack("B", obj))
        elif obj <= 2**8 - 1:
            fp.write(b"\xcc" + struct.pack("B", obj))
        elif obj <= 2**16 - 1:
            fp.write(b"\xcd" + struct.pack(">H", obj))
        elif obj <= 2**32 - 1:
            fp.write(b"\xce" + struct.pack(">I", obj))
        elif obj <= 2**64 - 1:
            fp.write(b"\xcf" + struct.pack(">Q", obj))
        else:
            raise Exception("huge unsigned int")

def _pack_nil(obj, fp):
    fp.write(b"\xc0")

def _pack_boolean(obj, fp):
    fp.write(b"\xc3" if obj else b"\xc2")

def _pack_float(obj, fp):
    # NOTE: forced 32-bit floats for Armory
    # fp.write(b"\xcb" + struct.pack(">d", obj)) # Double
    fp.write(b"\xca" + struct.pack(">f", obj))

def _pack_string(obj, fp):
    obj = obj.encode('utf-8')
    if len(obj) <= 31:
        fp.write(struct.pack("B", 0xa0 | len(obj)) + obj)
    elif len(obj) <= 2**8 - 1:
        fp.write(b"\xd9" + struct.pack("B", len(obj)) + obj)
    elif len(obj) <= 2**16 - 1:
        fp.write(b"\xda" + struct.pack(">H", len(obj)) + obj)
    elif len(obj) <= 2**32 - 1:
        fp.write(b"\xdb" + struct.pack(">I", len(obj)) + obj)
    else:
        raise Exception("huge string")

def _pack_binary(obj, fp):
    if len(obj) <= 2**8 - 1:
        fp.write(b"\xc4" + struct.pack("B", len(obj)) + obj)
    elif len(obj) <= 2**16 - 1:
        fp.write(b"\xc5" + struct.pack(">H", len(obj)) + obj)
    elif len(obj) <= 2**32 - 1:
        fp.write(b"\xc6" + struct.pack(">I", len(obj)) + obj)
    else:
        raise Exception("huge binary string")

def _pack_array(obj, fp):
    if len(obj) <= 15:
        fp.write(struct.pack("B", 0x90 | len(obj)))
    elif len(obj) <= 2**16 - 1:
        fp.write(b"\xdc" + struct.pack(">H", len(obj)))
    elif len(obj) <= 2**32 - 1:
        fp.write(b"\xdd" + struct.pack(">I", len(obj)))
    else:
        raise Exception("huge array")

    # Float32
    if len(obj) > 0 and isinstance(obj[0], float):
        fp.write(b"\xca")
        for e in obj:
            fp.write(struct.pack(">f", e))
    # Int32
    elif len(obj) > 0 and isinstance(obj[0], int):
        fp.write(b"\xd2")
        for e in obj:
            fp.write(struct.pack(">i", e))
    # Regular
    else:
        for e in obj:
            pack(e, fp)

def _pack_map(obj, fp):
    if len(obj) <= 15:
        fp.write(struct.pack("B", 0x80 | len(obj)))
    elif len(obj) <= 2**16 - 1:
        fp.write(b"\xde" + struct.pack(">H", len(obj)))
    elif len(obj) <= 2**32 - 1:
        fp.write(b"\xdf" + struct.pack(">I", len(obj)))
    else:
        raise Exception("huge array")

    for k, v in obj.items():
        pack(k, fp)
        pack(v, fp)

def pack(obj, fp):
    if obj is None:
        _pack_nil(obj, fp)
    elif isinstance(obj, bool):
        _pack_boolean(obj, fp)
    elif isinstance(obj, int):
        _pack_integer(obj, fp)
    elif isinstance(obj, float):
        _pack_float(obj, fp)
    elif isinstance(obj, str):
        _pack_string(obj, fp)
    elif isinstance(obj, bytes):
        _pack_binary(obj, fp)
    elif isinstance(obj, list) or isinstance(obj, tuple):
        _pack_array(obj, fp)
    elif isinstance(obj, dict):
        _pack_map(obj, fp)
    else:
        raise Exception("unsupported type: %s" % str(type(obj)))

def packb(obj):
    fp = io.BytesIO()
    pack(obj, fp)
    return fp.getvalue()
