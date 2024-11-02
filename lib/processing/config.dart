import 'dart:convert';
import 'dart:io';

const String fileExtension = '_scrapeconf.json';

class ScrapeConfigFileManager {
  final Directory _directory;
  List<String> scrapeConfigNames = [];

  ScrapeConfigFileManager() : _directory = Directory.current;

  List<String> getScrapeConfigNames() {
    if(scrapeConfigNames.isEmpty) {
      List<String> fileNames = _directory.listSync(followLinks: false)
          .whereType<File>()
          .where((file) => file.path.endsWith(fileExtension))
          .map((file) => file.uri.pathSegments.last)
          .map((filename) => filename.replaceAll(fileExtension, ""))
          .toList();
      fileNames.sort((a, b) => a.compareTo(b));
      scrapeConfigNames = fileNames;
    }
    return scrapeConfigNames;
  }

  void refresh() {
    scrapeConfigNames = [];
    getScrapeConfigNames();
  }

  ScrapeConfig? getScrapeConfigByConfigName(String configName) {
    File configFile = File("${_directory.path}/$configName$fileExtension");
    if(configFile.existsSync()) {
      return ScrapeConfig.fromFile(configFile);
    }
    return null;
  }

  /// Removes the config file with the given name.
  ///
  /// Returns true if the file was deleted, or did not exist anymore. In case the file could not be deleted, false is returned.
  bool removeScrapeConfigByConfigName(String configName) {
    File configFile = File("${_directory.path}/$configName$fileExtension");
    if(configFile.existsSync()) {
      scrapeConfigNames.remove(configName);
      try {
        configFile.deleteSync();
      }
      on FileSystemException catch (ex) {
        // TODO log
        return false;
      }
    }
    return true;
  }

  bool doesScrapeConfigExist(String configName) {
    return scrapeConfigNames.contains(configName);
  }
}

class ScrapeConfig {
  static const nameParamName = 'name';
  static const urlParamName = 'url';
  static const pagingRangeStartParamName = 'pagingRangeStart';
  static const pagingRangeEndParamName = 'pagingRangeEnd';
  static const containerSelectorParamName = 'containerSelector';
  static const childConfigsParamName = 'childConfigs';
  static const csvDelimiterParamName = 'csvDelimiter';
  static const csvWriterHeaderParamName = 'csvWriteHeader';
  String name;
  String url;
  int? pagingRangeStart;
  int? pagingRangeEnd;
  String containerSelector;
  Map<String, Map<String, String>> childConfigs;
  String csvDelimiter;
  bool csvWriteHeader;

  ScrapeConfig(this.name, this.url, this.pagingRangeStart, this.pagingRangeEnd, this.containerSelector, this.childConfigs,
      this.csvDelimiter, this.csvWriteHeader);

  factory ScrapeConfig.fromFile(File file) {
    // decode
    String json = file.readAsStringSync();
    const JsonDecoder decoder = JsonDecoder();
    final Map<String, dynamic> values = decoder.convert(json);

    // rebuild child configs to prevent casting problems
    Map<String, Map<String, String>> transformedChildConfigs = {};
    for(MapEntry<String, dynamic> mapEntry in (values[childConfigsParamName] as Map<String, dynamic>).entries) {
      Map<String, String> transformedChildConfigsMap = {};
      for(MapEntry<String, dynamic> mapEntry in (mapEntry.value as Map<String, dynamic>).entries) {
        transformedChildConfigsMap[mapEntry.key] = mapEntry.value;
      }
      transformedChildConfigs[mapEntry.key] = transformedChildConfigsMap;
    }

    // create config  instance
    return ScrapeConfig(values[nameParamName], values[urlParamName], values[pagingRangeStartParamName],
        values[pagingRangeEndParamName], values[containerSelectorParamName], transformedChildConfigs, values[csvDelimiterParamName],
        values[csvWriterHeaderParamName]);
  }

  void writeScrapeConfigFile(bool overwrite) async {
    // encode
    const JsonEncoder encoder = JsonEncoder.withIndent('  '); // indent with 2 spaces
    String json = encoder.convert(this);
    // save as file
    File file = File(name + fileExtension);
    IOSink sink = file.openWrite();
    sink.write(json);
    await sink.flush();
    await sink.close();
  }

  Map<String, dynamic> toJson() => {
    nameParamName : name,
    urlParamName : url,
    pagingRangeStartParamName : pagingRangeStart,
    pagingRangeEndParamName : pagingRangeEnd,
    containerSelectorParamName : containerSelector,
    childConfigsParamName : childConfigs,
    csvDelimiterParamName : csvDelimiter,
    csvWriterHeaderParamName : csvWriteHeader
  };
}
