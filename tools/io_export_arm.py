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
    "version": (2019, 6, 0),
    "blender": (2, 80, 0),
    "wiki_url": "http://armory3d.org/iron",
    "tracker_url": "https://github.com/armory3d/iron/issues"
}

from bpy_extras.io_utils import ExportHelper
import os
import bpy
import math
from mathutils import *
import time
import numpy as np

NodeTypeNode = 0
NodeTypeBone = 1
NodeTypeMesh = 2
NodeTypeLight = 3
NodeTypeCamera = 4
NodeTypeSpeaker = 5
NodeTypeDecal = 6
NodeTypeProbe = 7
AnimationTypeSampled = 0
AnimationTypeLinear = 1
AnimationTypeBezier = 2
ExportEpsilon = 1.0e-6

structIdentifier = ["object", "bone_object", "mesh_object", "light_object", "camera_object", "speaker_object", "decal_object", "probe_object"]
subtranslationName = ["xloc", "yloc", "zloc"]
subrotationName = ["xrot", "yrot", "zrot"]
subscaleName = ["xscl", "yscl", "zscl"]
deltaSubtranslationName = ["dxloc", "dyloc", "dzloc"]
deltaSubrotationName = ["dxrot", "dyrot", "dzrot"]
deltaSubscaleName = ["dxscl", "dyscl", "dzscl"]
axisName = ["x", "y", "z"]

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

    def write_mesh(self, bobject, o):
        self.output['mesh_datas'].append(o)

    def calc_aabb(self, bobject):
        aabb_center = 0.125 * sum((Vector(b) for b in bobject.bound_box), Vector())
        bobject.data.arm_aabb = [ \
            abs((bobject.bound_box[6][0] - bobject.bound_box[0][0]) / 2 + abs(aabb_center[0])) * 2, \
            abs((bobject.bound_box[6][1] - bobject.bound_box[0][1]) / 2 + abs(aabb_center[1])) * 2, \
            abs((bobject.bound_box[6][2] - bobject.bound_box[0][2]) / 2 + abs(aabb_center[2])) * 2  \
        ]

    def export_mesh_data(self, exportMesh, bobject, o, has_armature=False):
        exportMesh.calc_normals_split()
        # exportMesh.calc_loop_triangles()

        loops = exportMesh.loops
        num_verts = len(loops)
        num_uv_layers = len(exportMesh.uv_layers)
        has_tex = num_uv_layers > 0
        has_tex1 = num_uv_layers > 1
        num_colors = len(exportMesh.vertex_colors)
        has_col = num_colors > 0
        has_tang = has_tex

        pdata = np.empty(num_verts * 4, dtype='<f4') # p.xyz, n.z
        ndata = np.empty(num_verts * 2, dtype='<f4') # n.xy
        if has_tex:
            t0map = 0 # Get active uvmap
            t0data = np.empty(num_verts * 2, dtype='<f4')
            uv_layers = exportMesh.uv_layers
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
            if has_tex1:
                t1map = 1 if t0map == 0 else 0
                t1data = np.empty(num_verts * 2, dtype='<f4')
            # Scale for packed coords
            maxdim = 1.0
            lay0 = uv_layers[t0map] # TODO: handle t1map
            for v in lay0.data:
                if abs(v.uv[0]) > maxdim:
                    maxdim = abs(v.uv[0])
                if abs(v.uv[1]) > maxdim:
                    maxdim = abs(v.uv[1])
            if maxdim > 1:
                o['scale_tex'] = maxdim
                invscale_tex = (1 / o['scale_tex']) * 32767
            else:
                invscale_tex = 1 * 32767
            if has_tang:
                exportMesh.calc_tangents(uvmap=lay0.name)
                tangdata = np.empty(num_verts * 3, dtype='<f4')
        if has_col:
            cdata = np.empty(num_verts * 3, dtype='<f4')

        # Scale for packed coords
        maxdim = max(bobject.data.arm_aabb[0], max(bobject.data.arm_aabb[1], bobject.data.arm_aabb[2]))
        if maxdim > 2:
            o['scale_pos'] = maxdim / 2
        else:
            o['scale_pos'] = 1.0
        if has_armature: # Allow up to 2x bigger bounds for skinned mesh
            o['scale_pos'] *= 2.0
        
        scale_pos = o['scale_pos']
        invscale_pos = (1 / scale_pos) * 32767

        verts = exportMesh.vertices
        if has_tex:
            lay0 = exportMesh.uv_layers[t0map]
            if has_tex1:
                lay1 = exportMesh.uv_layers[t1map]

        for i, loop in enumerate(loops):
            v = verts[loop.vertex_index]
            co = v.co
            normal = loop.normal
            tang = loop.tangent

            i4 = i * 4
            i2 = i * 2
            pdata[i4    ] = co[0]
            pdata[i4 + 1] = co[1]
            pdata[i4 + 2] = co[2]
            pdata[i4 + 3] = normal[2] * scale_pos # Cancel scale
            ndata[i2    ] = normal[0]
            ndata[i2 + 1] = normal[1]
            if has_tex:
                uv = lay0.data[loop.index].uv
                t0data[i2    ] = uv[0]
                t0data[i2 + 1] = 1.0 - uv[1] # Reverse Y
                if has_tex1:
                    uv = lay1.data[loop.index].uv
                    t1data[i2    ] = uv[0]
                    t1data[i2 + 1] = 1.0 - uv[1]
                if has_tang:
                    i3 = i * 3
                    tangdata[i3    ] = tang[0]
                    tangdata[i3 + 1] = tang[1]
                    tangdata[i3 + 2] = tang[2]
            if has_col:
                i3 = i * 3
                cdata[i3    ] = pow(v.col[0], 2.2)
                cdata[i3 + 1] = pow(v.col[1], 2.2)
                cdata[i3 + 2] = pow(v.col[2], 2.2)

        mats = exportMesh.materials
        poly_map = []
        for i in range(max(len(mats), 1)):
            poly_map.append([])
        for poly in exportMesh.polygons:
            poly_map[poly.material_index].append(poly)

        o['index_arrays'] = []
        for index, polys in enumerate(poly_map):
            tris = 0
            for poly in polys:
                tris += poly.loop_total - 2
            if tris == 0: # No face assigned
                continue
            prim = np.empty(tris * 3, dtype='<i4')

            i = 0
            for poly in polys:
                first = poly.loop_start
                total = poly.loop_total
                if total == 3:
                    prim[i    ] = loops[first    ].index
                    prim[i + 1] = loops[first + 1].index
                    prim[i + 2] = loops[first + 2].index
                    i += 3
                else:
                    for j in range(total - 2):
                        prim[i    ] = loops[first + total - 1].index
                        prim[i + 1] = loops[first + j        ].index
                        prim[i + 2] = loops[first + j + 1    ].index
                        i += 3

            ia = {}
            ia['values'] = prim
            ia['material'] = 0
            if len(mats) > 1:
                for i in range(len(mats)): # Multi-mat mesh
                    if (mats[i] == mats[index]): # Default material for empty slots
                        ia['material'] = i
                        break
            o['index_arrays'].append(ia)

        # Pack
        pdata *= invscale_pos
        ndata *= 32767
        pdata = np.array(pdata, dtype='<i2')
        ndata = np.array(ndata, dtype='<i2')
        if has_tex:
            t0data *= invscale_tex
            t0data = np.array(t0data, dtype='<i2')
            if has_tex1:
                t1data *= invscale_tex
                t1data = np.array(t1data, dtype='<i2')
        if has_col:
            cdata *= 32767
            cdata = np.array(cdata, dtype='<i2')
        if has_tang:
            tangdata *= 32767
            tangdata = np.array(tangdata, dtype='<i2')

        # Output
        o['vertex_arrays'] = []
        o['vertex_arrays'].append({ 'attrib': 'pos', 'values': pdata })
        o['vertex_arrays'].append({ 'attrib': 'nor', 'values': ndata })
        if has_tex:
            o['vertex_arrays'].append({ 'attrib': 'tex', 'values': t0data })
            if has_tex1:
                o['vertex_arrays'].append({ 'attrib': 'tex1', 'values': t1data })
        if has_col:
            o['vertex_arrays'].append({ 'attrib': 'col', 'values': cdata })
        if has_tang:
            o['vertex_arrays'].append({ 'attrib': 'tang', 'values': tangdata })

    def export_mesh(self, bobject, scene):
        # This function exports a single mesh object
        print('Exporting mesh ' + bobject.data.name)

        o = {}
        o['name'] = bobject.name
        mesh = bobject.data

        armature = bobject.find_armature()
        apply_modifiers = not armature
        bobject_eval = bobject.evaluated_get(self.depsgraph) if apply_modifiers else bobject
        exportMesh = bobject_eval.to_mesh()

        self.calc_aabb(bobject)
        self.export_mesh_data(exportMesh, bobject, o, has_armature=armature != None)
        # if armature:
            # self.export_skin(bobject, armature, exportMesh, o)

        self.write_mesh(bobject, o)
        bobject_eval.to_mesh_clear()

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

    def execute(self, context):
        profile_time = time.time()
        self.depsgraph = context.evaluated_depsgraph_get()
        self.output = {}
        self.export_objects(context.scene)
        self.write_arm(self.filepath, self.output)
        print('Scene exported in ' + str(time.time() - profile_time))
        return {'FINISHED'}

