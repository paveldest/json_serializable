// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//ignore_for_file: avoid_unused_constructor_parameters, prefer_initializing_formals

import 'dart:collection';

import 'package:json_annotation/json_annotation.dart';
import 'package:source_gen_test/annotations.dart';

part 'checked_test_input.dart';
part 'configuration_input.dart';
part 'core_subclass_type_input.dart';
part 'default_value_input.dart';
part 'field_namer_input.dart';
part 'generic_test_input.dart';
part 'inheritance_test_input.dart';
part 'json_converter_test_input.dart';
part 'setter_test_input.dart';
part 'to_from_json_test_input.dart';

@ShouldThrow('Generator cannot target `theAnswer`.',
    todo: 'Remove the JsonSerializable annotation from `theAnswer`.')
@JsonSerializable()
const theAnswer = 42;

@ShouldThrow('Generator cannot target `annotatedMethod`.',
    todo: 'Remove the JsonSerializable annotation from `annotatedMethod`.')
@JsonSerializable()
void annotatedMethod() => null;

@ShouldGenerate(
  r'''
GeneralTestClass1 _$GeneralTestClass1FromJson(Map<String, dynamic> json) {
  return GeneralTestClass1()
    ..firstName = json['firstName'] as String
    ..lastName = json['lastName'] as String
    ..height = json['h'] as int
    ..dateOfBirth = json['dateOfBirth'] == null
        ? null
        : DateTime.parse(json['dateOfBirth'] as String)
    ..dynamicType = json['dynamicType']
    ..varType = json['varType']
    ..listOfInts = (json['listOfInts'] as List)?.map((e) => e as int)?.toList();
}

Map<String, dynamic> _$GeneralTestClass1ToJson(GeneralTestClass1 instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'h': instance.height,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String(),
      'dynamicType': instance.dynamicType,
      'varType': instance.varType,
      'listOfInts': instance.listOfInts
    };
''',
  configurations: ['default'],
)
@JsonSerializable()
class GeneralTestClass1 {
  String firstName, lastName;
  @JsonKey(name: 'h')
  int height;
  DateTime dateOfBirth;
  dynamic dynamicType;

  //ignore: prefer_typing_uninitialized_variables
  var varType;
  List<int> listOfInts;
}

@ShouldGenerate(
  r'''
GeneralTestClass2 _$GeneralTestClass2FromJson(Map<String, dynamic> json) {
  return GeneralTestClass2(json['height'] as int, json['firstName'] as String,
      json['lastName'] as String)
    ..dateOfBirth = json['dateOfBirth'] == null
        ? null
        : DateTime.parse(json['dateOfBirth'] as String);
}

Map<String, dynamic> _$GeneralTestClass2ToJson(GeneralTestClass2 instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'height': instance.height,
      'dateOfBirth': instance.dateOfBirth?.toIso8601String()
    };
''',
  configurations: ['default'],
)
@JsonSerializable()
class GeneralTestClass2 {
  final String firstName, lastName;
  int height;
  DateTime dateOfBirth;

  GeneralTestClass2(this.height, String firstName, [this.lastName])
      : firstName = firstName;
}

@ShouldGenerate(
  r'''
FinalFields _$FinalFieldsFromJson(Map<String, dynamic> json) {
  return FinalFields(json['a'] as int);
}

Map<String, dynamic> _$FinalFieldsToJson(FinalFields instance) =>
    <String, dynamic>{'a': instance.a};
''',
  configurations: ['default'],
)
@JsonSerializable()
class FinalFields {
  final int a;

  int get b => 4;

  FinalFields(this.a);
}

@ShouldGenerate(
  r'''
FinalFieldsNotSetInCtor _$FinalFieldsNotSetInCtorFromJson(
    Map<String, dynamic> json) {
  return FinalFieldsNotSetInCtor();
}

Map<String, dynamic> _$FinalFieldsNotSetInCtorToJson(
        FinalFieldsNotSetInCtor instance) =>
    <String, dynamic>{};
''',
  configurations: ['default'],
)
@JsonSerializable()
class FinalFieldsNotSetInCtor {
  final int a = 1;

