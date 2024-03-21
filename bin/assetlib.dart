import 'dart:io';
import 'package:assetlib/main.dart';

void main(List<String> args) {
  exitCode = 0; // presume success

  Generator(args);
}

class Generator with AssetClass {
  /// The command-line arguments.
  final List<String> _args;
  late final Map<String, dynamic> _results;

  /// Create an instance of [Generator] with the given command-line arguments.
  /// - [args] - The command-line arguments.
  Generator(this._args) {
    final ArgPasser arguments = ArgPasser(_args);

    if (arguments.hasVersion) {
      stdout.writeln('assetlib version: ${arguments.version}');
      exit(1);
    }

    if (arguments.hasHelp) {
      stdout.writeln('A command-line tool to generate an asset class.\n');
      stdout.writeln('Usage: dart assetlib [options]\n');
      stdout.writeln('Global options:');
      stdout.write('${arguments.usage}\n');
      exit(1);
    }

    _results = arguments.parse();

    init();
  }

  /// Initialize the generator.
  /// - [results] - The command-line arguments.
  init() {
    final className = _results['className'] ?? defaultClassName;

    var filePath = _results['output'] ?? defaultOutput;

    filePath = _results['source'] ?? (_results['source'] ?? '') + filePath;

    if (FileSystemEntity.isDirectorySync(filePath)) {
      stdout.writeln('Generating $defaultFileName in $filePath');
    } else {
      stdout.writeln('The output path is not a directory.');
      stdout.writeln('Run `assetlib --help` for more information.');
      exit(1);
    }

    final File classFile = File('$filePath/$defaultFileName');

    final IOSink sink = classFile.openWrite();

    for (var i = 0; i < 3; i++) {
      sink.writeln("///* GENERATED CODE - DO NOT MODIFY BY HAND *///");
    }

    sink.writeln('');
    sink.writeln('class $className {');
    sink.writeln('  $className._();\n');

    for (var path in defaultPaths) {
      if (FileSystemEntity.isDirectorySync(path)) {
        _writeAssetsFromDirectory(
          Directory(path),
          sink,
          _results['prefix'],
          classFile,
        );
      } else {
        _writeAssetFromFile(File(path), sink, _results['prefix']);
      }
      sink.writeln('');
    }

    sink.writeln('}');
    sink.close();

    // format the generated file
    Process.run('dart', ['format', classFile.path]).then((result) {
      if (result.exitCode == 0) {
        stdout.writeln('Generated $className in $filePath');
      } else {
        stdout.writeln('Could not format ${classFile.path}');
      }
    });
  }

  final List<Map<String, dynamic>> _writtenAssets = [];

  _writeAssetsFromDirectory(
    Directory directory,
    IOSink sink,
    String? prefix,
    File classFile,
  ) {
    final List<FileSystemEntity> entities = directory.listSync();

    for (var entity in entities) {
      if (FileSystemEntity.isDirectorySync(entity.path)) {
        _writeAssetsFromDirectory(
          Directory(entity.path),
          sink,
          prefix,
          classFile,
        );
      } else if (entity.path != classFile.path) {
        if (_writtenAssets.any((element) => element['path'] == entity.path)) {
          continue;
        }
        stdout.writeln('');
        _writeAssetFromFile(entity, sink, prefix);
      }
    }

    if (entities.isEmpty) {
      stdout.writeln('No assets found in ${directory.path}.....');
      return;
    }
  }

  _writeAssetFromFile(FileSystemEntity entity, IOSink sink, String? prefix) {
    if (entity.path.endsWith('.dart')) {
      stdout.writeln('Skipping ${entity.path}.....');
      return;
    }

    final String name = entity.path.split('/').last;
    final String key = (prefix ?? '') + name.split('.').first;
    final String value = entity.path;

    if (key.contains(RegExp(r'[^a-zA-Z0-9_]'))) {
      stdout.writeln(
          'Warning: $key contains invalid characters. Replacing with a valid name...');
    }
    var modifiedKey = key.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

    if (_writtenAssets.any((element) => element['key'] == modifiedKey)) {
      stdout.writeln('Asset $modifiedKey already exists.');
      stdout.writeln('Appending a number to the asset name.....');

      final asset =
          _writtenAssets.firstWhere((element) => element['key'] == modifiedKey);
      final count = int.parse(asset['count']?.toString() ?? '0') + 1;

      modifiedKey = modifiedKey + count.toString();

      asset['count'] = count;

      _writtenAssets.add({'path': entity.path, 'key': modifiedKey, 'count': 0});
    }

    final generatedAsset = '  static const String $modifiedKey = \'$value\';';

    sink.writeln('/// ${entity.path}');

    sink.writeln(generatedAsset);

    _writtenAssets.add({'path': entity.path, 'key': modifiedKey});
  }

  factory Generator.fromArgs(List<String> args) {
    return Generator(args);
  }
}
