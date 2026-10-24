import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:coldchat/data/filesharing/uploaded_media.dart';

class Catbox {
  static Future<UploadedMedia> uploadFile(String filename, Uint8List bytes) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://litterbox.catbox.moe/resources/internals/api.php'),
    );
    request.headers['User-Agent'] = 'ColdChat (https://github.com/c0ldplasma/coldchat)';
    request.files.add(
      http.MultipartFile.fromBytes('fileToUpload', bytes, filename: filename),
    );
    request.fields['reqtype'] = 'fileupload';
    request.fields['time'] = '72h';

    final response = await request.send();
    final responseBody = (await response.stream.bytesToString()).trim();

    if (response.statusCode != 200 || !responseBody.startsWith('http')) {
      throw 'Upload failed (${response.statusCode}): $responseBody';
    }

    return UploadedMedia(
      time: DateTime.now(),
      url: responseBody,
    );
  }
}