  FinalFieldsNotSetInCtor();
}

@ShouldGenerate(
  r'''
SetSupport _$SetSupportFromJson(Map<String, dynamic> json) {
  return SetSupport((json['values'] as List)?.map((e) => e as int)?.toSet());
}

Map<String, dynamic> _$SetSupportToJson(SetSupport instance) =>
    <String, dynamic>{'values': instance.values?.toList()};
''',
  configurations: ['default'],
)
@JsonSerializable()
class SetSupport {
  final Set<int> values;

  SetSupport(this.values);
}

@JsonSerializable(createToJson: false)
class FromJsonOptionalParameters {
  final ChildWithFromJson child;

  FromJsonOptionalParameters(this.child);
}

class ChildWithFromJson {
  ChildWithFromJson.fromJson(json, {initValue = false});
}

@JsonSerializable()
class ParentObject {
  int number;
  String str;
  ChildObject child;
}

@JsonSerializable()
class ChildObject {
  int number;
  String str;
}

@JsonSerializable()
class ParentObjectWithChildren {
  int number;
  String str;
  List<ChildObject> children;
}

@JsonSerializable()
class ParentObjectWithDynamicChildren {
  int number;
  String str;
  List<dynamic> children;
}

@JsonSerializable()
class UnknownCtorParamType {
  int number;

  // ignore: undefined_class, field_initializer_not_assignable
  UnknownCtorParamType(Bob number) : number = number;
}

@JsonSerializable()
class UnknownFieldType {
  // ignore: undefined_class
  Bob number;
}

@JsonSerializable(createFactory: false)
class UnknownFieldTypeToJsonOnly {
  // ignore: undefined_class
  Bob number;
}

@JsonSerializable()
class UnknownFieldTypeWithConvert {
  @JsonKey(fromJson: _everythingIs42, toJson: _everythingIs42)
  // ignore: undefined_class
  Bob number;
}

dynamic _everythingIs42(Object input) => 42;

@JsonSerializable(createFactory: false)
class NoSerializeFieldType {
  Stopwatch watch;
}

@JsonSerializable(createToJson: false)
class NoDeserializeFieldType {
  Stopwatch watch;
}

@JsonSerializable(createFactory: false)
class NoSerializeBadKey {
  Map<int, DateTime> intDateTimeMap;
}

@JsonSerializable(createToJson: false)
class NoDeserializeBadKey {
  Map<int, DateTime> intDateTimeMap;
}

@JsonSerializable(createFactory: false)
class IncludeIfNullAll {
  @JsonKey(includeIfNull: true)
  int number;
  String str;
}

@ShouldGenerate(
  r'''
Map<String, dynamic> _$IncludeIfNullOverrideToJson(
    IncludeIfNullOverride instance) {
  final val = <String, dynamic>{
    'number': instance.number,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('str', instance.str);
  return val;
}
''',
  configurations: ['default'],
)
@JsonSerializable(createFactory: false, includeIfNull: false)
class IncludeIfNullOverride {
  @JsonKey(includeIfNull: true)
  int number;
  String str;
}

// https://github.com/dart-lang/json_serializable/issues/7 regression
@JsonSerializable()
class NoCtorClass {
  final int member;

  factory NoCtorClass.fromJson(Map<String, dynamic> json) => null;
}

@ShouldThrow(
  'More than one field has the JSON key `str`.',
  todo: 'Check the `JsonKey` annotations on fields.',
  element: 'str',
)
@JsonSerializable(createFactory: false)
class KeyDupesField {
  @JsonKey(name: 'str')
  int number;

  String str;
}

@ShouldThrow(
  'More than one field has the JSON key `a`.',
  todo: 'Check the `JsonKey` annotations on fields.',
  element: 'str',
)
@JsonSerializable(createFactory: false)
class DupeKeys {
  @JsonKey(name: 'a')
  int number;

  @JsonKey(name: 'a')
  String str;
}

