import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageHelper {
  static final picker = ImagePicker();
  static bool _isPicking = false;

  /// Pick image from gallery (with permission handling)
  static Future<File?> pickImageFromGallery() async {
    if (_isPicking) return null;
    _isPicking = true;

    try {
      bool isGranted = await _requestPermission();
      if (!isGranted) return null;

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100, // pick full quality, we’ll compress later
      );

      if (pickedFile == null) return null;

      final file = File(pickedFile.path);
      _logFileSize(file, "Original");

      return file;
    } catch (e) {
      debugPrint("Image pick error: $e");
      return null;
    } finally {
      _isPicking = false;
    }
  }

  /// Compress image to reduce file size
  static Future<File?> compressImage(File file, {int quality = 50}) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        "${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
    );

    if (result == null) return null;

    final compressedFile = File(result.path);
    _logFileSize(compressedFile, "Compressed");

    return compressedFile;
  }

  /// Request permission for Android/iOS
  static Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      var storageStatus = await Permission.storage.status;
      var photosStatus = await Permission.photos.status;

      if (storageStatus.isDenied || photosStatus.isDenied) {
        //ask again
        photosStatus = await Permission.photos.request();
        storageStatus = await Permission.storage.request();
      }

      if (storageStatus.isPermanentlyDenied ||
          photosStatus.isPermanentlyDenied) {
        // User must go to settings
        await openAppSettings();
        return false;
      }

      return photosStatus.isGranted || storageStatus.isGranted;
    } else if (Platform.isIOS) {
      var status = await Permission.photos.status;

      if (status.isDenied) {
        status = await Permission.photos.request();
      }

      if (status.isPermanentlyDenied || status.isRestricted) {
        // iOS limited/restricted access requires settings
        await openAppSettings();
        return false;
      }

      return status.isGranted;
    }
    return false;
  }

  /// Helper to log file size
  static Future<void> _logFileSize(File file, String label) async {
    final sizeInBytes = await file.length();
    final sizeInKB = sizeInBytes / 1024;
    final sizeInMB = sizeInKB / 1024;
    debugPrint(
      '$label image size: ${sizeInBytes.toStringAsFixed(2)} bytes '
      '(${sizeInKB.toStringAsFixed(2)} KB, ${sizeInMB.toStringAsFixed(2)} MB)',
    );
  }
}
