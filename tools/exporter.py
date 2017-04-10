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
    __slots__ = ("co", "normal", "uvs", "col", "loop_indices", "index", "bone_weights", "bone_indices", "bone_count", "vertexIndex")
    def __init__(self, mesh, loop):
        self.vertexIndex = loop.vertex_index
        i = loop.index
        self.co = mesh.vertices[self.vertexIndex].co.freeze()
        self.normal = loop.normal.freeze()
        self.uvs = tuple(layer.data[i].uv.freeze() for layer in mesh.uv_layers)
        self.col = [0, 0, 0]
        if len(mesh.vertex_colors) > 0:
            self.col = mesh.vertex_colors[0].data[i].color.freeze()
        self.loop_indices = [i]

        # Take the four most influential groups
        # groups = sorted(mesh.vertices[self.vertexIndex].groups, key=lambda group: group.weight, reverse=True)
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
    __slots__ = ("hash", "vertexIndex", "faceIndex", "position", "normal", "color", "texcoord0", "texcoord1")

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

    def export_mesh_fast(self, exportMesh, bobject, fp, o, om):
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
        om['vertex_arrays'] = []
        pa = {}
        pa['attrib'] = "position"
        pa['size'] = 3
        pa['values'] = vdata
        om['vertex_arrays'].append(pa)
        na = {}
        na['attrib'] = "normal"
        na['size'] = 3
        na['values'] = ndata
        om['vertex_arrays'].append(na)
        
        if num_uv_layers > 0:
            ta = {}
            ta['attrib'] = "texcoord"
            ta['size'] = 2
            ta['values'] = t0data
            om['vertex_arrays'].append(ta)
            if num_uv_layers > 1:
                ta1 = {}
                ta1['attrib'] = "texcoord1"
                ta1['size'] = 2
                ta1['values'] = t1data
                om['vertex_arrays'].append(ta1)
        
        if num_colors > 0:
            ca = {}
            ca['attrib'] = "color"
            ca['size'] = 3
            ca['values'] = cdata
            om['vertex_arrays'].append(ca)
        
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
        om['index_arrays'] = []
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
            om['index_arrays'].append(ia)
        
        # Make tangents
        if num_uv_layers > 0:
            tanga = {}
            tanga['attrib'] = "tangent"
            tanga['size'] = 3
            tanga['values'] = self.calc_tangents(pa['values'], na['values'], ta['values'], om['index_arrays'][0]['values'])  
            om['vertex_arrays'].append(tanga)

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

        om = {}
        # Triangles is default
        # om['primitive'] = "triangles"

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
        self.export_mesh_fast(exportMesh, bobject, fp, o, om)

        # Restore the morph state
        if shapeKeys:
            bobject.active_shape_key_index = activeShapeKeyIndex
            bobject.show_only_shape_key = showOnlyShapeKey

            for m in range(len(currentMorphValue)):
                shapeKeys.key_blocks[m].value = currentMorphValue[m]

            mesh.update()

        o['mesh'] = om
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
            # f.write(dumps(output))
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


# u-msgpack-python v2.1 - vsergeev at gmail
# https://github.com/vsergeev/u-msgpack-python
#
# u-msgpack-python is a lightweight MessagePack serializer and deserializer
# module, compatible with both Python 2 and 3, as well CPython and PyPy
# implementations of Python. u-msgpack-python is fully compliant with the
# latest MessagePack specification.com/msgpack/msgpack/blob/master/spec.md). In
# particular, it supports the new binary, UTF-8 string, and application ext
# types.
#
# MIT License
#
# Copyright (c) 2013-2014 Ivan A. Sergeev
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
"""
u-msgpack-python v2.1 - vsergeev at gmail
https://github.com/vsergeev/u-msgpack-python

u-msgpack-python is a lightweight MessagePack serializer and deserializer
module, compatible with both Python 2 and 3, as well CPython and PyPy
implementations of Python. u-msgpack-python is fully compliant with the
latest MessagePack specification.com/msgpack/msgpack/blob/master/spec.md). In
particular, it supports the new binary, UTF-8 string, and application ext
types.

License: MIT
"""

