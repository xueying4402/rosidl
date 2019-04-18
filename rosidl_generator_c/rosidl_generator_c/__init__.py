# Copyright 2015 Open Source Robotics Foundation, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from rosidl_cmake import convert_camel_case_to_lower_case_underscore
from rosidl_cmake import generate_files
from rosidl_parser.definition import AbstractGenericString
from rosidl_parser.definition import AbstractSequence
from rosidl_parser.definition import AbstractString
from rosidl_parser.definition import AbstractType
from rosidl_parser.definition import AbstractWString
from rosidl_parser.definition import Array
from rosidl_parser.definition import BasicType
from rosidl_parser.definition import NamespacedType


def generate_c(generator_arguments_file):
    mapping = {
        'idl.h.em': '%s.h',
        'idl__functions.c.em': '%s__functions.c',
        'idl__functions.h.em': '%s__functions.h',
        'idl__struct.h.em': '%s__struct.h',
        'idl__type_support.h.em': '%s__type_support.h',
    }
    generate_files(generator_arguments_file, mapping)


BASIC_IDL_TYPES_TO_C = {
    'float': 'float',
    'double': 'double',
    'long double': 'long double',
    'char': 'signed char',
    'wchar': 'uint16_t',
    'boolean': 'bool',
    'octet': 'uint8_t',
    'uint8': 'uint8_t',
    'int8': 'int8_t',
    'uint16': 'uint16_t',
    'int16': 'int16_t',
    'uint32': 'uint32_t',
    'int32': 'int32_t',
    'uint64': 'uint64_t',
    'int64': 'int64_t',
}


def idl_structure_type_to_c_include_prefix(namespaced_type):
    return '/'.join(
        convert_camel_case_to_lower_case_underscore(x)
        for x in (namespaced_type.namespaces + [namespaced_type.name]))


def idl_structure_type_to_c_typename(namespaced_type):
    return '__'.join(namespaced_type.namespaces + [namespaced_type.name])


def idl_structure_type_sequence_to_c_typename(namespaced_type):
    return idl_structure_type_to_c_typename(namespaced_type) + '__Sequence'


def interface_path_to_string(interface_path):
    return '/'.join(
        list(interface_path.parents[0].parts) + [interface_path.stem])


def idl_declaration_to_c(type_, name):
    """
    Convert an IDL type into the C declaration.

    Example input: uint32, std_msgs/String
    Example output: uint32_t, char *

    @param type_: The message type
    @type type_: rosidl_parser.Type
    @param type_: The member name
    @type type_: str
    """
    if isinstance(type_, AbstractGenericString):
        return basetype_to_c(type_) + ' ' + name
    if isinstance(type_, Array):
        return basetype_to_c(type_.value_type) + ' ' + name + '[' + str(type_.size) + ']'
    return idl_type_to_c(type_) + ' ' + name


def idl_type_to_c(type_):
    if isinstance(type_, Array):
        assert False, 'The array size is part of the variable'
    if isinstance(type_, AbstractSequence):
        if isinstance(type_.value_type, BasicType):
            c_type = 'rosidl_generator_c__' + type_.value_type.typename.replace(' ', '_')
        else:
            c_type = basetype_to_c(type_.value_type)
        c_type += '__Sequence'
        return c_type
    return basetype_to_c(type_)


def basetype_to_c(basetype):
    if isinstance(basetype, BasicType):
        return BASIC_IDL_TYPES_TO_C[basetype.typename]
    if isinstance(basetype, AbstractString):
        return 'rosidl_generator_c__String'
    if isinstance(basetype, AbstractWString):
        return 'rosidl_generator_c__U16String'
    if isinstance(basetype, NamespacedType):
        return idl_structure_type_to_c_typename(basetype)
    assert False, str(basetype)


def value_to_c(type_, value):
    assert isinstance(type_, AbstractType)
    assert value is not None

    if isinstance(type_, AbstractString):
        return '"%s"' % escape_string(value)

    return basic_value_to_c(type_, value)


def basic_value_to_c(type_, value):
    assert isinstance(type_, BasicType)
    assert value is not None

    if 'boolean' == type_.typename:
        return 'true' if value else 'false'

    if type_.typename in (
        'short', 'long', 'long long',
        'char', 'wchar', 'octet',
        'int8', 'int16', 'int32', 'int64',
    ):
        return str(value)

    if type_.typename in (
        'unsigned short', 'unsigned long', 'unsigned long long',
        'uint8', 'uint16', 'uint32', 'uint64',
    ):
        return str(value) + 'u'

    if 'float' == type_.typename:
        return '{value}f'.format_map(locals())

    if 'double' == type_.typename:
        return '{value}l'.format_map(locals())

    assert False, "unknown basic type '%s'" % type_


def escape_string(s):
    s = s.replace('\\', '\\\\')
    s = s.replace('"', r'\"')
    return s
