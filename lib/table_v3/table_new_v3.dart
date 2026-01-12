import 'dart:convert';
import 'package:demo_1/table_v3/test_table_new_v3.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ------------------------------------------------------------
/// MODEL COLUMN CONFIG
/// ------------------------------------------------------------
class TableColumnConfig {
  final String key;
  final String title;
  bool visible;
  double width;
  final double minWidth;
  final bool hideOnSmallScreen;

  TableColumnConfig({
    required this.key,
    String? title,
    this.visible = true,
    this.width = 150,
    this.minWidth = 60,
    this.hideOnSmallScreen = false,
  }) : title = title ?? key;

  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'visible': visible,
    'width': width,
    'minWidth': minWidth,
    'hideOnSmallScreen': hideOnSmallScreen,
  };

  static TableColumnConfig fromJson(Map<String, dynamic> json) {
    return TableColumnConfig(
      key: json['key'],
      title: json['title'],
      visible: json['visible'],
      width: (json['width'] as num).toDouble(),
      minWidth: (json['minWidth'] as num).toDouble(),
      hideOnSmallScreen: json['hideOnSmallScreen'] ?? false,
    );
  }

  TableColumnConfig clone() {
    return TableColumnConfig(
      key: key,
      title: title,
      visible: visible,
      width: width,
      minWidth: minWidth,
      hideOnSmallScreen: hideOnSmallScreen,
    );
  }
}

/// ------------------------------------------------------------
/// TABLE CONTROLLER
/// ------------------------------------------------------------
class TableController extends ChangeNotifier {
  final String tableId;

  /// key -> config
  final Map<String, TableColumnConfig> columns = {};

  /// Sort
  String? sortColumn;
  bool sortAsc = true;

  /// Filters (string)
  final Map<String, String> filters = {};

  bool _inited = false;
  bool get inited => _inited;

  TableController({required this.tableId});

  /// init with default configs (and read saved config)
  Future<void> init(List<TableColumnConfig> defaultConfigs) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("table_config_$tableId");

    if (saved != null) {
      final decoded = jsonDecode(saved) as Map<String, dynamic>;
      for (var cfg in defaultConfigs) {
        if (decoded[cfg.key] != null) {
          columns[cfg.key] =
              TableColumnConfig.fromJson(decoded[cfg.key] as Map<String, dynamic>);
        } else {
          columns[cfg.key] = cfg.clone();
        }
      }

      // restore sort & filters if present
      if (decoded['_meta'] != null) {
        final meta = decoded['_meta'] as Map<String, dynamic>;
        sortColumn = meta['sortColumn'];
        sortAsc = meta['sortAsc'] ?? true;
        final savedFilters = meta['filters'] as Map<String, dynamic>?;
        if (savedFilters != null) {
          filters.clear();
          savedFilters.forEach((k, v) => filters[k] = v.toString());
        }
      }
    } else {
      for (var cfg in defaultConfigs) {
        columns[cfg.key] = cfg.clone();
      }
    }

