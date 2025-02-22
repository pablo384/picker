// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picker/picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$Picker', () {
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/Picker');

    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        return '';
      });

      log.clear();
    });

    group('#pickImage', () {
      test('passes the image source argument correctly', () async {
        await Picker.pickImage(source: ImageSource.camera);
        await Picker.pickImage(source: ImageSource.gallery);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 1,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null
            }),
          ],
        );
      });

      test('passes the width and height arguments correctly', () async {
        await Picker.pickImage(source: ImageSource.camera);
        await Picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 10.0,
        );
        await Picker.pickImage(
          source: ImageSource.camera,
          maxHeight: 10.0,
        );
        await Picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 10.0,
          maxHeight: 20.0,
        );
        await Picker.pickImage(
            source: ImageSource.camera, maxWidth: 10.0, imageQuality: 70);
        await Picker.pickImage(
            source: ImageSource.camera, maxHeight: 10.0, imageQuality: 70);
        await Picker.pickImage(
            source: ImageSource.camera,
            maxWidth: 10.0,
            maxHeight: 20.0,
            imageQuality: 70);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': null,
              'imageQuality': null
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': null
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': null
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': null
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': null,
              'imageQuality': 70
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': null,
              'maxHeight': 10.0,
              'imageQuality': 70
            }),
            isMethodCall('pickImage', arguments: <String, dynamic>{
              'source': 0,
              'maxWidth': 10.0,
              'maxHeight': 20.0,
              'imageQuality': 70
            }),
          ],
        );
      });

      test('does not accept a negative width or height argument', () {
        expect(
          Picker.pickImage(source: ImageSource.camera, maxWidth: -1.0),
          throwsArgumentError,
        );

        expect(
          Picker.pickImage(source: ImageSource.camera, maxHeight: -1.0),
          throwsArgumentError,
        );
      });

      test('handles a null image path response gracefully', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) => null);

        expect(
            await Picker.pickImage(source: ImageSource.gallery), isNull);
        expect(await Picker.pickImage(source: ImageSource.camera), isNull);
      });
    });

    group('#pickVideo', () {
      test('passes the image source argument correctly', () async {
        await Picker.pickVideo(source: ImageSource.camera);
        await Picker.pickVideo(source: ImageSource.gallery);

        expect(
          log,
          <Matcher>[
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 0,
            }),
            isMethodCall('pickVideo', arguments: <String, dynamic>{
              'source': 1,
            }),
          ],
        );
      });

      test('handles a null image path response gracefully', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) => null);

        expect(
            await Picker.pickVideo(source: ImageSource.gallery), isNull);
        expect(await Picker.pickVideo(source: ImageSource.camera), isNull);
      });
    });

    group('#retrieveLostData', () {
      test('retrieveLostData get success response', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          return <String, String>{
            'type': 'image',
            'path': '/example/path',
          };
        });
        final LostDataResponse response = await Picker.retrieveLostData();
        expect(response.type, RetrieveType.image);
        expect(response.file!.path, '/example/path');
      });

      test('retrieveLostData get error response', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          return <String, String>{
            'type': 'video',
            'errorCode': 'test_error_code',
            'errorMessage': 'test_error_message',
          };
        });
        final LostDataResponse response = await Picker.retrieveLostData();
        expect(response.type, RetrieveType.video);
        expect(response.exception!.code, 'test_error_code');
        expect(response.exception!.message, 'test_error_message');
      });

      test('retrieveLostData get null response', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          return null;
        });
        expect((await Picker.retrieveLostData()).isEmpty, true);
      });

      test('retrieveLostData get both path and error should throw', () async {
        channel.setMockMethodCallHandler((MethodCall methodCall) async {
          return <String, String>{
            'type': 'video',
            'errorCode': 'test_error_code',
            'errorMessage': 'test_error_message',
            'path': '/example/path',
          };
        });
        expect(Picker.retrieveLostData(), throwsAssertionError);
      });
    });
  });
}
