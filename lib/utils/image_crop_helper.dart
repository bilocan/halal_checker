import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../app_colors.dart';

/// Opens the crop UI for [photo]. Returns the cropped file, or [photo]
/// unchanged if the user dismisses without cropping.
Future<XFile> maybeCropImage(BuildContext context, XFile photo) async {
  final cropped = await ImageCropper().cropImage(
    sourcePath: photo.path,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Crop image',
        toolbarColor: kGreen,
        toolbarWidgetColor: Colors.white,
        activeControlsWidgetColor: kGreen,
        lockAspectRatio: false,
        initAspectRatio: CropAspectRatioPreset.original,
      ),
      IOSUiSettings(
        title: 'Crop image',
        cancelButtonTitle: 'Skip',
        doneButtonTitle: 'Done',
        showCancelConfirmationDialog: false,
      ),
    ],
  );
  return cropped != null ? XFile(cropped.path) : photo;
}
