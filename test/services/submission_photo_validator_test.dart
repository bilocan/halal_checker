import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:halal_checker/utils/submission_photo_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<File> writeTempPng(String name, List<int> bytes) async {
    final dir = await Directory.systemTemp.createTemp('halal_photo_val_');
    final f = File('${dir.path}/$name');
    await f.writeAsBytes(bytes);
    return f;
  }

  group('SubmissionPhotoValidator', () {
    test('rejects file larger than maxBytes', () async {
      final dir = await Directory.systemTemp.createTemp('halal_photo_val_');
      final f = File('${dir.path}/big.dat');
      await f.writeAsBytes(List<int>.filled(120, 0));
      final issue = await SubmissionPhotoValidator.validate(
        f,
        maxBytes: 100,
        minShortEdge: 1,
      );
      expect(issue, SubmissionPhotoIssue.tooLarge);
      await dir.delete(recursive: true);
    });

    test('rejects unreadable bytes', () async {
      final dir = await Directory.systemTemp.createTemp('halal_photo_val_');
      final f = File('${dir.path}/bad.png');
      await f.writeAsBytes(<int>[0, 1, 2, 3]);
      final issue = await SubmissionPhotoValidator.validate(
        f,
        maxBytes: 1000,
        minShortEdge: 1,
      );
      expect(issue, SubmissionPhotoIssue.unreadable);
      await dir.delete(recursive: true);
    });

    test('rejects tiny PNG (resolution too low)', () async {
      final im = img.Image(width: 1, height: 1);
      img.fill(im, color: img.ColorRgb8(0, 0, 0));
      final bytes = img.encodePng(im);
      final f = await writeTempPng('tiny.png', bytes);
      final issue = await SubmissionPhotoValidator.validate(
        f,
        maxBytes: 999999,
      );
      expect(issue, SubmissionPhotoIssue.resolutionTooLow);
      await f.parent.delete(recursive: true);
    });

    test('accepts sufficiently large PNG', () async {
      final im = img.Image(width: 400, height: 400);
      img.fill(im, color: img.ColorRgb8(200, 200, 200));
      final bytes = img.encodePng(im);
      final f = await writeTempPng('ok.png', bytes);
      final issue = await SubmissionPhotoValidator.validate(f);
      expect(issue, isNull);
      await f.parent.delete(recursive: true);
    });
  });
}
