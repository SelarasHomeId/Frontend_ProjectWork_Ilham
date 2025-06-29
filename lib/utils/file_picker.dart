import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mime/mime.dart';

Future<void> uploadPhotoFromFile(
  BuildContext context, {
  required void Function(PlatformFile, String) filePicked,
  required Future<void> Function(String) cropImages,
}) async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final currentFiles = result.files.single;
      List<String> partName = currentFiles.name.split('.').toList();
      String type = partName.last;

      switch (type) {
        case 'pdf':
        case 'doc':
        case 'docx':
          filePicked(currentFiles, type);
          break;

        case 'png':
        case 'jpg':
        case 'jpeg':
          await cropImages(currentFiles.path!);
          break;
        default:
          break;
      }

      // await cropImages(pickedImage!.path);
    }
  } catch (e) {
    debugPrint("ERROR : ${e.toString()}");
  }
}

Future<AsPathResponse?> cropImages(
    {required BuildContext context, required String path}) async {
  try {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '',
          toolbarColor: Colors.orange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: '',
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );

    if (croppedFile == null) {
      return null;
    }

    final mimeType = lookupMimeType(path);
    String fileName = path.split('/').last;
    List<String> getFileExtension(String fileName) => fileName.split('/');
    List<String> dataMime = getFileExtension(mimeType as String);
    String fileExtension = dataMime[1];
    MediaType fileType = MediaType.parse(mimeType);

    return AsPathResponse(
        path: path,
        fileName: fileName.toString().replaceAll(" ", "_"),
        fileExtension: fileExtension.toString().replaceAll("jpeg", "jpg"),
        fileType: fileType);
  } catch (e, stack) {
    debugPrint('Error cropping image: $e $stack');
  }
  return null;
}

class AsPathResponse {
  final String? path;
  final String? fileName;
  final String? fileExtension;
  final MediaType? fileType;

  AsPathResponse({
    this.path,
    this.fileName,
    this.fileExtension,
    this.fileType,
  });

  @override
  String toString() {
    return 'AsPathResponse(path: $path, fileName: $fileName, fileExtension: $fileExtension, fileType: $fileType)';
  }
}
