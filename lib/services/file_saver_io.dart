// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> saveAndLaunchFile(List<int> bytes, String fileName) async {
  Directory? directory;
  try {
    directory = await getDownloadsDirectory();
  } catch (_) {}
  directory ??= await getApplicationDocumentsDirectory();

  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);

  // Try to open directly with Excel / PDF viewer
  try {
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      // If no default viewer, open native share dialog
      await Share.shareXFiles([XFile(file.path)], text: fileName);
    }
  } catch (_) {
    try {
      await Share.shareXFiles([XFile(file.path)], text: fileName);
    } catch (_) {}
  }

  return file.path;
}
