/// Platform-agnostic file system interop.
///
/// On web: uses JS interop (File System Access API / OPFS).
/// On native (Android, iOS, Windows, Linux, macOS): uses dart:io.
export 'fs_interop_io.dart'
    if (dart.library.js_interop) 'fs_interop_web.dart';