__version__ = "2.1"
"Module version string"

version = (2,1)
"Module version tuple"

import struct
import collections
import sys
import io

################################################################################
### Ext Class
################################################################################

# Extension type for application-defined types and data
class Ext:
    """
    The Ext class facilitates creating a serializable extension object to store
    an application-defined type and data byte array.
    """

    def __init__(self, type, data):
        """
        Construct a new Ext object.

        Args:
            type: application-defined type integer from 0 to 127
            data: application-defined data byte array

        Raises:
            TypeError:
                Specified ext type is outside of 0 to 127 range.

        Example:
        >>> foo = umsgpack.Ext(0x05, b"\x01\x02\x03")
        >>> umsgpack.packb({u"special stuff": foo, u"awesome": True})
        '\x82\xa7awesome\xc3\xadspecial stuff\xc7\x03\x05\x01\x02\x03'
        >>> bar = umsgpack.unpackb(_)
        >>> print(bar["special stuff"])
        Ext Object (Type: 0x05, Data: 01 02 03)
        >>>
        """
        # Application ext type should be 0 <= type <= 127
        if not isinstance(type, int) or not (type >= 0 and type <= 127):
            raise TypeError("ext type out of range")
        # Check data is type bytes
        elif sys.version_info[0] == 3 and not isinstance(data, bytes):
            raise TypeError("ext data is not type \'bytes\'")
        elif sys.version_info[0] == 2 and not isinstance(data, str):
            raise TypeError("ext data is not type \'str\'")
        self.type = type
        self.data = data

    def __eq__(self, other):
        """
        Compare this Ext object with another for equality.
        """
        return (isinstance(other, self.__class__) and
                self.type == other.type and
                self.data == other.data)

    def __ne__(self, other):
        """
        Compare this Ext object with another for inequality.
        """
        return not self.__eq__(other)

    def __str__(self):
        """
        String representation of this Ext object.
        """
        s = "Ext Object (Type: 0x%02x, Data: " % self.type
        for i in range(min(len(self.data), 8)):
            if i > 0:
                s += " "
            if isinstance(self.data[i], int):
                s += "%02x" % (self.data[i])
            else:
                s += "%02x" % ord(self.data[i])
        if len(self.data) > 8:
            s += " ..."
        s += ")"
        return s

################################################################################
### Exceptions
################################################################################

# Base Exception classes
class PackException(Exception):
    "Base class for exceptions encountered during packing."
    pass
class UnpackException(Exception):
    "Base class for exceptions encountered during unpacking."
    pass

# Packing error
class UnsupportedTypeException(PackException):
    "Object type not supported for packing."
    pass

# Unpacking error
class InsufficientDataException(UnpackException):
    "Insufficient data to unpack the encoded object."
    pass
class InvalidStringException(UnpackException):
    "Invalid UTF-8 string encountered during unpacking."
    pass
class ReservedCodeException(UnpackException):
    "Reserved code encountered during unpacking."
    pass
class UnhashableKeyException(UnpackException):
    """
    Unhashable key encountered during map unpacking.
    The serialized map cannot be deserialized into a Python dictionary.
    """
    pass
class DuplicateKeyException(UnpackException):
    "Duplicate key encountered during map unpacking."
    pass

# Backwards compatibility
KeyNotPrimitiveException = UnhashableKeyException
KeyDuplicateException = DuplicateKeyException

################################################################################
### Exported Functions and Globals
################################################################################

# Exported functions and variables, set up in __init()
pack = None
packb = None
unpack = None
unpackb = None
dump = None
dumps = None
load = None
loads = None

