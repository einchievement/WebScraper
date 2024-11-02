import '../processing/config.dart';
import '../tools/simple_id.dart';

class ConfigContext {
  String? configName;
  String? url;
  int? pagingStart;
  int? pagingEnd;
  late String delimiter;
  late bool saveHeader;
  String? containerSelector;
  Map<String, Map<String, String>> childConfigs = {};

  ConfigContext.withDefault()
      : delimiter = CsvDelimiter.comma.value,
        saveHeader = true;

  ConfigContext.withConfig(ScrapeConfig config) {
    configName = config.name;
    url = config.url;
    pagingStart = config.pagingRangeStart;
    pagingEnd = config.pagingRangeEnd;
    delimiter = config.csvDelimiter;
    saveHeader = config.csvWriteHeader;
    containerSelector = config.containerSelector;

    for(MapEntry<String, Map<String, String>> mapEntry in config.childConfigs.entries) {
      String id = IDGenerator.generateID();
      Map<String, String> values = Map.from(mapEntry.value);
      values["name"] = mapEntry.key;

      if (values["type"] == SelectionType.attribute.value) {
        values["selector"] = "${values["selector"]}|${values.remove("attributeName")}";
      }

      childConfigs[id] = values;
    }
  }

  void reset() {
    configName = null;
    url = null;
    pagingStart = null;
    pagingEnd = null;
    delimiter = CsvDelimiter.comma.value;
    saveHeader = true;
    childConfigs = {};
  }

  void putSubConfig(String id, String name, String value) {
     Map<String, String>? sub = childConfigs[id];
     if (sub == null) {
       childConfigs[id] = sub = {};
     }
     sub[name] = value;
  }

  void removeSubConfig(String id) {
    childConfigs.remove(id);
  }

  void validateSubConfigs() {
    for (Map<String, String> map in childConfigs.values) {
      if (map["type"] == null) {
        map["type"] = SelectionType.text.value;
      }
    }
  }

  ScrapeConfig? toScrapeConfig() {
    if (configName == null || containerSelector == null || url == null) {
      return null;
    }

    validateSubConfigs();
    Map<String, Map<String, String>> alteredChildConfigs = {};

    for (Map<String, String> value in childConfigs.values) {
      Map<String, String> valueClone = Map.from(value);

      if (valueClone["type"] == SelectionType.attribute.value) {
        String selector = valueClone["selector"]!;
        List<String> selectorAttribute = selector.split("|");
        // if no attribute for this selector is defined, use it as text
        if (selectorAttribute.length < 2) {
          valueClone["type"] == SelectionType.text.value;
        }
        // selector contains multiple pipes, use only the last as attribute and join the rest
        else if (selectorAttribute.length > 2) {
          String attributeName = selectorAttribute.removeLast();
          String selector = selectorAttribute.join("|");
          valueClone["attributeName"] = attributeName;
          valueClone["selector"] = selector;
        }
        else {
          valueClone["attributeName"] = selectorAttribute.last;
          valueClone["selector"] = selectorAttribute.first;
        }
      }

      String? name = valueClone.remove("name");
      if (name != null) {
        alteredChildConfigs[name] = valueClone;
      }
    }

    return ScrapeConfig(configName!, url!, pagingStart, pagingEnd, containerSelector!, alteredChildConfigs, delimiter, saveHeader);
  }
}

enum SelectionType {
  text('Text', 'text'),
  attribute('Attribute', 'attribute');

  const SelectionType(this.name, this.value);

  final String name;
  final String value;

  static SelectionType getTypeByValue(String? value) {
    if (value == null) {
      return SelectionType.text;
    }

    for (SelectionType type in SelectionType.values) {
      if (type.value == value) {
        return type;
      }
    }
    return SelectionType.text;
  }
}

enum CsvDelimiter {
  comma('comma', ','),
  semicolon('semicolon', ';'),
  colon('colon', ':'),
  space('space', ' '),
  tab('tab', '\t');

  const CsvDelimiter(this.name, this.value);

  final String name;
  final String value;

  static CsvDelimiter getDelimiterByValue(String? value) {
    if (value == null) {
      return CsvDelimiter.comma;
    }

    for (CsvDelimiter delimiter in CsvDelimiter.values) {
      if (delimiter.value == value) {
        return delimiter;
      }
    }
    return CsvDelimiter.comma;
  }
}
