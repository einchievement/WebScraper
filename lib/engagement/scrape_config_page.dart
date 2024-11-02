import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_scraper/tools/simple_id.dart';

import '../preparation/validator.dart';
import '../preparation/config_context.dart';
import '../processing/config.dart';

class ScraperConfigPage extends StatelessWidget {
  final ScrapeConfigFileManager scrapeConfigFileManager = ScrapeConfigFileManager();


  ScraperConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.all(15),
        child: ScraperConfigMain(
          scrapeConfigFileManager: scrapeConfigFileManager,
        ),
      ),
    );
  }
}

class ScraperConfigMain extends StatefulWidget {
  final ScrapeConfigFileManager scrapeConfigFileManager;

  const ScraperConfigMain({super.key, required this.scrapeConfigFileManager});

  @override
  State<StatefulWidget> createState() {
    return ScraperConfigMainState();
  }
}

class ScraperConfigMainState extends State<ScraperConfigMain> {
  final _formKey = GlobalKey<FormState>();
  ConfigContext configContext = ConfigContext.withDefault();

  void _executeScrape() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();
    ScrapeConfig? scrapeConfig = configContext.toScrapeConfig();
    if (scrapeConfig == null) {
      return;
    }
    scrapeConfig.writeScrapeConfigFile(true);
    // scrape(scrapeConfig);
  }

  void _changeConfigContext(String configName) {
    ScrapeConfig? scrapeConfig = widget.scrapeConfigFileManager.getScrapeConfigByConfigName(configName);
    ConfigContext scrapeConfigContext;
    if (scrapeConfig != null) {
      scrapeConfigContext = ConfigContext.withConfig(scrapeConfig);
    }
    else {
      scrapeConfigContext = ConfigContext.withDefault();
    }

    setState(() {
      configContext = scrapeConfigContext;
    });
  }

  void _createNewConfigContext() {
    setState(() {
      configContext = ConfigContext.withDefault();
    });
  }

  void _deleteCurrentConfig() {
    if (configContext.configName == null) {
      // current ConfigContext has not been saved yet, simply reset
      _createNewConfigContext();
      return;
    }
    bool deleteResult = widget.scrapeConfigFileManager.removeScrapeConfigByConfigName(configContext.configName!);
    if (deleteResult) {
      _createNewConfigContext();
    }
    // TODO tell user file could not be deleted
  }

  void _duplicateCurrentConfig() {
    String? configName = configContext.configName;
    if (configName == null) {
      _createNewConfigContext();
      return;
    }
    ScrapeConfig? scrapeConfig = widget.scrapeConfigFileManager.getScrapeConfigByConfigName(configName);
    if (scrapeConfig == null) {
      _createNewConfigContext();
      return;
    }
    ConfigContext duplicateContext = ConfigContext.withConfig(scrapeConfig);
    duplicateContext.configName = null;

    setState(() {
      configContext = duplicateContext;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        Row(
          children: [
            DropdownMenu<String>(
              label: const Text('Config'),
              width: 500,
              controller: TextEditingController(text: configContext.configName ?? "New Configuration ..."),
              dropdownMenuEntries: widget.scrapeConfigFileManager.getScrapeConfigNames().map((e) => DropdownMenuEntry<String>(value: e, label: e)).toList(),
              onSelected: (String? value) {
                if (!Validator.isEmpty(value)) {
                  _changeConfigContext(value!);
                }
              },
              // TODO update list, maybe with a refresh button
            ),
            const Padding(
                padding: EdgeInsets.symmetric(horizontal:  5)
            ),
            IconButton(
              onPressed: _createNewConfigContext,
              icon: const Icon(Icons.add),
            ),
            IconButton(
              onPressed: configContext.configName == null ? null : _duplicateCurrentConfig,
              icon: const Icon(Icons.content_copy),
            ),
            IconButton(
              onPressed: _deleteCurrentConfig,
              icon: const Icon(Icons.delete_outline),
            ),
            OutlinedButton(
                onPressed: _executeScrape,
                child: const Text("Execute")
            ),
          ],
        ),
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 15)
        ),
        const Row(
          children: [
            Text('Configuration Details')
          ],
        ),
        // TODO add info if scrape config has been saved
        const VerticalSpacing(),
        Expanded(
          child: ScrapeConfigForm(
            configContext: configContext,
            formKey: _formKey,
          ),
        )
      ],
    );
  }
}

class ScrapeConfigForm extends StatefulWidget {
  final ConfigContext configContext;
  final GlobalKey<FormState> formKey;