def menu_func(self, context):
    self.layout.operator(ArmoryExporter.bl_idname, text="Armory (.arm)")

def register():
    bpy.utils.register_class(ArmoryExporter)
    bpy.types.TOPBAR_MT_file_export.append(menu_func)

def unregister():
    bpy.types.TOPBAR_MT_file_export.remove(menu_func)
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
import numpy as np

def _pack_integer(obj, fp):
    if obj < 0:
        if obj >= -32:
            fp.write(struct.pack("b", obj))
        elif obj >= -2**(8 - 1):
            fp.write(b"\xd0" + struct.pack("b", obj))
        elif obj >= -2**(16 - 1):
            fp.write(b"\xd1" + struct.pack("<h", obj))
        elif obj >= -2**(32 - 1):
            fp.write(b"\xd2" + struct.pack("<i", obj))
        elif obj >= -2**(64 - 1):
            fp.write(b"\xd3" + struct.pack("<q", obj))
        else:
            raise Exception("huge signed int")
    else:
        if obj <= 127:
            fp.write(struct.pack("B", obj))
        elif obj <= 2**8 - 1:
            fp.write(b"\xcc" + struct.pack("B", obj))
        elif obj <= 2**16 - 1:
            fp.write(b"\xcd" + struct.pack("<H", obj))
        elif obj <= 2**32 - 1:
            fp.write(b"\xce" + struct.pack("<I", obj))
        elif obj <= 2**64 - 1:
            fp.write(b"\xcf" + struct.pack("<Q", obj))
        else:
            raise Exception("huge unsigned int")

