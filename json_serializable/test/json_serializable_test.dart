// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:async';

import 'package:analyzer/dart/element/type.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:json_serializable/json_serializable.dart';
import 'package:json_serializable/src/constants.dart';
import 'package:json_serializable/src/type_helper.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_gen_test/source_gen_test.dart';
import 'package:test/test.dart';

import 'shared_config.dart';
import 'test_file_utils.dart';

Matcher _throwsUnsupportedError(matcher) =>
    throwsA(const TypeMatcher<UnsupportedError>()
        .having((e) => e.message, 'message', matcher));

const _expectedAnnotatedTests = [
  'theAnswer',
  'annotatedMethod',
  'FinalFields',
  'FinalFieldsNotSetInCtor',
  'SetSupport',
  'IncludeIfNullOverride',
  'KeyDupesField',
  'DupeKeys',
  'IgnoredFieldClass',
  'IgnoredFieldCtorClass',
  'PrivateFieldCtorClass',
  'IncludeIfNullDisallowNullClass',
  'JsonValueWithBool',
  'JsonValueValid',
  'FieldWithFromJsonCtorAndTypeParams',
  'WithANonCtorGetterChecked',
  'WithANonCtorGetter',
  'UnsupportedMapField',
  'UnsupportedListField',
  'UnsupportedSetField',
  'UnsupportedDurationField',
  'UnsupportedUriField',
  'UnsupportedDateTimeField',
  'DefaultWithSymbol',
  'DefaultWithFunction',
  'DefaultWithType',
  'DefaultWithConstObject',
  'DefaultWithNestedEnum',
  'DefaultWithNonNullableField',
  'DefaultWithNonNullableClass',
  'DefaultWithToJsonClass',
  'DefaultWithDisallowNullRequiredClass',
  'FieldNamerNone',
  'FieldNamerKebab',
  'FieldNamerSnake',
  'GenericClass',
  'GenericClass',
  'SubType',
  'SubType',
  'SubTypeWithAnnotatedFieldOverrideExtends',
  'SubTypeWithAnnotatedFieldOverrideExtendsWithOverrides',
  'SubTypeWithAnnotatedFieldOverrideImplements',
  'JsonConverterNamedCtor',
  'JsonConvertOnField',
  'JsonConverterWithBadTypeArg',
  'JsonConverterDuplicateAnnotations',
  'JsonConverterCtorParams',
  'JustSetter',
  'JustSetterNoToJson',
  'GeneralTestClass1',
  'GeneralTestClass2',
  'JustSetterNoFromJson',
  'BadFromFuncReturnType',
  'InvalidFromFunc2Args',
  'ValidToFromFuncClassStatic',
  'BadToFuncReturnType',
  'InvalidToFunc2Args',
  'ObjectConvertMethods',
  'DynamicConvertMethods',
  'TypedConvertMethods',
  'FromDynamicCollection',
  'BadNoArgs',
  'BadTwoRequiredPositional',
  'BadOneNamed',
  'OkayOneNormalOptionalPositional',
  'OkayOneNormalOptionalNamed',
  'OkayOnlyOptionalPositional'
];

LibraryReader _libraryReader;

void main() async {
  initializeBuildLogTracking();
  _libraryReader = await initializeLibraryReaderForDirectory(
    testFilePath('test', 'src'),
    '_json_serializable_test_input.dart',
  );

  testAnnotatedElements(
    _libraryReader,
    const JsonSerializableGenerator(),
    additionalGenerators: const {
      'wrapped': JsonSerializableGenerator(
        config: JsonSerializable(useWrappers: true),
      ),
    },
    expectedAnnotatedTests: _expectedAnnotatedTests,
  );

  group('without wrappers', () {
    _registerTests(JsonSerializable.defaults);
  });
  group(
      'with wrapper',
      () => _registerTests(
          const JsonSerializable(useWrappers: true).withDefaults()));

  group('configuration', () {
    Future<Null> runWithConfigAndLogger(
        JsonSerializable config, String className) async {
      await generateForElement(
          JsonSerializableGenerator(
              config: config, typeHelpers: const [_ConfigLogger()]),
          _libraryReader,
          className);
    }

    setUp(_ConfigLogger.configurations.clear);

    group('defaults', () {
      for (var className in [
        'ConfigurationImplicitDefaults',
        'ConfigurationExplicitDefaults',
      ]) {
        for (var nullConfig in [true, false]) {
          final testDescription =
              '$className with ${nullConfig ? 'null' : 'default'} config';

          test(testDescription, () async {
            await runWithConfigAndLogger(
                nullConfig ? null : const JsonSerializable(), className);

            expect(_ConfigLogger.configurations, hasLength(2));
            expect(_ConfigLogger.configurations.first,
                same(_ConfigLogger.configurations.last));
            expect(_ConfigLogger.configurations.first.toJson(),
                generatorConfigDefaultJson);
          });
        }
      }
    });

    test(
        'values in config override unconfigured (default) values in annotation',
        () async {
      await runWithConfigAndLogger(
          JsonSerializable.fromJson(generatorConfigNonDefaultJson),
          'ConfigurationImplicitDefaults');

      expect(_ConfigLogger.configurations, isEmpty,
          reason: 'all generation is disabled');

      // Create a configuration with just `create_to_json` set to true so we
      // can validate the configuration that is run with
      final configMap =
          Map<String, dynamic>.from(generatorConfigNonDefaultJson);
      configMap['create_to_json'] = true;

      await runWithConfigAndLogger(JsonSerializable.fromJson(configMap),
          'ConfigurationImplicitDefaults');
    });

    test(
        'explicit values in annotation override corresponding settings in config',
        () async {
      await runWithConfigAndLogger(
          JsonSerializable.fromJson(generatorConfigNonDefaultJson),
          'ConfigurationExplicitDefaults');

      expect(_ConfigLogger.configurations, hasLength(2));
      expect(_ConfigLogger.configurations.first,
          same(_ConfigLogger.configurations.last));

      // The effective configuration should be non-Default configuration, but
      // with all fields set from JsonSerializable as the defaults

      final expected = Map.from(generatorConfigNonDefaultJson);
      for (var jsonSerialKey in jsonSerializableFields) {
        expected[jsonSerialKey] = generatorConfigDefaultJson[jsonSerialKey];
      }

      expect(_ConfigLogger.configurations.first.toJson(), expected);
    });
  });
}