compatibility = False
"""
Compatibility mode boolean.

When compatibility mode is enabled, u-msgpack-python will serialize both
unicode strings and bytes into the old "raw" msgpack type, and deserialize the
"raw" msgpack type into bytes. This provides backwards compatibility with the
old MessagePack specification.

Example:
>>> umsgpack.compatibility = True
>>>
>>> umsgpack.packb([u"some string", b"some bytes"])
b'\x92\xabsome string\xaasome bytes'
>>> umsgpack.unpackb(_)
[b'some string', b'some bytes']
>>>
"""

################################################################################
### Packing
################################################################################

# You may notice struct.pack("B", obj) instead of the simpler chr(obj) in the
# code below. This is to allow for seamless Python 2 and 3 compatibility, as
# chr(obj) has a str return type instead of bytes in Python 3, and
# struct.pack(...) has the right return type in both versions.

def _pack_integer(obj, fp):
    if obj < 0:
        if obj >= -32:
            fp.write(struct.pack("b", obj))
        elif obj >= -2**(8-1):
            fp.write(b"\xd0" + struct.pack("b", obj))
        elif obj >= -2**(16-1):
            fp.write(b"\xd1" + struct.pack(">h", obj))
        elif obj >= -2**(32-1):
            fp.write(b"\xd2" + struct.pack(">i", obj))
        elif obj >= -2**(64-1):
            fp.write(b"\xd3" + struct.pack(">q", obj))
        else:
            raise UnsupportedTypeException("huge signed int")
    else:
        if obj <= 127:
            fp.write(struct.pack("B", obj))
        elif obj <= 2**8-1:
            fp.write(b"\xcc" + struct.pack("B", obj))
        elif obj <= 2**16-1:
            fp.write(b"\xcd" + struct.pack(">H", obj))
        elif obj <= 2**32-1:
            fp.write(b"\xce" + struct.pack(">I", obj))
        elif obj <= 2**64-1:
            fp.write(b"\xcf" + struct.pack(">Q", obj))
        else:
            raise UnsupportedTypeException("huge unsigned int")

def _pack_nil(obj, fp):
    fp.write(b"\xc0")

def _pack_boolean(obj, fp):
    fp.write(b"\xc3" if obj else b"\xc2")

def _pack_float(obj, fp):
    if _float_size == 64:
        fp.write(b"\xcb" + struct.pack(">d", obj))
    else:
        fp.write(b"\xca" + struct.pack(">f", obj))

def _pack_string(obj, fp):
    obj = obj.encode('utf-8')
    if len(obj) <= 31:
        fp.write(struct.pack("B", 0xa0 | len(obj)) + obj)
    elif len(obj) <= 2**8-1:
        fp.write(b"\xd9" + struct.pack("B", len(obj)) + obj)
    elif len(obj) <= 2**16-1:
        fp.write(b"\xda" + struct.pack(">H", len(obj)) + obj)
    elif len(obj) <= 2**32-1:
        fp.write(b"\xdb" + struct.pack(">I", len(obj)) + obj)
    else:
        raise UnsupportedTypeException("huge string")

def _pack_binary(obj, fp):
    if len(obj) <= 2**8-1:
        fp.write(b"\xc4" + struct.pack("B", len(obj)) + obj)
    elif len(obj) <= 2**16-1:
        fp.write(b"\xc5" + struct.pack(">H", len(obj)) + obj)
    elif len(obj) <= 2**32-1:
        fp.write(b"\xc6" + struct.pack(">I", len(obj)) + obj)
    else:
        raise UnsupportedTypeException("huge binary string")

def _pack_oldspec_raw(obj, fp):
    if len(obj) <= 31:
        fp.write(struct.pack("B", 0xa0 | len(obj)) + obj)
    elif len(obj) <= 2**16-1:
        fp.write(b"\xda" + struct.pack(">H", len(obj)) + obj)
    elif len(obj) <= 2**32-1:
        fp.write(b"\xdb" + struct.pack(">I", len(obj)) + obj)
    else:
        raise UnsupportedTypeException("huge raw string")