@ShouldGenerate(
  r'''
Map<String, dynamic> _$IgnoredFieldClassToJson(IgnoredFieldClass instance) =>
    <String, dynamic>{
      'ignoredFalseField': instance.ignoredFalseField,
      'ignoredNullField': instance.ignoredNullField
    };
''',
  configurations: ['default'],
)
@JsonSerializable(createFactory: false)
class IgnoredFieldClass {
  @JsonKey(ignore: true)
  int ignoredTrueField;

  @JsonKey(ignore: false)
  int ignoredFalseField;

  int ignoredNullField;
}

@ShouldThrow(
  'Cannot populate the required constructor argument: '
      'ignoredTrueField. It is assigned to an ignored field.',
  element: '',
)
@JsonSerializable()
class IgnoredFieldCtorClass {
  @JsonKey(ignore: true)
  int ignoredTrueField;

  IgnoredFieldCtorClass(this.ignoredTrueField);
}

@ShouldThrow(
  'Cannot populate the required constructor argument: '
      '_privateField. It is assigned to a private field.',
  element: '',
)
@JsonSerializable()
class PrivateFieldCtorClass {
  // ignore: unused_field
  int _privateField;

  PrivateFieldCtorClass(this._privateField);
}

@ShouldThrow(
  'Error with `@JsonKey` on `field`. '
      'Cannot set both `disallowNullvalue` and `includeIfNull` to `true`. '
      'This leads to incompatible `toJson` and `fromJson` behavior.',
  element: 'field',
)
@JsonSerializable()
class IncludeIfNullDisallowNullClass {
  @JsonKey(includeIfNull: true, disallowNullValue: true)
  int field;
}

@JsonSerializable(createFactory: false, explicitToJson: true)
class TrivialNestedNullable {
  TrivialNestedNullable child;
  int otherField;
}

@JsonSerializable(createFactory: false, nullable: false, explicitToJson: true)
class TrivialNestedNonNullable {
  TrivialNestedNonNullable child;
  int otherField;
}

@ShouldThrow(
  'The `JsonValue` annotation on `BadEnum.value` does not have a value '
      'of type String, int, or null.',
  element: 'value',
)
@JsonSerializable()
class JsonValueWithBool {
  BadEnum field;
}

enum BadEnum {
  @JsonValue(true)
  value
}

@ShouldGenerate(r'''const _$GoodEnumEnumMap = <GoodEnum, dynamic>{
  GoodEnum.noAnnotation: 'noAnnotation',
  GoodEnum.stringAnnotation: 'string annotation',
  GoodEnum.stringAnnotationWeird: r"string annotation with $ funky 'values'",
  GoodEnum.intValue: 42,
  GoodEnum.nullValue: null
};
''', contains: true)
@JsonSerializable()
class JsonValueValid {
  GoodEnum field;
}

enum GoodEnum {
  noAnnotation,
  @JsonValue('string annotation')
  stringAnnotation,
  @JsonValue("string annotation with \$ funky 'values'")
  stringAnnotationWeird,
  @JsonValue(42)
  intValue,
  @JsonValue(null)
  nullValue
}

@ShouldGenerate(r'''
FieldWithFromJsonCtorAndTypeParams _$FieldWithFromJsonCtorAndTypeParamsFromJson(
    Map<String, dynamic> json) {
  return FieldWithFromJsonCtorAndTypeParams()
    ..customOrders = json['customOrders'] == null
        ? null
        : MyList.fromJson((json['customOrders'] as List)
            ?.map((e) => e == null
                ? null
                : GeneralTestClass2.fromJson(e as Map<String, dynamic>))
            ?.toList());
}
''')
@JsonSerializable(createToJson: false)
class FieldWithFromJsonCtorAndTypeParams {
  MyList<GeneralTestClass2, int> customOrders;
}

class MyList<T, Q> extends ListBase<T> {
  final List<T> _data;

  MyList(Iterable<T> source) : _data = source.toList() ?? [];

  factory MyList.fromJson(List<T> items) => MyList(items);

  @override
  int get length => _data.length;

  @override
  set length(int value) {
    _data.length = value;
  }

  @override
  T operator [](int index) => _data[index];

  @override
  void operator []=(int index, T value) {
    _data[index] = value;
  }
}