  const ScrapeConfigForm({super.key, required this.configContext, required this.formKey});

  @override
  State<StatefulWidget> createState() {
    return ScrapeConfigFormState();
  }
}

class ScrapeConfigFormState extends State<ScrapeConfigForm> {

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
            width: 500,
            child: TextFormField(
              enabled: Validator.isEmpty(widget.configContext.configName),
              controller: TextEditingController(text: widget.configContext.configName),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Name',
              ),
              validator: (String? value) {
                return Validator.isEmpty(value) ? "Cannot be empty" : null;
              },
              onSaved: (String? value) {
                widget.configContext.configName = value;
              },
            ),
          ),
          const VerticalSpacing(),
          SizedBox(
            width: 1000,
            child: TextFormField(
              controller: TextEditingController(text: widget.configContext.url),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'URL',
              ),
              validator: (String? value) {
                return Validator.validateURL(value) ? null : "Enter a valid URL";
              },
              onSaved: (String? value) {
                widget.configContext.url = value!;
              },
            ),
          ),
          const VerticalSpacing(),
          Row(
            children: [
              SizedBox(
                width: 175,
                child: TextFormField(
                  controller: TextEditingController(text: widget.configContext.pagingStart?.toString()),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Paging Range Start',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (String? value) {
                    return Validator.validatePageNumber(value) ? null : "Enter a valid Number";
                  },
                  onSaved: (String? value) {
                    if (Validator.isEmpty(value)) {
                      widget.configContext.pagingStart = null;
                      return;
                    }
                    int? parsed = int.tryParse(value!);
                    if (parsed != null) {
                      widget.configContext.pagingStart = parsed;
                    }
                  },
                ),
              ),
              const HorizontalSpacing(),
              SizedBox(
                width: 175,
                child: TextFormField(
                  controller: TextEditingController(text: widget.configContext.pagingEnd?.toString()),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Paging Range End',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (String? value) {
                    return Validator.validatePageNumber(value) ? null : "Enter a valid Number";
                  },
                  onSaved: (String? value) {
                    if (Validator.isEmpty(value)) {
                      widget.configContext.pagingEnd = null;
                      return;
                    }
                    int? parsed = int.tryParse(value!);
                    if (parsed == null) {
                      widget.configContext.pagingEnd = parsed;
                    }
                  },
                ),
              ),
            ],
          ),
          const VerticalSpacing(),
          Row(
            children: [
              DropdownMenu<CsvDelimiter>(
                label: const Text('csv Delimiter'),
                width: 175,
                enableSearch: false,
                initialSelection: CsvDelimiter.getDelimiterByValue(widget.configContext.delimiter),
                dropdownMenuEntries: CsvDelimiter.values.map<DropdownMenuEntry<CsvDelimiter>>((CsvDelimiter delimiter) {
                  return DropdownMenuEntry<CsvDelimiter>(value: delimiter, label: delimiter.name);
                }).toList(),
                onSelected: (CsvDelimiter? delimiter) {
                  widget.configContext.delimiter = delimiter?.value ?? CsvDelimiter.comma.value;
                },
              ),
              const HorizontalSpacing(),
              DropdownMenu<bool>(
                label: const Text('save Header?'),
                width: 175,
                enableSearch: false,
                initialSelection: widget.configContext.saveHeader,
                dropdownMenuEntries: const [
                  DropdownMenuEntry<bool>(value: true, label: 'yes'),
                  DropdownMenuEntry<bool>(value: false, label: 'no'),
                ],
                onSelected: (bool? header) {
                  widget.configContext.saveHeader = header ?? true;
                },
              ),
            ],
          ),
          const VerticalSpacing(),
          SizedBox(
            width: 530,
            child: TextFormField(
              controller: TextEditingController(text: widget.configContext.containerSelector),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Parent Selector',
              ),
              validator: (String? value) {
                return (value == null || value.isEmpty) ? "Cannot be empty" : null;
              },
              onSaved: (String? value) {
                widget.configContext.containerSelector = value!;
              },
            ),
          ),
          Expanded(
              child: ScrapeConfigFormChildConfig(
                configContext: widget.configContext,
              ),
          ),
        ],
      ),
    );
  }
}

class ScrapeConfigFormChildConfigRowDivider extends StatelessWidget {
  final VoidCallback callback;