def _pack_ext(obj, fp):
    if len(obj.data) == 1:
        fp.write(b"\xd4" + struct.pack("B", obj.type & 0xff) + obj.data)
    elif len(obj.data) == 2:
        fp.write(b"\xd5" + struct.pack("B", obj.type & 0xff) + obj.data)
    elif len(obj.data) == 4:
        fp.write(b"\xd6" + struct.pack("B", obj.type & 0xff) + obj.data)
    elif len(obj.data) == 8:
        fp.write(b"\xd7" + struct.pack("B", obj.type & 0xff) + obj.data)
    elif len(obj.data) == 16:
        fp.write(b"\xd8" + struct.pack("B", obj.type & 0xff) + obj.data)
    elif len(obj.data) <= 2**8-1:
        fp.write(b"\xc7" + struct.pack("BB", len(obj.data), obj.type & 0xff) + obj.data)
    elif len(obj.data) <= 2**16-1:
        fp.write(b"\xc8" + struct.pack(">HB", len(obj.data), obj.type & 0xff) + obj.data)
    elif len(obj.data) <= 2**32-1:
        fp.write(b"\xc9" + struct.pack(">IB", len(obj.data), obj.type & 0xff) + obj.data)
    else:
        raise UnsupportedTypeException("huge ext data")

def _pack_array(obj, fp):
    if len(obj) <= 15:
        fp.write(struct.pack("B", 0x90 | len(obj)))
    elif len(obj) <= 2**16-1:
        fp.write(b"\xdc" + struct.pack(">H", len(obj)))
    elif len(obj) <= 2**32-1:
        fp.write(b"\xdd" + struct.pack(">I", len(obj)))
    else:
        raise UnsupportedTypeException("huge array")

    for e in obj:
        pack(e, fp)

def _pack_map(obj, fp):
    if len(obj) <= 15:
        fp.write(struct.pack("B", 0x80 | len(obj)))
    elif len(obj) <= 2**16-1:
        fp.write(b"\xde" + struct.pack(">H", len(obj)))
    elif len(obj) <= 2**32-1:
        fp.write(b"\xdf" + struct.pack(">I", len(obj)))
    else:
        raise UnsupportedTypeException("huge array")

    for k,v in obj.items():
        pack(k, fp)
        pack(v, fp)

########################################

# Pack for Python 2, with 'unicode' type, 'str' type, and 'long' type
def _pack2(obj, fp):
    """
    Serialize a Python object into MessagePack bytes.

    Args:
        obj: a Python object
        fp: a .write()-supporting file-like object

    Returns:
        None.

    Raises:
        UnsupportedType(PackException):
            Object type not supported for packing.

    Example:
    >>> f = open('test.bin', 'wb')
    >>> umsgpack.pack({u"compact": True, u"schema": 0}, f)
    >>>
    """

    global compatibility

    if obj is None:
        _pack_nil(obj, fp)
    elif isinstance(obj, bool):
        _pack_boolean(obj, fp)
    elif isinstance(obj, int) or isinstance(obj, long):
        _pack_integer(obj, fp)
    elif isinstance(obj, float):
        _pack_float(obj, fp)
    elif compatibility and isinstance(obj, unicode):
        _pack_oldspec_raw(bytes(obj), fp)
    elif compatibility and isinstance(obj, bytes):
        _pack_oldspec_raw(obj, fp)
    elif isinstance(obj, unicode):
        _pack_string(obj, fp)
    elif isinstance(obj, str):
        _pack_binary(obj, fp)
    elif isinstance(obj, list) or isinstance(obj, tuple):
        _pack_array(obj, fp)
    elif isinstance(obj, dict):
        _pack_map(obj, fp)
    elif isinstance(obj, Ext):
        _pack_ext(obj, fp)
    else:
        raise UnsupportedTypeException("unsupported type: %s" % str(type(obj)))

