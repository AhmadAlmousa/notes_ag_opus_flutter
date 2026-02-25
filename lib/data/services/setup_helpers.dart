/// Platform-agnostic setup helpers.
/// 
/// On native: uses path_provider for default directory.
/// On web: stubs that throw UnsupportedError.
export 'setup_helpers_web.dart'
    if (dart.library.io) 'setup_helpers_io.dart';