  const ScrapeConfigFormChildConfigRowDivider({super.key, required this.callback});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // use same length as URL field; 960 line width + 40 button width
        const SizedBox(
          width: 960,
          child: Divider(
            height: 10,
            thickness: 2,
            color: Colors.grey,
          ),
        ),
        IconButton.outlined(
          onPressed: callback,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class ScrapeConfigFormChildConfig extends StatefulWidget {
  final ConfigContext configContext;

  const ScrapeConfigFormChildConfig({super.key, required this.configContext});

  @override
  State<StatefulWidget> createState() {
    return ScrapeConfigFormChildConfigState();
  }
}

class ScrapeConfigFormChildConfigState extends State<ScrapeConfigFormChildConfig> {
  List<Widget> items = [];
  bool changedByThis = false;

  void insertRow(int index) {
    setState(() {
      items.insert(index, createScrapeConfigFormChildConfigRow());
      changedByThis = true;
    });
  }

  // TODO remove?
  void removeRow(int index) {
    setState(() {
      items.removeAt(index);
      changedByThis = true;
    });
  }

  void removeWidget(Widget w) {
    String rowKeyString = w.key!.toString();
    widget.configContext.removeSubConfig(rowKeyString);
    setState(() {
      items.remove(w);
      changedByThis = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!changedByThis) {
      // change came from outside, meaning config context changed
      items = [];
      if ( widget.configContext.childConfigs.isEmpty) {
        items.add(createScrapeConfigFormChildConfigRow());
        items.add(createScrapeConfigFormChildConfigRow());
      }
      else {
        for (MapEntry<String, Map<String, String>> mapEntry in widget.configContext.childConfigs.entries) {
          items.add(createScrapeConfigFormChildConfigRow(id: mapEntry.key, name: mapEntry.value["name"], selector: mapEntry.value["selector"],
              selectionType: SelectionType.getTypeByValue(mapEntry.value["type"])));
        }
      }
    }
    changedByThis = false;

    List<Widget> rows = [ScrapeConfigFormChildConfigRowDivider(key: Key(IDGenerator.generateID()), callback: () => insertRow(0),)]; // index is position to insert new element
    int counter = 0;

    for (Widget w in items) {
      // duplicate current counter value, because anonymous function of IconButton's onPressed
      // uses the reference of int, not the value
      int currentCounter = counter;

      rows.add(w);
      rows.add(ScrapeConfigFormChildConfigRowDivider(key: Key(IDGenerator.generateID()), callback: () => insertRow(currentCounter + 1)));

      counter++;
    }

    return ListView(
      children: rows,
    );
  }

  Widget createScrapeConfigFormChildConfigRow({String? id, String? name, String? selector, SelectionType selectionType = SelectionType.text})
  {
    String rowKeyString;
    if (id == null) {
      rowKeyString = IDGenerator.generateID();
    }
    else {
      rowKeyString = id;
    }
    Key rowKey = Key(rowKeyString);
    Row row = Row(
      key: rowKey,
      children: [
        SizedBox(
          width: 250,
          child: TextFormField(
            controller: TextEditingController(text: name),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Element Name',
            ),
            onSaved: (String? value) {
              if (value == null || value.isEmpty) {
                return;
              }
              widget.configContext.putSubConfig(rowKeyString, "name", value);
            },
          ),
        ),
        const HorizontalSpacing(),
        DropdownMenu<SelectionType>(
          label: const Text('Type'),
          width: 150,
          enableSearch: false,
          initialSelection: selectionType,
          dropdownMenuEntries: SelectionType.values.map<DropdownMenuEntry<SelectionType>>((SelectionType type) {
            return DropdownMenuEntry<SelectionType>(value: type, label: type.name);
          }).toList(),
          onSelected: (SelectionType? type) {
            widget.configContext.putSubConfig(rowKeyString, "type", type?.value ?? SelectionType.text.value);
          },
        ),
        const HorizontalSpacing(),
        SizedBox(
          // fill up space to be same length as URL field
          width: 528,
          child: TextFormField(
            controller: TextEditingController(text: selector),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Element Selector',
            ),
            onSaved: (String? value) {
              if (value == null || value.isEmpty) {
                return;
              }
              widget.configContext.putSubConfig(rowKeyString, "selector", value);
            },
          ),
        ),
      ],
    );

    IconButton button = IconButton(
      onPressed: () => removeWidget(row),
      icon: const Icon(Icons.delete_outline),
    );

    row.children.add(button);

    return row;
  }
}

class VerticalSpacing extends StatelessWidget {
  const VerticalSpacing({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8)
    );
  }
}

class HorizontalSpacing extends StatelessWidget {
  const HorizontalSpacing({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8)
    );
  }
}