# Pack for Python 3, with unicode 'str' type, 'bytes' type, and no 'long' type
def _pack3(obj, fp):
    """
    Serialize a Python object into MessagePack bytes.

    Args:
        obj: a Python object
        fp: a .write()-supporting file-like object

    Returns:
        None.

    Raises:
        UnsupportedType(PackException):
            Object type not supported for packing.

    Example:
    >>> f = open('test.bin', 'wb')
    >>> umsgpack.pack({u"compact": True, u"schema": 0}, f)
    >>>
    """
    global compatibility

    if obj is None:
        _pack_nil(obj, fp)
    elif isinstance(obj, bool):
        _pack_boolean(obj, fp)
    elif isinstance(obj, int):
        _pack_integer(obj, fp)
    elif isinstance(obj, float):
        _pack_float(obj, fp)
    elif compatibility and isinstance(obj, str):
        _pack_oldspec_raw(obj.encode('utf-8'), fp)
    elif compatibility and isinstance(obj, bytes):
        _pack_oldspec_raw(obj, fp)
    elif isinstance(obj, str):
        _pack_string(obj, fp)
    elif isinstance(obj, bytes):
        _pack_binary(obj, fp)
    elif isinstance(obj, list) or isinstance(obj, tuple):
        _pack_array(obj, fp)
    elif isinstance(obj, dict):
        _pack_map(obj, fp)
    elif isinstance(obj, Ext):
        _pack_ext(obj, fp)
    else:
        raise UnsupportedTypeException("unsupported type: %s" % str(type(obj)))

def _packb2(obj):
    """
    Serialize a Python object into MessagePack bytes.

    Args:
        obj: a Python object

    Returns:
        A 'str' containing serialized MessagePack bytes.

    Raises:
        UnsupportedType(PackException):
            Object type not supported for packing.

    Example:
    >>> umsgpack.packb({u"compact": True, u"schema": 0})
    '\x82\xa7compact\xc3\xa6schema\x00'
    >>>
    """
    fp = io.BytesIO()
    _pack2(obj, fp)
    return fp.getvalue()

def _packb3(obj):
    """
    Serialize a Python object into MessagePack bytes.

    Args:
        obj: a Python object

    Returns:
        A 'bytes' containing serialized MessagePack bytes.

    Raises:
        UnsupportedType(PackException):
            Object type not supported for packing.

    Example:
    >>> umsgpack.packb({u"compact": True, u"schema": 0})
    b'\x82\xa7compact\xc3\xa6schema\x00'
    >>>
    """
    fp = io.BytesIO()
    _pack3(obj, fp)
    return fp.getvalue()

################################################################################
### Unpacking
################################################################################

def _read_except(fp, n):
    data = fp.read(n)
    if len(data) < n:
        raise InsufficientDataException()
    return data

def _unpack_integer(code, fp):
    if (ord(code) & 0xe0) == 0xe0:
        return struct.unpack("b", code)[0]
    elif code == b'\xd0':
        return struct.unpack("b", _read_except(fp, 1))[0]
    elif code == b'\xd1':
        return struct.unpack(">h", _read_except(fp, 2))[0]
    elif code == b'\xd2':
        return struct.unpack(">i", _read_except(fp, 4))[0]
    elif code == b'\xd3':
        return struct.unpack(">q", _read_except(fp, 8))[0]
    elif (ord(code) & 0x80) == 0x00:
        return struct.unpack("B", code)[0]
    elif code == b'\xcc':
        return struct.unpack("B", _read_except(fp, 1))[0]
    elif code == b'\xcd':
        return struct.unpack(">H", _read_except(fp, 2))[0]
    elif code == b'\xce':
        return struct.unpack(">I", _read_except(fp, 4))[0]
    elif code == b'\xcf':
        return struct.unpack(">Q", _read_except(fp, 8))[0]
    raise Exception("logic error, not int: 0x%02x" % ord(code))

def _unpack_reserved(code, fp):
    if code == b'\xc1':
        raise ReservedCodeException("encountered reserved code: 0x%02x" % ord(code))
    raise Exception("logic error, not reserved code: 0x%02x" % ord(code))

def _unpack_nil(code, fp):
    if code == b'\xc0':
        return None
    raise Exception("logic error, not nil: 0x%02x" % ord(code))