def _pack_nil(obj, fp):
    fp.write(b"\xc0")

def _pack_boolean(obj, fp):
    fp.write(b"\xc3" if obj else b"\xc2")

def _pack_float(obj, fp):
    # NOTE: forced 32-bit floats for Armory
    # fp.write(b"\xcb" + struct.pack("<d", obj)) # Double
    fp.write(b"\xca" + struct.pack("<f", obj))

def _pack_string(obj, fp):
    obj = obj.encode('utf-8')
    if len(obj) <= 31:
        fp.write(struct.pack("B", 0xa0 | len(obj)) + obj)
    elif len(obj) <= 2**8 - 1:
        fp.write(b"\xd9" + struct.pack("B", len(obj)) + obj)
    elif len(obj) <= 2**16 - 1:
        fp.write(b"\xda" + struct.pack("<H", len(obj)) + obj)
    elif len(obj) <= 2**32 - 1:
        fp.write(b"\xdb" + struct.pack("<I", len(obj)) + obj)
    else:
        raise Exception("huge string")

def _pack_binary(obj, fp):
    if len(obj) <= 2**8 - 1:
        fp.write(b"\xc4" + struct.pack("B", len(obj)) + obj)
    elif len(obj) <= 2**16 - 1:
        fp.write(b"\xc5" + struct.pack("<H", len(obj)) + obj)
    elif len(obj) <= 2**32 - 1:
        fp.write(b"\xc6" + struct.pack("<I", len(obj)) + obj)
    else:
        raise Exception("huge binary string")

def _pack_array(obj, fp):
    if len(obj) <= 15:
        fp.write(struct.pack("B", 0x90 | len(obj)))
    elif len(obj) <= 2**16 - 1:
        fp.write(b"\xdc" + struct.pack("<H", len(obj)))
    elif len(obj) <= 2**32 - 1:
        fp.write(b"\xdd" + struct.pack("<I", len(obj)))
    else:
        raise Exception("huge array")

    if len(obj) > 0 and isinstance(obj[0], float):
        fp.write(b"\xca")
        for e in obj:
            fp.write(struct.pack("<f", e))
    elif len(obj) > 0 and isinstance(obj[0], bool):
        for e in obj:
            pack(e, fp)
    elif len(obj) > 0 and isinstance(obj[0], int):
        fp.write(b"\xd2")
        for e in obj:
            fp.write(struct.pack("<i", e))
    # Float32
    elif len(obj) > 0 and isinstance(obj[0], np.float32):
        fp.write(b"\xca")
        fp.write(obj.tobytes())
    # Int32
    elif len(obj) > 0 and isinstance(obj[0], np.int32):
        fp.write(b"\xd2")
        fp.write(obj.tobytes())
    # Int16
    elif len(obj) > 0 and isinstance(obj[0], np.int16):
        fp.write(b"\xd1")
        fp.write(obj.tobytes())
    # Regular
    else:
        for e in obj:
            pack(e, fp)

def _pack_map(obj, fp):
    if len(obj) <= 15:
        fp.write(struct.pack("B", 0x80 | len(obj)))
    elif len(obj) <= 2**16 - 1:
        fp.write(b"\xde" + struct.pack("<H", len(obj)))
    elif len(obj) <= 2**32 - 1:
        fp.write(b"\xdf" + struct.pack("<I", len(obj)))
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
    elif isinstance(obj, list) or isinstance(obj, tuple) or isinstance(obj, np.ndarray):
        _pack_array(obj, fp)
    elif isinstance(obj, dict):
        _pack_map(obj, fp)
    else:
        raise Exception("unsupported type: %s" % str(type(obj)))

def packb(obj):
    fp = io.BytesIO()
    pack(obj, fp)
    return fp.getvalue()
