@# Included from rosidl_generator_c/resource/idl__struct.h.em
@{
from rosidl_parser.definition import AbstractGenericString
from rosidl_parser.definition import AbstractNestedType
from rosidl_parser.definition import AbstractSequence
from rosidl_parser.definition import AbstractString
from rosidl_parser.definition import AbstractWString
from rosidl_parser.definition import BasicType
from rosidl_parser.definition import BoundedSequence
from rosidl_parser.definition import NamespacedType
from rosidl_generator_c import basetype_to_c
from rosidl_generator_c import idl_declaration_to_c
from rosidl_generator_c import idl_structure_type_sequence_to_c_typename
from rosidl_generator_c import idl_structure_type_to_c_include_prefix
from rosidl_generator_c import idl_structure_type_to_c_typename
from rosidl_generator_c import interface_path_to_string
from rosidl_generator_c import value_to_c
}@
@#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
@# Collect necessary include directives for all members
@{
from collections import OrderedDict
includes = OrderedDict()
for member in message.structure.members:
    if isinstance(member.type, AbstractSequence) and isinstance(member.type.value_type, BasicType):
        member_names = includes.setdefault(
            'rosidl_generator_c/primitives_sequence.h', [])
        member_names.append(member.name)
        continue
    type_ = member.type
    if isinstance(type_, AbstractNestedType):
        type_ = type_.value_type
    if isinstance(type_, AbstractString):
        member_names = includes.setdefault('rosidl_generator_c/string.h', [])
        member_names.append(member.name)
    elif isinstance(type_, AbstractWString):
        member_names = includes.setdefault(
            'rosidl_generator_c/u16string.h', [])
        member_names.append(member.name)
    elif isinstance(type_, NamespacedType):
        include_prefix = idl_structure_type_to_c_include_prefix(type_)
        if include_prefix.endswith('__request'):
            include_prefix = include_prefix[:-9]
        elif include_prefix.endswith('__response'):
            include_prefix = include_prefix[:-10]
        if include_prefix.endswith('__goal'):
            include_prefix = include_prefix[:-6]
        elif include_prefix.endswith('__result'):
            include_prefix = include_prefix[:-8]
        elif include_prefix.endswith('__feedback'):
            include_prefix = include_prefix[:-10]
        member_names = includes.setdefault(
            include_prefix + '__struct.h', [])
        member_names.append(member.name)
}@
@#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

@#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// Constants defined in the message
@[for constant in message.constants]@

/// Constant '@(constant.name)'.
@[    if isinstance(constant.type, BasicType)]@
@[        if constant.type.typename in (
              'short', 'unsigned short', 'long', 'unsigned long', 'long long', 'unsigned long long',
              'char', 'wchar', 'octet',
              'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64',
          )]@
enum
{
  @(idl_structure_type_to_c_typename(message.structure.namespaced_type))__@(constant.name) = @(value_to_c(constant.type, constant.value))
};
@[        elif constant.type.typename in ('float', 'double', 'long double', 'boolean')]@
static const @(basetype_to_c(constant.type)) @(idl_structure_type_to_c_typename(message.structure.namespaced_type))__@(constant.name) = @(value_to_c(constant.type, constant.value));
@[        else]@
@{assert False, 'Unhandled basic type: ' + str(constant.type)}@
@[        end if]@
@[    elif isinstance(constant.type, AbstractString)]@
static const char * const @(idl_structure_type_to_c_typename(message.structure.namespaced_type))__@(constant.name) = @(value_to_c(constant.type, constant.value));
@[    end if]@
@[end for]@
@#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
@
@#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
@[if includes]@

// Include directives for member types
@[    for header_file, member_names in includes.items()]@
@[        for member_name in member_names]@
// Member '@(member_name)'
@[        end for]@
@[        if header_file in include_directives]@
// already included above
// @
@[        else]@
@{include_directives.add(header_file)}@
@[        end if]@
#include "@(header_file)"
@[    end for]@
@[end if]@
@#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
@
@#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
@# Constants for array and string fields with an upper bound
@{
upper_bounds = []
for member in message.structure.members:
    type_ = member.type
    if isinstance(type_, BoundedSequence):
        upper_bounds.append((
            member.name,
            '%s__%s__MAX_SIZE' % (idl_structure_type_to_c_typename(message.structure.namespaced_type), member.name),
            type_.maximum_size,
        ))
    if isinstance(type_, AbstractNestedType):
        type_ = type_.value_type
    if isinstance(type_, AbstractGenericString) and type_.has_maximum_size():
        upper_bounds.append((
            member.name,
            '%s__%s__MAX_STRING_SIZE' % (idl_structure_type_to_c_typename(message.structure.namespaced_type), member.name),
            type_.maximum_size,
        ))
}@
@[if upper_bounds]@

// constants for array fields with an upper bound
@[  for field_name, enum_name, enum_value in upper_bounds]@
// @(field_name)
enum
{
  @(enum_name) = @(enum_value)
};
@[  end for]@
@[end if]@
@#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

@#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// Struct defined in @(interface_path_to_string(interface_path)) in the package @(package_name).
typedef struct @(idl_structure_type_to_c_typename(message.structure.namespaced_type))
{
@[for member in message.structure.members]@
  @(idl_declaration_to_c(member.type, member.name));
@[end for]@
} @(idl_structure_type_to_c_typename(message.structure.namespaced_type));
@#>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

@#<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// Struct for a sequence of @(idl_structure_type_to_c_typename(message.structure.namespaced_type)).
typedef struct @(idl_structure_type_sequence_to_c_typename(message.structure.namespaced_type))
{
  @(idl_structure_type_to_c_typename(message.structure.namespaced_type)) * data;
  /// The number of valid items in data
  size_t size;
  /// The number of allocated items in data
  size_t capacity;
} @(idl_structure_type_sequence_to_c_typename(message.structure.namespaced_type));