def _unpack_boolean(code, fp):
    if code == b'\xc2':
        return False
    elif code == b'\xc3':
        return True
    raise Exception("logic error, not boolean: 0x%02x" % ord(code))

def _unpack_float(code, fp):
    if code == b'\xca':
        return struct.unpack(">f", _read_except(fp, 4))[0]
    elif code == b'\xcb':
        return struct.unpack(">d", _read_except(fp, 8))[0]
    raise Exception("logic error, not float: 0x%02x" % ord(code))

def _unpack_string(code, fp):
    if (ord(code) & 0xe0) == 0xa0:
        length = ord(code) & ~0xe0
    elif code == b'\xd9':
        length = struct.unpack("B", _read_except(fp, 1))[0]
    elif code == b'\xda':
        length = struct.unpack(">H", _read_except(fp, 2))[0]
    elif code == b'\xdb':
        length = struct.unpack(">I", _read_except(fp, 4))[0]
    else:
        raise Exception("logic error, not string: 0x%02x" % ord(code))

    # Always return raw bytes in compatibility mode
    global compatibility
    if compatibility:
        return _read_except(fp, length)

    try:
        return bytes.decode(_read_except(fp, length), 'utf-8')
    except UnicodeDecodeError:
        raise InvalidStringException("unpacked string is not utf-8")

def _unpack_binary(code, fp):
    if code == b'\xc4':
        length = struct.unpack("B", _read_except(fp, 1))[0]
    elif code == b'\xc5':
        length = struct.unpack(">H", _read_except(fp, 2))[0]
    elif code == b'\xc6':
        length = struct.unpack(">I", _read_except(fp, 4))[0]
    else:
        raise Exception("logic error, not binary: 0x%02x" % ord(code))

    return _read_except(fp, length)

def _unpack_ext(code, fp):
    if code == b'\xd4':
        length = 1
    elif code == b'\xd5':
        length = 2
    elif code == b'\xd6':
        length = 4
    elif code == b'\xd7':
        length = 8
    elif code == b'\xd8':
        length = 16
    elif code == b'\xc7':
        length = struct.unpack("B", _read_except(fp, 1))[0]
    elif code == b'\xc8':
        length = struct.unpack(">H", _read_except(fp, 2))[0]
    elif code == b'\xc9':
        length = struct.unpack(">I", _read_except(fp, 4))[0]
    else:
        raise Exception("logic error, not ext: 0x%02x" % ord(code))

    return Ext(ord(_read_except(fp, 1)), _read_except(fp, length))

def _unpack_array(code, fp):
    if (ord(code) & 0xf0) == 0x90:
        length = (ord(code) & ~0xf0)
    elif code == b'\xdc':
        length = struct.unpack(">H", _read_except(fp, 2))[0]
    elif code == b'\xdd':
        length = struct.unpack(">I", _read_except(fp, 4))[0]
    else:
        raise Exception("logic error, not array: 0x%02x" % ord(code))

    return [_unpack(fp) for i in xrange(length)]

def _deep_list_to_tuple(obj):
    if isinstance(obj, list):
        return tuple([_deep_list_to_tuple(e) for e in obj])
    return obj

def _unpack_map(code, fp):
    if (ord(code) & 0xf0) == 0x80:
        length = (ord(code) & ~0xf0)
    elif code == b'\xde':
        length = struct.unpack(">H", _read_except(fp, 2))[0]
    elif code == b'\xdf':
        length = struct.unpack(">I", _read_except(fp, 4))[0]
    else:
        raise Exception("logic error, not map: 0x%02x" % ord(code))

    d = {}
    for i in xrange(length):
        # Unpack key
        k = _unpack(fp)

        if isinstance(k, list):
            # Attempt to convert list into a hashable tuple
            k = _deep_list_to_tuple(k)
        elif not isinstance(k, collections.Hashable):
            raise UnhashableKeyException("encountered unhashable key: %s, %s" % (str(k), str(type(k))))
        elif k in d:
            raise DuplicateKeyException("encountered duplicate key: %s, %s" % (str(k), str(type(k))))

        # Unpack value
        v = _unpack(fp)

        try:
            d[k] = v
        except TypeError:
            raise UnhashableKeyException("encountered unhashable key: %s" % str(k))
    return d

