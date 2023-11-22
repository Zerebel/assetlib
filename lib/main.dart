import 'dart:io';

import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

mixin AssetClass {
  /// The [ArgParser] for parsing the command-line arguments.
  /// - [path] - Path to the asset directory.
  /// - [class] - Name of the generated asset class.
  /// - [output] - Path to the generated asset class file.
  /// - [prefix] - Prefix to add to the asset class members.
  /// - [help] - Show this help message.
  /// - [version] - Show the version of this application.
  ArgParser get arguments => ArgParser()
    // TODO: path from arguments should exist in pubspec.yaml
    ..addOption('path',
        abbr: 'p', defaultsTo: '.', help: 'Path to the asset directory.')
    ..addOption('class',
        abbr: 'c',
        defaultsTo: defaultClassName,
        help: 'Name of the generated asset class.')
    ..addOption('output',
        abbr: 'o',
        defaultsTo: defaultOutput,
        help: 'Path to the generated asset class file.')
    ..addOption('prefix',
        abbr: 'x',
        defaultsTo: '',
        help: 'Prefix to add to the asset class members.')
    ..addFlag('help',
        abbr: 'h', negatable: false, help: 'Show this help message.')
    ..addFlag('version',
        abbr: 'v',
        negatable: false,
        help: 'Show the version of this application.');

  /// The content of the [pubspec.yaml] file.
  final _pubspec = loadYaml(File('pubspec.yaml').readAsStringSync());

  /// - [version] - Version of the application.
  String get version => _pubspec['version'];

  /// Default Directory for assets from pubspec.yaml
  /// - [path] - Default Path to the asset directory.
  ///     default: 'assets/'
  YamlList get defaultPaths {
    if (_pubspec['flutter'] == null) {
      throw Exception('flutter section not found in pubspec.yaml');
    }
    return _pubspec['flutter']['assets'];
  }

  /// - [Class] - Default Name of the generated asset class.
  ///    default: 'ProjectNameAssets'
  String get defaultClassName {
    if (_pubspec['name'] == null) {
      throw Exception('name section not found in pubspec.yaml');
    }

    // capitalize first word
    final name = _pubspec['name'].toString().split(' ').map((word) {
      return word[0].toUpperCase() + word.substring(1);
    }).join('');

    //TODO: Minor suggestion
    // final k = _pubspec['name'].toString().split("").first.toUpperCase();

    return '${name}Assets';
  }

  /// - [File] - Default name of the generated asset class file.
  ///
  String get defaultFileName {
    if (_pubspec['name'] == null) {
      throw Exception('name section not found in pubspec.yaml');
    }

    final name = _pubspec['name'] as String;

    return '${name}_assets.dart';
  }

  /// - [output] - Default Path to the generated asset class file.
  ///   default: 'lib/assets.dart'
  String get defaultOutput {
    final String path = 'lib/';
    if (!(Directory(path).existsSync())) {
      throw Exception('lib directory not found');
    }

    return path;
  }
}
