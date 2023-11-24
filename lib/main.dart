import 'dart:io';

mixin AssetClass {
  final pubspecFileContent = File('pubspec.yaml').readAsStringSync();

  String? get name {
    return RegExp(r'name: (.*)').firstMatch(pubspecFileContent)?.group(1);
  }

  /// Get name of the application from pubspec.yaml
  /// - [name] - Name of the application.
  String get defaultClassName {
    if (name == null) {
      throw Exception('name section not found in pubspec.yaml');
    }

    return '${name!.substring(0, 1).toUpperCase() + name!.substring(1)}Assets';
  }

  /// - [defaultPaths] - Default Directory for assets from pubspec.yaml
  /// - [path] - Default Path to the asset directory.
  List<String> get defaultPaths {
    final lines = pubspecFileContent.split('\n');
    final assetsIndex = lines.indexWhere((line) => line.trim() == 'assets:');
    if (assetsIndex == -1) {
      throw Exception('assets section not found in pubspec.yaml');
    }

    final paths = <String>[];
    for (var i = assetsIndex + 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('-')) {
        paths.add(line.substring(1).trim());
      } else if (line.isNotEmpty) {
        break;
      }
    }

    return paths;
  }

  /// - [defaultFileName] - Default Name of the generated asset class.
  ///   default: 'projectName_assets'
  String get defaultFileName => '${name}_assets.dart';

  /// - [defaultOutput] - Default Path to the generated asset class file.
  ///  default: 'lib/'
  String get defaultOutput {
    final String path = 'lib/';
    if (!(Directory(path).existsSync())) {
      throw Exception('lib directory not found');
    }

    return path;
  }
}

class ArgPasser {
  final List<String> args;

  ArgPasser(this.args);

  // parse function
  Map<String, dynamic> parse() {
    // check for invalid arguments and unknown flags
    for (var arg in args) {
      if (arg.startsWith('-')) {
        if (![
          '-v',
          '--version',
          '-h',
          '--help',
          '-p',
          '--prefix',
          '-o',
          '--output',
          '-c',
          '--class'
        ].contains(arg)) {
          throw Exception('''Unknown flag $arg
          Run `assetlib --help` for more information.
          ''');
        }
      } else {
        throw Exception('''Invalid argument $arg
            Run `assetlib --help` for more information.
            ''');
      }
    }

    return {
      'version': version,
      'help': hasHelp,
      'prefix': hasPrefix,
      'output': output,
      'className': className,
    };
  }

  bool get hasVersion => args.contains('-v') || args.contains('--version');

  bool get hasHelp => args.contains('-h') || args.contains('--help');

  bool get hasPrefix => args.contains('-p') || args.contains('--prefix');

  String? get prefix {
    final index = args.indexWhere((arg) => arg == '-p' || arg == '--prefix');
    if (index == -1) {
      return null;
    }

    return args[index + 1];
  }

  String? get output {
    final index = args.indexWhere((arg) => arg == '-o' || arg == '--output');
    if (index == -1) {
      return null;
    }

    return args[index + 1];
  }

  String? get className {
    final index = args.indexWhere((arg) => arg == '-c' || arg == '--class');
    if (index == -1) {
      return null;
    }

    return args[index + 1];
  }

  String version = '0.0.1';

  String usage = '''
    -h, --help       Show this help message.
    -v, --version    Show the version of this application.
    -p, --prefix     Prefix to add to the asset class members.
    -o, --output     Path to the generated asset class file.
    -c, --class      Name of the generated asset class.
  ''';
}