def _unpack(fp):
    code = _read_except(fp, 1)
    return _unpack_dispatch_table[code](code, fp)

########################################

def _unpack2(fp):
    """
    Deserialize MessagePack bytes into a Python object.

    Args:
        fp: a .read()-supporting file-like object

    Returns:
        A Python object.

    Raises:
        InsufficientDataException(UnpackException):
            Insufficient data to unpack the encoded object.
        InvalidStringException(UnpackException):
            Invalid UTF-8 string encountered during unpacking.
        ReservedCodeException(UnpackException):
            Reserved code encountered during unpacking.
        UnhashableKeyException(UnpackException):
            Unhashable key encountered during map unpacking.
            The serialized map cannot be deserialized into a Python dictionary.
        DuplicateKeyException(UnpackException):
            Duplicate key encountered during map unpacking.

    Example:
    >>> f = open('test.bin', 'rb')
    >>> umsgpack.unpackb(f)
    {u'compact': True, u'schema': 0}
    >>>
    """
    return _unpack(fp)

def _unpack3(fp):
    """
    Deserialize MessagePack bytes into a Python object.

    Args:
        fp: a .read()-supporting file-like object

    Returns:
        A Python object.

    Raises:
        InsufficientDataException(UnpackException):
            Insufficient data to unpack the encoded object.
        InvalidStringException(UnpackException):
            Invalid UTF-8 string encountered during unpacking.
        ReservedCodeException(UnpackException):
            Reserved code encountered during unpacking.
        UnhashableKeyException(UnpackException):
            Unhashable key encountered during map unpacking.
            The serialized map cannot be deserialized into a Python dictionary.
        DuplicateKeyException(UnpackException):
            Duplicate key encountered during map unpacking.

    Example:
    >>> f = open('test.bin', 'rb')
    >>> umsgpack.unpackb(f)
    {'compact': True, 'schema': 0}
    >>>
    """
    return _unpack(fp)

# For Python 2, expects a str object
def _unpackb2(s):
    """
    Deserialize MessagePack bytes into a Python object.

    Args:
        s: a 'str' containing serialized MessagePack bytes

    Returns:
        A Python object.

    Raises:
        TypeError:
            Packed data is not type 'str'.
        InsufficientDataException(UnpackException):
            Insufficient data to unpack the encoded object.
        InvalidStringException(UnpackException):
            Invalid UTF-8 string encountered during unpacking.
        ReservedCodeException(UnpackException):
            Reserved code encountered during unpacking.
        UnhashableKeyException(UnpackException):
            Unhashable key encountered during map unpacking.
            The serialized map cannot be deserialized into a Python dictionary.
        DuplicateKeyException(UnpackException):
            Duplicate key encountered during map unpacking.

    Example:
    >>> umsgpack.unpackb(b'\x82\xa7compact\xc3\xa6schema\x00')
    {u'compact': True, u'schema': 0}
    >>>
    """
    if not isinstance(s, str):
        raise TypeError("packed data is not type 'str'")
    return _unpack(io.BytesIO(s))

# For Python 3, expects a bytes object
def _unpackb3(s):
    """
    Deserialize MessagePack bytes into a Python object.

    Args:
        s: a 'bytes' containing serialized MessagePack bytes

    Returns:
        A Python object.

    Raises:
        TypeError:
            Packed data is not type 'bytes'.
        InsufficientDataException(UnpackException):
            Insufficient data to unpack the encoded object.
        InvalidStringException(UnpackException):
            Invalid UTF-8 string encountered during unpacking.
        ReservedCodeException(UnpackException):
            Reserved code encountered during unpacking.
        UnhashableKeyException(UnpackException):
            Unhashable key encountered during map unpacking.
            The serialized map cannot be deserialized into a Python dictionary.
        DuplicateKeyException(UnpackException):
            Duplicate key encountered during map unpacking.

    Example:
    >>> umsgpack.unpackb(b'\x82\xa7compact\xc3\xa6schema\x00')
    {'compact': True, 'schema': 0}
    >>>
    """
    if not isinstance(s, bytes):
        raise TypeError("packed data is not type 'bytes'")
    return _unpack(io.BytesIO(s))

