import 'dart:io';

import 'package:args/args.dart';
import 'package:assetlib/main.dart';

void main(List<String> args) {
  exitCode = 0; // presume success

  Generator(args);
}

class Generator with AssetClass {
  /// The command-line arguments.
  final List<String> _args;
  ArgResults? results;

  /// Create an instance of [Generator] with the given command-line arguments.
  /// - [args] - The command-line arguments.
  Generator(this._args) {
    results = arguments.parse(_args);

    if (results!['version']) {
      stdout.writeln('assetlib version: $version');
      exit(1);
    }

    if (results!['help']) {
      stdout.writeln('A command-line tool to generate an asset class.\n');
      stdout.writeln('Usage: dart assetlib [options]\n');
      stdout.writeln('Global options:');
      stdout.write('${arguments.usage}\n');
      stdout.writeln('Available commands:');
      exit(1);
    }

    init();
  }

  /// Initialize the generator.
  /// - [results] - The command-line arguments.
  init() async {
    final className = results?['class'] ?? defaultClassName;

    final filePath = results?['output'] ?? defaultOutput;

    if (FileSystemEntity.isDirectorySync(filePath)) {
      stdout.writeln('Generating $className in $filePath...');
    } else {
      stdout.writeln('[INFO] The output path is not a directory.');
      stdout.writeln('[INFO] Run `assetlib --help` for more information.');
      exit(1);
    }

    final File classFile = File(filePath + '/$defaultFileName');

    final IOSink sink = classFile.openWrite();

    for (var i = 0; i < 3; i++) {
      sink.writeln("///* GENERATED CODE - DO NOT MODIFY BY HAND *///");
    }

    sink.writeln('');
    sink.writeln('class $className {');
    sink.writeln('  $className._();\n');

    for (var path in defaultPaths) {
      sink.writeln('/// $path');
      if (FileSystemEntity.isDirectorySync(path)) {
        _writeAssetsFromDirectory(Directory(path), sink);
      } else {
        _writeAssetFromFile(File(path), sink);
      }
      sink.writeln('');
    }

    sink.writeln('}');
    sink.close();

    stdout.writeln('[INFO] Formatting assets file');
    await Process.run("dart", ["format"]);
  }

  final List<String> _writtenAssets = [];

  _writeAssetsFromDirectory(Directory directory, IOSink sink) {
    final entities = directory.listSync().skipWhile((entity) {
      return FileSystemEntity.isDirectorySync(entity.path);
    }).toList();

    if (entities.isEmpty) {
      stdout.writeln('No assets found in ${directory.path}.....');
      return;
    }

    stdout.writeln(
      'Found ${entities.length} file${entities.length > 1 ? 's' : ''} in ${directory.path}',
    );

    for (var entity in entities) {
      stdout.writeln('');

      _writeAssetFromFile(entity, sink);
    }
  }

  _writeAssetFromFile(FileSystemEntity entity, IOSink sink) {
    final String name = entity.path.split('/').last;
    final String key = name.split('.').first;
    final String value = entity.path;

    // TODO: add support for prefix

    final generatedAsset = '  static const String $key = \'$value\';';

    if (_writtenAssets.contains(generatedAsset)) {
      stdout.writeln('Asset $name already exists.');
      return;
    }

    sink.writeln(generatedAsset);
    _writtenAssets.add(generatedAsset);
  }

  factory Generator.fromArgs(List<String> args) {
    return Generator(args);
  }
}