    _inited = true;
    notifyListeners();
  }

  List<TableColumnConfig> getVisibleForWidth(double width) {
    // DO NOT mutate the real config.visible here.
    return columns.values.where((c) {
      if (!c.visible) return false;
      if (c.hideOnSmallScreen && width < 1280) return false;
      return true;
    }).toList();
  }

  /// Toggle visible (user action) — persist immediately
  Future<void> toggleColumn(String key) async {
    final c = columns[key];
    if (c == null) return;
    c.visible = !c.visible;
    await _save();
    notifyListeners();
  }

  /// Update width (called by UI); doesn't accept widths less than minWidth
  Future<void> updateWidth(String key, double newWidth) async {
    final c = columns[key];
    if (c == null) return;
    double w = newWidth.clamp(c.minWidth, 2000);
    if (w == c.width) return;
    c.width = w;
    await _save(); // persist while resizing to keep UX consistent
    notifyListeners();
  }

  /// Update width for two columns at once (current and neighbor)
  Future<void> updateWidthPair(
      String leftKey, String rightKey, double leftDelta) async {
    final left = columns[leftKey];
    final right = columns[rightKey];
    if (left == null || right == null) return;
    final newLeft = (left.width + leftDelta).clamp(left.minWidth, 2000);
    final newRight = (right.width - leftDelta).clamp(right.minWidth, 2000);

    // If one side reached boundary, adjust delta accordingly
    final appliedLeftDelta = newLeft - left.width;
    final appliedRightDelta = right.width - newRight;
    // take the minimum absolute delta to apply consistently
    final applied = (appliedLeftDelta.abs() < appliedRightDelta.abs())
        ? appliedLeftDelta
        : -appliedRightDelta;

    left.width = (left.width + applied).clamp(left.minWidth, 2000);
    right.width = (right.width - applied).clamp(right.minWidth, 2000);

    await _save();
    notifyListeners();
  }

  /// Sorting
  Future<void> sortBy(String key) async {
    if (sortColumn == key) {
      sortAsc = !sortAsc;
    } else {
      sortColumn = key;
      sortAsc = true;
    }
    await _save();
    notifyListeners();
  }

  /// Filtering
  Future<void> updateFilter(String key, String value) async {
    if (value.isEmpty) {
      filters.remove(key);
    } else {
      filters[key] = value;
    }
    await _save();
    notifyListeners();
  }

  /// reset to given defaults
  Future<void> resetToDefaults(List<TableColumnConfig> defaults) async {
    columns.clear();
    for (var c in defaults) {
      columns[c.key] = c.clone();
    }
    sortColumn = null;
    sortAsc = true;
    filters.clear();
    await _save();
    notifyListeners();
  }

  /// clear saved config (e.g. logout)
  Future<void> clearSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("table_config_$tableId");
    // keep current in-memory state as-is; caller can call resetToDefaults if needed
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, dynamic>{};
    columns.forEach((k, v) {
      map[k] = v.toJson();
    });
    // meta (sort + filters)
    map['_meta'] = {
      'sortColumn': sortColumn,
      'sortAsc': sortAsc,
      'filters': filters,
    };
    await prefs.setString("table_config_$tableId", jsonEncode(map));
  }
}

/// ------------------------------------------------------------
/// ADVANCED TABLE WIDGET (row-first, optimized)
/// ------------------------------------------------------------

class TableNewV3 extends StatefulWidget {
  /// initialConfigs: the default column definitions (used for reset / init)
  final List<TableColumnConfig> initialConfigs;

  /// rows: list of data rows; each row is Map<key, dynamic>
  final List<Map<String, dynamic>> rows;

  /// controller (optional). If null, widget will create internal controller.
  final TableController? controller;

  final double headerHeight;
  final double filterHeight;
  final double rowHeight;

  const TableNewV3({
    super.key,
    required this.initialConfigs,
    required this.rows,
    this.controller,
    this.headerHeight = 48,
    this.filterHeight = 44,
    this.rowHeight = 52,
  });

  @override
  State<TableNewV3> createState() => _TableNewV3State();
}

class _TableNewV3State extends State<TableNewV3> {
  late final TableController controller;
  final Map<String, TextEditingController> _filterControllers = {};
  final ScrollController _verticalScroll = ScrollController();
  final ScrollController _horizontalScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? TableController(tableId: 'advanced_table_default');

    // init filter controllers for defaults
    for (var c in widget.initialConfigs) {
      _filterControllers[c.key] = TextEditingController();
    }