Future<String> _runForElementNamed(JsonSerializable config, String name) async {
  final generator = JsonSerializableGenerator(config: config);
  return generateForElement(generator, _libraryReader, name);
}

void _registerTests(JsonSerializable generator) {
  Future<String> runForElementNamed(String name) =>
      _runForElementNamed(generator, name);

  void expectThrows(String elementName, messageMatcher, [todoMatcher]) {
    todoMatcher ??= isEmpty;
    expect(
      () => runForElementNamed(elementName),
      throwsInvalidGenerationSourceError(
        messageMatcher,
        todoMatcher: todoMatcher,
      ),
    );
  }

  group('explicit toJson', () {
    test('nullable', () async {
      final output = await _runForElementNamed(
          JsonSerializable(useWrappers: generator.useWrappers),
          'TrivialNestedNullable');

      final expected = generator.useWrappers
          ? r'''
Map<String, dynamic> _$TrivialNestedNullableToJson(
        TrivialNestedNullable instance) =>
    _$TrivialNestedNullableJsonMapWrapper(instance);

class _$TrivialNestedNullableJsonMapWrapper extends $JsonMapWrapper {
  final TrivialNestedNullable _v;
  _$TrivialNestedNullableJsonMapWrapper(this._v);

  @override
  Iterable<String> get keys => const ['child', 'otherField'];

  @override
  dynamic operator [](Object key) {
    if (key is String) {
      switch (key) {
        case 'child':
          return _v.child?.toJson();
        case 'otherField':
          return _v.otherField;
      }
    }
    return null;
  }
}
'''
          : r'''
Map<String, dynamic> _$TrivialNestedNullableToJson(
        TrivialNestedNullable instance) =>
    <String, dynamic>{
      'child': instance.child?.toJson(),
      'otherField': instance.otherField
    };
''';

      expect(output, expected);
    });
    test('non-nullable', () async {
      final output = await _runForElementNamed(
          JsonSerializable(useWrappers: generator.useWrappers),
          'TrivialNestedNonNullable');

      final expected = generator.useWrappers
          ? r'''
Map<String, dynamic> _$TrivialNestedNonNullableToJson(
        TrivialNestedNonNullable instance) =>
    _$TrivialNestedNonNullableJsonMapWrapper(instance);

class _$TrivialNestedNonNullableJsonMapWrapper extends $JsonMapWrapper {
  final TrivialNestedNonNullable _v;
  _$TrivialNestedNonNullableJsonMapWrapper(this._v);

  @override
  Iterable<String> get keys => const ['child', 'otherField'];

  @override
  dynamic operator [](Object key) {
    if (key is String) {
      switch (key) {
        case 'child':
          return _v.child.toJson();
        case 'otherField':
          return _v.otherField;
      }
    }
    return null;
  }
}
'''
          : r'''
Map<String, dynamic> _$TrivialNestedNonNullableToJson(
        TrivialNestedNonNullable instance) =>
    <String, dynamic>{
      'child': instance.child.toJson(),
      'otherField': instance.otherField
    };
''';

      expect(output, expected);
    });
  });

  group('unknown types', () {
    tearDown(() {
      expect(buildLogItems, hasLength(1));
      expect(buildLogItems.first,
          startsWith('This element has an undefined type.'));
      clearBuildLog();
    });
    String flavorMessage(String flavor) =>
        'Could not generate `$flavor` code for `number` '
        'because the type is undefined.';

    String flavorTodo(String flavor) =>
        'Check your imports. If you\'re trying to generate code for a '
        'Platform-provided type, you may have to specify a custom `$flavor` '
        'in the associated `@JsonKey` annotation.';

    group('fromJson', () {
      final msg = flavorMessage('fromJson');
      final todo = flavorTodo('fromJson');
      test('in constructor arguments', () {
        expectThrows('UnknownCtorParamType', msg, todo);
      });

      test('in fields', () {
        expectThrows('UnknownFieldType', msg, todo);
      });
    });

    group('toJson', () {
      test('in fields', () {
        expectThrows('UnknownFieldTypeToJsonOnly', flavorMessage('toJson'),
            flavorTodo('toJson'));
      });
    });

    test('with proper convert methods', () async {
      final output = await runForElementNamed('UnknownFieldTypeWithConvert');
      expect(output, contains("_everythingIs42(json['number'])"));
      if (generator.useWrappers) {
        expect(output, contains('_everythingIs42(_v.number)'));
      } else {
        expect(output, contains('_everythingIs42(instance.number)'));
      }
    });
  });

  group('unserializable types', () {
    final noSupportHelperFyi = 'Could not generate `toJson` code for `watch`.\n'
        'None of the provided `TypeHelper` instances support the defined type.';

    test('for toJson', () {
      expectThrows('NoSerializeFieldType', noSupportHelperFyi,
          'Make sure all of the types are serializable.');
    });

    test('for fromJson', () {
      expectThrows(
          'NoDeserializeFieldType',
          noSupportHelperFyi.replaceFirst('toJson', 'fromJson'),
          'Make sure all of the types are serializable.');
    });

    final mapKeyFyi = 'Could not generate `toJson` code for `intDateTimeMap` '
        'because of type `int`.\nMap keys must be of type '
        '`String`, enum, `Object` or `dynamic`.';

    test('for toJson in Map key', () {
      expectThrows('NoSerializeBadKey', mapKeyFyi,
          'Make sure all of the types are serializable.');
    });

    test('for fromJson', () {
      expectThrows(
          'NoDeserializeBadKey',
          mapKeyFyi.replaceFirst('toJson', 'fromJson'),
          'Make sure all of the types are serializable.');
    });
  });

  test('class with final fields', () async {
    final generateResult = await runForElementNamed('FinalFields');
    expect(
        generateResult,
        contains(
            r'Map<String, dynamic> _$FinalFieldsToJson(FinalFields instance)'));
  });

  group('valid inputs', () {
    test('class with fromJson() constructor with optional parameters',
        () async {
      final output = await runForElementNamed('FromJsonOptionalParameters');

      expect(output, contains('ChildWithFromJson.fromJson'));
    });

    test('class with child json-able object', () async {
      final output = await runForElementNamed('ParentObject');

      expect(
          output,
          contains("ChildObject.fromJson(json['child'] "
              'as Map<String, dynamic>)'));
    });

    test('class with child json-able object - anyMap', () async {
      final output = await _runForElementNamed(
          JsonSerializable(anyMap: true, useWrappers: generator.useWrappers),
          'ParentObject');

      expect(output, contains("ChildObject.fromJson(json['child'] as Map)"));
    });

    test('class with child list of json-able objects', () async {
      final output = await runForElementNamed('ParentObjectWithChildren');

      expect(output, contains('.toList()'));
      expect(output, contains('ChildObject.fromJson'));
    });

    test('class with child list of dynamic objects is left alone', () async {
      final output =
          await runForElementNamed('ParentObjectWithDynamicChildren');

      expect(output, contains('children = json[\'children\'] as List;'));
    });
  });

  group('includeIfNull', () {
    test('some', () async {
      final output = await runForElementNamed('IncludeIfNullAll');
      expect(output, isNot(contains(generatedLocalVarName)));
      expect(output, isNot(contains(toJsonMapHelperName)));
    });
  });

  test('missing default ctor with a factory', () {
    expect(
        () => runForElementNamed('NoCtorClass'),
        _throwsUnsupportedError(
            'The class `NoCtorClass` has no default constructor.'));
  });
}

class _ConfigLogger implements TypeHelper<TypeHelperContextWithConfig> {
  static final configurations = <JsonSerializable>[];

  const _ConfigLogger();

  @override
  Object deserialize(DartType targetType, String expression,
      TypeHelperContextWithConfig context) {
    configurations.add(context.config);
    return null;
  }

  @override
  Object serialize(DartType targetType, String expression,
      TypeHelperContextWithConfig context) {
    configurations.add(context.config);
    return null;
  }
}
