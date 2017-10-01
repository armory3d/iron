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
    "version": (10, 0, 0),
    "blender": (2, 78, 0),
    "wiki_url": "http://armory3d.org/manual",
    "tracker_url": "https://github.com/armory3d/armory/issues"
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
AnimationTypeSampled = 0
AnimationTypeLinear = 1
AnimationTypeBezier = 2
ExportEpsilon = 1.0e-6

structIdentifier = ["object", "bone_object", "mesh_object", "lamp_object", "camera_object", "speaker_object"]

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
        self.col = [0, 0, 0]
        if len(mesh.vertex_colors) > 0:
            self.col = mesh.vertex_colors[0].data[loop_idx].color[:]
        # self.colors = tuple(layer.data[loop_idx].color[:] for layer in mesh.vertex_colors)
        self.loop_indices = [loop_idx]

        # Take the four most influential groups
        # groups = sorted(mesh.vertices[vert_idx].groups, key=lambda group: group.weight, reverse=True)
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
            (self.uvs == other.uvs)
            )

        if eq:
            indices = self.loop_indices + other.loop_indices
            self.loop_indices = indices
            other.loop_indices = indices
        return eq

class ExportVertex:
    __slots__ = ("hash", "vertex_index", "face_index", "position", "normal", "color", "texcoord0", "texcoord1")

    def __init__(self):
        self.color = [1.0, 1.0, 1.0]
        self.texcoord0 = [0.0, 0.0]
        self.texcoord1 = [0.0, 0.0]

    def __eq__(self, v):
        if self.hash != v.hash:
            return False
        if self.position != v.position:
            return False
        if self.normal != v.normal:
            return False
        if self.texcoord0 != v.texcoord0:
            return False
        if self.color != v.color:
            return False
        if self.texcoord1 != v.texcoord1:
            return False
        return True

    def Hash(self):
        h = hash(self.position[0])
        h = h * 21737 + hash(self.position[1])
        h = h * 21737 + hash(self.position[2])
        h = h * 21737 + hash(self.normal[0])
        h = h * 21737 + hash(self.normal[1])
        h = h * 21737 + hash(self.normal[2])
        h = h * 21737 + hash(self.color[0])
        h = h * 21737 + hash(self.color[1])
        h = h * 21737 + hash(self.color[2])
        h = h * 21737 + hash(self.texcoord0[0])
        h = h * 21737 + hash(self.texcoord0[1])
        h = h * 21737 + hash(self.texcoord1[0])
        h = h * 21737 + hash(self.texcoord1[1])
        self.hash = h

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

    def write_vector2d(self, vector):
        return [vector[0], vector[1]]

    def write_vector3d(self, vector):
        return [vector[0], vector[1], vector[2]]

    def write_vertex_array2d(self, vertexArray, attrib):
        va = []
        count = len(vertexArray)
        k = 0

        lineCount = count >> 3
        for i in range(lineCount):
            for j in range(7):
                va += self.write_vector2d(getattr(vertexArray[k], attrib))
                k += 1

            va += self.write_vector2d(getattr(vertexArray[k], attrib))
            k += 1

        count &= 7
        if (count != 0):
            for j in range(count - 1):
                va += self.write_vector2d(getattr(vertexArray[k], attrib))
                k += 1

            va += self.write_vector2d(getattr(vertexArray[k], attrib))

        return va

    def write_vertex_array3d(self, vertex_array, attrib):
        va = []
        count = len(vertex_array)
        k = 0

        lineCount = count >> 3
        for i in range(lineCount):

            for j in range(7):
                va += self.write_vector3d(getattr(vertex_array[k], attrib))
                k += 1

            va += self.write_vector3d(getattr(vertex_array[k], attrib))
            k += 1

        count &= 7
        if count != 0:
            for j in range(count - 1):
                va += self.write_vector3d(getattr(vertex_array[k], attrib))
                k += 1

            va += self.write_vector3d(getattr(vertex_array[k], attrib))

        return va

    def write_triangle(self, triangle_index, index_table):
        i = triangle_index * 3
        return [index_table[i], index_table[i + 1], index_table[i + 2]]

    def write_triangle_array(self, count, index_table):
        va = []
        triangle_index = 0

        line_count = count >> 4
        for i in range(line_count):

            for j in range(15):
                va += self.write_triangle(triangle_index, index_table)
                triangle_index += 1

            va += self.write_triangle(triangle_index, index_table)
            triangle_index += 1

        count &= 15
        if (count != 0):

            for j in range(count - 1):
                va += self.write_triangle(triangle_index, index_table)
                triangle_index += 1

            va += self.write_triangle(triangle_index, index_table)

        return va

    @staticmethod
    def get_shape_keys(mesh):
        if not hasattr(mesh, 'shape_keys'): # Metaball
            return None
        shape_keys = mesh.shape_keys
        if shape_keys and len(shape_keys.key_blocks) > 1:
            return shape_keys
        return None

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

    def calc_tangents(self, posa, nora, uva, ia):
        triangle_count = int(len(ia) / 3)
        vertex_count = int(len(posa) / 3)
        tangents = [0] * vertex_count * 3
        # bitangents = [0] * vertex_count * 3
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

    def write_mesh(self, bobject, fp, o):
        self.output['mesh_datas'].append(o)

    def export_mesh_fast(self, exportMesh, bobject, fp, o):
        # Much faster export but produces slightly less efficient data
        exportMesh.calc_normals_split()
        exportMesh.calc_tessface()
        vert_list = { Vertex(exportMesh, loop) : 0 for loop in exportMesh.loops}.keys()
        num_verts = len(vert_list)
        num_uv_layers = len(exportMesh.uv_layers)
        num_colors = len(exportMesh.vertex_colors)
        vdata = [0] * num_verts * 3
        ndata = [0] * num_verts * 3
        if num_uv_layers > 0:
            t0data = [0] * num_verts * 2
            if num_uv_layers > 1:
                t1data = [0] * num_verts * 2
        if num_colors > 0:
            cdata = [0] * num_verts * 3
        # Make arrays
        for i, vtx in enumerate(vert_list):
            vtx.index = i

            co = vtx.co
            normal = vtx.normal
            for j in range(3):
                vdata[(i * 3) + j] = co[j]
                ndata[(i * 3) + j] = normal[j]
            if num_uv_layers > 0:
                t0data[i * 2] = vtx.uvs[0].x
                t0data[i * 2 + 1] = 1.0 - vtx.uvs[0].y # Reverse TCY
                if num_uv_layers > 1:
                    t1data[i * 2] = vtx.uvs[1].x
                    t1data[i * 2 + 1] = 1.0 - vtx.uvs[1].y
            if num_colors > 0:
                cdata[i * 3] = vtx.col[0]
                cdata[i * 3 + 1] = vtx.col[1]
                cdata[i * 3 + 2] = vtx.col[2]
        # Output
        o['vertex_arrays'] = []
        pa = {}
        pa['attrib'] = "pos"
        pa['size'] = 3
        pa['values'] = vdata
        o['vertex_arrays'].append(pa)
        na = {}
        na['attrib'] = "nor"
        na['size'] = 3
        na['values'] = ndata
        o['vertex_arrays'].append(na)
        
        if num_uv_layers > 0:
            ta = {}
            ta['attrib'] = "tex"
            ta['size'] = 2
            ta['values'] = t0data
            o['vertex_arrays'].append(ta)
            if num_uv_layers > 1:
                ta1 = {}
                ta1['attrib'] = "tex1"
                ta1['size'] = 2
                ta1['values'] = t1data
                o['vertex_arrays'].append(ta1)
        
        if num_colors > 0:
            ca = {}
            ca['attrib'] = "col"
            ca['size'] = 3
            ca['values'] = cdata
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
                mat = exportMesh.materials[poly.material_index]
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
            ia = {}
            ia['size'] = 3
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
        
        # Make tangents
        if num_uv_layers > 0:
            tanga = {}
            tanga['attrib'] = "tangent"
            tanga['size'] = 3
            tanga['values'] = self.calc_tangents(pa['values'], na['values'], ta['values'], o['index_arrays'][0]['values'])  
            o['vertex_arrays'].append(tanga)

        return vert_list

    def do_export_mesh(self, bobject, scene):
        # This function exports a single mesh object
        oid = bobject.data.name
        print('Exporting mesh ' + bobject.data.name)

        o = {}
        mesh = bobject.data
        o['name'] = oid
        structFlag = False;

        # Save the morph state if necessary
        activeShapeKeyIndex = bobject.active_shape_key_index
        showOnlyShapeKey = bobject.show_only_shape_key
        currentMorphValue = []

        shapeKeys = ArmoryExporter.get_shape_keys(mesh)
        if shapeKeys:
            bobject.active_shape_key_index = 0
            bobject.show_only_shape_key = True

            baseIndex = 0
            relative = shapeKeys.use_relative
            if relative:
                morphCount = 0
                baseName = shapeKeys.reference_key.name
                for block in shapeKeys.key_blocks:
                    if block.name == baseName:
                        baseIndex = morphCount
                        break
                    morphCount += 1

            morphCount = 0
            for block in shapeKeys.key_blocks:
                currentMorphValue.append(block.value)
                block.value = 0.0

                if block.name != "":
                    # self.IndentWrite(B"Morph (index = ", 0, structFlag)
                    # self.WriteInt(morphCount)

                    # if ((relative) and (morphCount != baseIndex)):
                    #   self.Write(B", base = ")
                    #   self.WriteInt(baseIndex)

                    # self.Write(B")\n")
                    # self.IndentWrite(B"{\n")
                    # self.IndentWrite(B"Name {string {\"", 1)
                    # self.Write(bytes(block.name, "UTF-8"))
                    # self.Write(B"\"}}\n")
                    # self.IndentWrite(B"}\n")
                    # TODO
                    structFlag = True

                morphCount += 1

            shapeKeys.key_blocks[0].value = 1.0
            mesh.update()

        armature = bobject.find_armature()
        applyModifiers = not armature

        # Apply all modifiers to create a new mesh with tessfaces.

        # We don't apply modifiers for a skinned mesh because we need the vertex positions
        # before they are deformed by the armature modifier in order to export the proper
        # bind pose. This does mean that modifiers preceding the armature modifier are ignored,
        # but the Blender API does not provide a reasonable way to retrieve the mesh at an
        # arbitrary stage in the modifier stack.
        exportMesh = bobject.to_mesh(scene, applyModifiers, "RENDER", True, False)

        if exportMesh == None:
            print('Armory Warning: ' + oid + ' was not exported')
            return

        if len(exportMesh.uv_layers) > 2:
            print('Armory Warning: ' + oid + ' exceeds maximum of 2 UV Maps supported')

        fp = ''
        self.export_mesh_fast(exportMesh, bobject, fp, o)

        # Restore the morph state
        if shapeKeys:
            bobject.active_shape_key_index = activeShapeKeyIndex
            bobject.show_only_shape_key = showOnlyShapeKey

            for m in range(len(currentMorphValue)):
                shapeKeys.key_blocks[m].value = currentMorphValue[m]

            mesh.update()

        self.write_mesh(bobject, fp, o)

    def export_objects(self, scene):
        meshes = []
        self.output['mesh_datas'] = [];
        for o in scene.objects:
            if o.type == 'MESH' and o.data != None and o.data not in meshes:
                meshes.append(o.data)
                self.do_export_mesh(o, scene)

    def write_arm(self, filepath, output):
        # with open(filepath, 'wb') as f:
            # f.write(packb(output))
        with open(filepath, 'w') as f:
                f.write(json.dumps(output, sort_keys=True, indent=4))

    def execute(self, context):
        profile_time = time.time()
        self.output = {}
        self.export_objects(context.scene)
        self.write_arm(self.filepath, self.output)
        print('Scene built in ' + str(time.time() - profile_time))
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
