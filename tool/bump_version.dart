// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const changeLogFiles = ['CHANGELOG.md'];
const filesToUpdate = [
  'pubspec.yaml',
  'ios/sweph.podspec',
  'macos/sweph.podspec',
];

class Version {
  final int _major;
  final int _minor;
  final int _patch;
  final String? _buildNumber;

  Version(this._major, this._minor, this._patch, [this._buildNumber]);

  @override
  String toString() {
    if (_buildNumber == null) {
      return '$_major.$_minor.$_patch';
    } else {
      return '$_major.$_minor.$_patch+$_buildNumber';
    }
  }

  Version nextPatch() => Version(_major, _minor, _patch + 1, _buildNumber);
  Version nextMinor() => Version(_major, _minor + 1, 0, _buildNumber);
  Version nextMajor() => Version(_major + 1, 0, 0, _buildNumber);

  static Version fromString(String? versionStr, [String? buildNumber]) {
    RegExp pattern = RegExp(r'^(?:(\d+)\.(\d+)\.(\d+)(?:\+(.+))?)$');

    if (versionStr == null || !pattern.hasMatch(versionStr)) {
      return Version(0, 0, 1, buildNumber);
    }

    final match = pattern.firstMatch(versionStr)!;
    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    final patch = int.parse(match.group(3)!);
    buildNumber ??= match.group(4);

    return Version(major, minor, patch, buildNumber);
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
    final prefix = '## $to\n\n- $log\n\n';
    file.writeAsStringSync(prefix);
    file.writeAsStringSync(contents, mode: FileMode.append);
  }
}

String? getVersion(File file, RegExp pattern) {
  for (final line in file.readAsLinesSync()) {
    final match = pattern.firstMatch(line);
    if (match == null) {
      continue;
    }
    return match.group(1)!;
  }
  return null;
}

void main(List<String> args) {
  final rootDir = Directory.current;

  final pubspecFile = File('${rootDir.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Run from root folder');
    return;
  }

  final bumpType = ['major', 'minor', 'patch'];
  if (args.isEmpty || !bumpType.contains(args[0])) {
    print('Specify major, minor, or patch');
    return;
  }

  late Version nextVersion;
  String? nativeVersion = getVersion(
      File('${rootDir.path}/native/sweph/src/sweph.h'),
      RegExp(r'^#define SE_VERSION\s+"(.*)"\s*$'));
  Version currentVersion = Version.fromString(
      getVersion(pubspecFile, RegExp(r'^version: (.*)$')), nativeVersion);

  if (args[0] == 'major') {
    nextVersion = currentVersion.nextMajor();
  } else if (args[0] == 'minor') {
    nextVersion = currentVersion.nextMinor();
  } else if (args[0] == 'patch') {
    nextVersion = currentVersion.nextPatch();
  }

  stdout.write('Enter changelog: ');
  final log = stdin.readLineSync(encoding: utf8);
  if (log == null) {
    return;
  }

  updateVersion(currentVersion, nextVersion);
  changeLog(nextVersion, log);

  print(
      "Updated version from '$currentVersion' to $nextVersion with log: $log");
}
