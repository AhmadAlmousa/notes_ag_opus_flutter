import 'package:path_provider/path_provider.dart';

/// Get the default documents directory path for note storage.
Future<String> getDefaultNotesDirectory() async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/Organote';
}