    // init controller (async)
    controller.init(widget.initialConfigs).then((_) {
      // restore filter text from controller state if any
      controller.filters.forEach((k, v) {
        if (_filterControllers.containsKey(k)) _filterControllers[k]!.text = v;
      });
      setState(() {}); // trigger build when ready
    });
  }

  @override
  void dispose() {
    for (var t in _filterControllers.values) {
      t.dispose();
    }
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  /// compute visible columns (take responsive into account but DO NOT mutate config)
  List<TableColumnConfig> _visibleCols(double width) {
    return controller.getVisibleForWidth(width);
  }

  /// Build header row (with resize handles)
  Widget _buildHeaderRow(List<TableColumnConfig> visibleCols) {
    return Row(
      children: List.generate(visibleCols.length * 2 - 1, (i) {
        if (i.isEven) {
          final col = visibleCols[i ~/ 2];
          return Container(
            width: col.width,
            height: widget.headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            color: Colors.grey.shade200,
            child: InkWell(
              onTap: () => controller.sortBy(col.key),
              child: Row(
                children: [
                  Expanded(child: Text(col.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                  if (controller.sortColumn == col.key)
                    Icon(controller.sortAsc ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                ],
              ),
            ),
          );
        } else {
          // resize handle between columns
          final left = visibleCols[(i - 1) ~/ 2];
          final right = visibleCols[(i + 1) ~/ 2];
          return _ResizeHandle(
            height: widget.headerHeight + widget.filterHeight,
            onDrag: (dx) {
              controller.updateWidthPair(left.key, right.key, dx);
            },
          );
        }
      }),
    );
  }

  Widget _buildFilterRow(List<TableColumnConfig> visibleCols) {
    return Row(
      children: List.generate(visibleCols.length * 2 - 1, (i) {
        if (i.isEven) {
          final col = visibleCols[i ~/ 2];
          final tc = _filterControllers[col.key]!;
          return Container(
            width: col.width,
            height: widget.filterHeight,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: TextField(
              controller: tc,
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Filter...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              onChanged: (v) => controller.updateFilter(col.key, v),
            ),
          );
        } else {
          return SizedBox(width: _ResizeHandle.handleWidth);
        }
      }),
    );
  }

  /// Build a single row widget (row-based rendering)
  Widget _buildDataRow(List<TableColumnConfig> visibleCols, Map<String, dynamic> row, int rowIndex) {
    return InkWell(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (_){
          return DemoTableV3();
        }));
      },
      child: Row(
            children: List.generate(visibleCols.length * 2 - 1, (i) {
              if (i.isEven) {
                final col = visibleCols[i ~/ 2];
                final value = row[col.key];
                return Container(
                  width: col.width,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.centerLeft,
                  child: _buildCellContent(value),
                );
              } else {
                return SizedBox(width: _ResizeHandle.handleWidth);
              }
            }),
          ),
    );
  }

  Widget _buildCellContent(dynamic value) {
    if (value == null) return const SizedBox();
    if (value is Widget) return value;
    return Text(value.toString(), overflow: TextOverflow.ellipsis);
  }

  /// Apply filter + sort on data and return final list
  List<Map<String, dynamic>> _processRows(List<TableColumnConfig> visibleCols) {
    var data = List<Map<String, dynamic>>.from(widget.rows);

    // FILTER: only apply for filters that exist and whose column is visible in current width
    final activeFilters = controller.filters.entries.where((e) =>
    e.value.trim().isNotEmpty &&
        controller.columns.containsKey(e.key) &&
        visibleCols.any((c) => c.key == e.key));

    for (var f in activeFilters) {
      final k = f.key;
      final q = f.value.toLowerCase();
      data = data.where((r) {
        final val = r[k];
        return val != null &&
            val.toString().toLowerCase().contains(q);
      }).toList();
    }

    // SORT: if sortColumn is set and the column is visible
    if (controller.sortColumn != null &&
        visibleCols.any((c) => c.key == controller.sortColumn)) {
      final key = controller.sortColumn!;
      data.sort((a, b) {
        final va = a[key];
        final vb = b[key];

        // handle nulls
        if (va == null && vb == null) return 0;
        if (va == null) return controller.sortAsc ? -1 : 1;
        if (vb == null) return controller.sortAsc ? 1 : -1;

        // compare by type
        final cmp = _compareDynamic(va, vb);
        return controller.sortAsc ? cmp : -cmp;
      });
    }

    return data;
  }

  /// smart comparator: number -> date -> string fallback
  int _compareDynamic(dynamic a, dynamic b) {
    // numbers
    if (a is num && b is num) {
      return a.compareTo(b);
    }
    // DateTime
    if (a is DateTime && b is DateTime) {
      return a.compareTo(b);
    }
    // try parsing numbers from string
    final an = _tryParseNum(a);
    final bn = _tryParseNum(b);
    if (an != null && bn != null) return an.compareTo(bn);
    // try parse date
    final ad = _tryParseDate(a);
    final bd = _tryParseDate(b);
    if (ad != null && bd != null) return ad.compareTo(bd);
    // fallback to string compare
    return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());
  }

  double? _tryParseNum(dynamic v) {
    try {
      if (v is num) return v.toDouble();
      final s = v.toString();
      return double.tryParse(s.replaceAll(',', ''));
    } catch (_) {
      return null;
    }
  }

  DateTime? _tryParseDate(dynamic v) {
    try {
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString());
    } catch (_) {
      return null;
    }
  }

  /// Settings popup (reset default & toggle)
  Widget _buildSettingsButton() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.settings),
      itemBuilder: (_) {
        final items = <PopupMenuEntry<int>>[];
        // header
        items.add(const PopupMenuItem<int>(
          enabled: false,
          child: Text('Table settings', style: TextStyle(fontWeight: FontWeight.bold)),
        ));
        items.add(const PopupMenuDivider());

        // toggle checkboxes
        int idx = 0;
        for (var c in widget.initialConfigs) {
          final current = controller.columns[c.key] ?? c;
          items.add(CheckedPopupMenuItem<int>(
            checked: current.visible,
            value: idx++,
            child: Row(
              children: [
                Expanded(child: Text(current.title)),
                if (current.hideOnSmallScreen)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Text('(auto hide)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
              ],
            ),
          ));
        }

        items.add(const PopupMenuDivider());
        items.add(PopupMenuItem<int>(
          value: -1,
          child: const Text('Reset to defaults'),
        ));

        return items;
      },
      onSelected: (v) {
        if (v == -1) {
          controller.resetToDefaults(widget.initialConfigs);
          // restore filter text controllers
          for (var c in widget.initialConfigs) {
            _filterControllers[c.key]?.text = '';
          }
        } else if (v >= 0) {
          final key = widget.initialConfigs[v].key;
          controller.toggleColumn(key);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // if controller not inited yet, show spinner
    if (!controller.inited) {
      return const Center(child: CircularProgressIndicator());
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, __) {
        final width = MediaQuery.of(context).size.width;
        final visibleCols = _visibleCols(width);

        // total inner width
        final innerWidth = visibleCols.fold<double>(
            0, (prev, c) => prev + c.width) +
            (_ResizeHandle.handleWidth * (visibleCols.isEmpty ? 0 : visibleCols.length - 1));

        final processed = _processRows(visibleCols);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // settings button row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSettingsButton(),
                // small info
                Text('Showing ${processed.length} / ${widget.rows.length} rows'),
              ],
            ),
            const SizedBox(height: 8),
            // table header + filter (horizontal scroll)
            Expanded(
              child: Column(
                children: [
                  _buildHeaderRow(visibleCols),
                  _buildFilterRow(visibleCols),
                  const Divider(height: 1),
                  // table body (vertical scroll)
                  Expanded(
                    child: Scrollbar(
                      controller: _verticalScroll,
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _verticalScroll,
                        itemCount: processed.length,
                        itemBuilder: (ctx, idx) {
                          final row = processed[idx];
                          final bg = (idx % 2 == 0) ? Colors.white : Colors.grey.shade50;
                          return Container(
                            color: bg,
                            child: _buildDataRow(visibleCols, row, idx),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// small resize handle widget between columns
class _ResizeHandle extends StatefulWidget {
  static const handleWidth = 8.0;
  final double height;
  final void Function(double dx) onDrag;
  const _ResizeHandle({required this.height, required this.onDrag});

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  double _startX = 0.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        _startX = details.globalPosition.dx;
      },
      onPanUpdate: (details) {
        final dx = details.globalPosition.dx - _startX;
        _startX = details.globalPosition.dx;
        widget.onDrag(dx);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeLeftRight,
        child: Container(
          width: _ResizeHandle.handleWidth,
          height: widget.height,
          color: Colors.transparent,
          child: Center(
            child: Container(width: 1, height: widget.height * 0.5, color: Colors.grey.shade400),
          ),
        ),
      ),
    );
  }
}