################################################################################
### Module Initialization
################################################################################

def __init():
    global pack
    global packb
    global unpack
    global unpackb
    global dump
    global dumps
    global load
    global loads
    global compatibility
    global _float_size
    global _unpack_dispatch_table
    global xrange

    # Compatibility mode for handling strings/bytes with the old specification
    compatibility = False

    # Auto-detect system float precision
    if sys.float_info.mant_dig == 53:
        _float_size = 64
    else:
        _float_size = 32

    # Map packb and unpackb to the appropriate version
    if sys.version_info[0] == 3:
        pack = _pack3
        packb = _packb3
        dump = _pack3
        dumps = _packb3
        unpack = _unpack3
        unpackb = _unpackb3
        load = _unpack3
        loads = _unpackb3
        xrange = range
    else:
        pack = _pack2
        packb = _packb2
        dump = _pack2
        dumps = _packb2
        unpack = _unpack2
        unpackb = _unpackb2
        load = _unpack2
        loads = _unpackb2

    # Build a dispatch table for fast lookup of unpacking function

    _unpack_dispatch_table = {}
    # Fix uint
    for code in range(0, 0x7f+1):
        _unpack_dispatch_table[struct.pack("B", code)] = _unpack_integer
    # Fix map
    for code in range(0x80, 0x8f+1):
        _unpack_dispatch_table[struct.pack("B", code)] = _unpack_map
    # Fix array
    for code in range(0x90, 0x9f+1):
        _unpack_dispatch_table[struct.pack("B", code)] = _unpack_array
    # Fix str
    for code in range(0xa0, 0xbf+1):
        _unpack_dispatch_table[struct.pack("B", code)] = _unpack_string
    # Nil
    _unpack_dispatch_table[b'\xc0'] = _unpack_nil
    # Reserved
    _unpack_dispatch_table[b'\xc1'] = _unpack_reserved
    # Boolean
    _unpack_dispatch_table[b'\xc2'] = _unpack_boolean
    _unpack_dispatch_table[b'\xc3'] = _unpack_boolean
    # Bin
    for code in range(0xc4, 0xc6+1):
        _unpack_dispatch_table[struct.pack("B", code)] = _unpack_binary
    # Ext
    for code in range(0xc7, 0xc9+1):
        _unpack_dispatch_table[struct.pack("B", code)] = _unpack_ext
    # Float
    _unpack_dispatch_table[b'\xca'] = _unpack_float
    _unpack_dispatch_table[b'\xcb'] = _unpack_float
    # Uint
    for code in range(0xcc, 0xcf+1):
        _unpack_dispatch_table[struct.pack("B", code)] = _unpack_integer
    # Int
    for code in range(0xd0, 0xd3+1):
        _unpack_dispatch_table[struct.pack("B", code)] = _unpack_integer
    # Fixext
    for code in range(0xd4, 0xd8+1):
        _unpack_dispatch_table[struct.pack("B", code)] = _unpack_ext
    # String
    for code in range(0xd9, 0xdb+1):
        _unpack_dispatch_table[struct.pack("B", code)] = _unpack_string
    # Array
    _unpack_dispatch_table[b'\xdc'] = _unpack_array
    _unpack_dispatch_table[b'\xdd'] = _unpack_array
    # Map
    _unpack_dispatch_table[b'\xde'] = _unpack_map
    _unpack_dispatch_table[b'\xdf'] = _unpack_map
    # Negative fixint
    for code in range(0xe0, 0xff+1):
        _unpack_dispatch_table[struct.pack("B", code)] = _unpack_integer

__init()
