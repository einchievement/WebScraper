import 'dart:io';

import 'package:http/http.dart';
import 'package:html/parser.dart';
import 'package:html/dom.dart';
import 'package:web_scraper/processing/config.dart';

class ScrapePageResult {
  bool success;
  List<Map<String, String?>> result;

  ScrapePageResult.failure() : success = false, result = [];
  ScrapePageResult.success(this.result) : success = true;
}

Future<void> scrape(ScrapeConfig config) async {
  String pagingPlaceholder = '\${page}';
  List<Map<String, String?>> result = [];

  // check if url has scheme, if not fallback to https
  String url = config.url;
  Uri uri = Uri.parse(url);
  if (!uri.hasScheme) {
    uri = Uri.https(uri.authority, uri.path, uri.queryParametersAll);
    url = uri.toString();
  }

  Client client = Client();
  try {
    if (!url.contains(pagingPlaceholder)) {
      ScrapePageResult scrapeResult = await scrapePage(client, url, config);
      result = scrapeResult.result;
    }
    else {
      int page = config.pagingRangeStart ?? 1;
      ScrapePageResult scrapeResult;
      do {
        String pagedUrl = url.replaceFirst(pagingPlaceholder, page.toString());
        scrapeResult = await scrapePage(client, pagedUrl, config);
        result.addAll(scrapeResult.result);
        page++;
      }
      while (scrapeResult.success && (config.pagingRangeEnd == null || (config.pagingRangeEnd ?? 0) >= page));
    }
  }
  finally {
    client.close();
  }

  _writeFile(config.name, result, config.childConfigs.keys.toList(), config.csvWriteHeader, config.csvDelimiter);
}

Future<ScrapePageResult> scrapePage(Client client, String url, ScrapeConfig config) async {
  // request
  Response response = await client.get(Uri.parse(url));

  if (response.statusCode != 200) {
    return ScrapePageResult.failure();
  }

  // parse, https://www.w3.org/TR/selectors-4/#overview
  Document document = parse(response.body);
  List<Element> elementContainer = document.querySelectorAll(config.containerSelector);

  if (elementContainer.isEmpty) {
    return ScrapePageResult.failure();
  }

  List<Map<String, String?>> entries = [];

  for (Element element in elementContainer) {
    Map<String, String?> values = {};

    for (MapEntry<String, Map<String, String>> childConfig in config.childConfigs.entries) {
      String? value;
      switch (childConfig.value['type']) {
        case 'text':
          value = _getText(element, childConfig.value['selector']);
        case 'attribute':
          value = _getAttributeValue(element, childConfig.value['selector'], childConfig.value['attributeName']);
        default:
          continue;
      }
      values[childConfig.key] = value;
    }

    entries.add(values);
  }

  return ScrapePageResult.success(entries);
}

String? _getText(Element e, String? selector) {
  if (selector == null) {
    return null;
  }
  Element? child = e.querySelector(selector);
  if (child == null) {
    return null;
  }
  return child.text.trim();
}

String? _getAttributeValue(Element e, String? selector, String? attributeName) {
  if (selector == null || attributeName == null) {
    return null;
  }
  Element? child = e.querySelector(selector);
  if (child == null) {
    return null;
  }
  return child.attributes[attributeName];
}

Future<void> _writeFile(String filename, List<Map<String, String?>> content, List<String> header, bool includeHeader, String delimiter) async {
  List<String> lines = [];
  if (includeHeader) {
    lines.add(header.join(delimiter));
  }
  for (Map<String, String?> e in content) {
    String value = '';
    int length = 0;
    for (String h in header) {
      value += e[h] ?? "";
      length++;
      if (length < e.length) {
        value += delimiter;
      }
    }
    lines.add(value);
  }

  File file = File('$filename.csv');
  IOSink sink = file.openWrite();
  sink.writeAll(lines, '\n');
  await sink.flush();
  await sink.close();
}
