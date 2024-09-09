// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const changeLogFiles = ["CHANGELOG.md"];
const filesToUpdate = [
  "pubspec.yaml",
  "ios/sweph.podspec",
  "macos/sweph.podspec",
];

class Version {
  final int _major;
  final int _minor;
  final int _patch;
  final int _pluginVersion;

  Version(this._major, this._minor, this._patch, this._pluginVersion);

  @override
  String toString() {
    return '$_major.$_minor.$_patch+$_pluginVersion';
  }

  static Version fromString(String versionStr) {
    final parts = versionStr.split('+');
    final List<int> versions =
        parts[0].split('.').map((str) => int.parse(str)).toList();
    if (parts.length == 1) {
      return Version(versions[0], versions[1], versions[2], 1);
    }
    return Version(versions[0], versions[1], versions[2], int.parse(parts[1]));
  }

  static Version getNextVersion(Version currentVersion, Version nativeVersion) {
    return Version(nativeVersion._major, nativeVersion._minor,
        nativeVersion._patch, currentVersion._pluginVersion + 1);
  }
}

void updateVersion(Version from, Version to) {
  for (final path in filesToUpdate) {
    final file = File(path);
    final contents = file.readAsStringSync();
    file.writeAsStringSync(contents.replaceAll(from.toString(), to.toString()));
  }
}

void changeLog(Version to, String log) {
  for (final path in changeLogFiles) {
    final file = File(path);
    final contents = file.readAsStringSync();
    final prefix = "## $to\n\n- $log\n\n";
    file.writeAsStringSync(prefix);
    file.writeAsStringSync(contents, mode: FileMode.append);
  }
}

Version? getVersion(File file, RegExp pattern) {
  for (final line in file.readAsLinesSync()) {
    final match = pattern.firstMatch(line);
    if (match == null) {
      continue;
    }
    return Version.fromString(match.group(1)!);
  }
  return null;
}

void main(List<String> args) {
  final rootDir = Directory.current;

  final pubspecFile = File("${rootDir.path}/pubspec.yaml");
  if (!pubspecFile.existsSync()) {
    print("Run from root folder");
    return;
  }

  Version? currentVersion = getVersion(pubspecFile, RegExp(r"^version: (.*)$"));
  Version? nativeVersion = getVersion(
      File("${rootDir.path}/native/sweph/src/sweph.h"),
      RegExp(r'^#define SE_VERSION\s+"(.*)"\s*$'));

  if (currentVersion == null || nativeVersion == null) {
    return;
  }

  stdout.write("Enter changelog: ");
  final log = stdin.readLineSync(encoding: utf8);
  if (log == null) {
    return;
  }

  final nextVersion = Version.getNextVersion(currentVersion, nativeVersion);

  updateVersion(currentVersion, nextVersion);
  changeLog(nextVersion, log);

  print(
      "Updated version from '$currentVersion' to $nextVersion with log: $log");
}
