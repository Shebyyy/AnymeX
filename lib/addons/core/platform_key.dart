import 'dart:ffi' show Abi;
import 'dart:io' show Platform;

/// Identifies the current OS + CPU the way the add-on repo names its files,
/// e.g. `android-arm64-v8a`, `windows-x64`, `linux-x64`, `macos-arm64`.
///
/// Returns `null` on platforms where a downloaded executable cannot run
/// (iOS) or that the add-on repo does not ship binaries for.
String? currentPlatformKey() {
  final abi = Abi.current();
  if (Platform.isAndroid) {
    if (abi == Abi.androidArm64) return 'android-arm64-v8a';
    if (abi == Abi.androidArm) return 'android-armeabi-v7a';
    if (abi == Abi.androidX64) return 'android-x86_64';
    return null;
  }
  if (Platform.isWindows) {
    if (abi == Abi.windowsX64) return 'windows-x64';
    return null;
  }
  if (Platform.isLinux) {
    if (abi == Abi.linuxX64) return 'linux-x64';
    if (abi == Abi.linuxArm64) return 'linux-arm64';
    return null;
  }
  if (Platform.isMacOS) {
    if (abi == Abi.macosArm64) return 'macos-arm64';
    if (abi == Abi.macosX64) return 'macos-x64';
    return null;
  }
  return null;
}
