import 'package:flutter/material.dart';

/// ==================
/// MODEL
/// ==================
class Mapper {
  Mapper({
    required this.label,
    required this.value,
  });

  String label;
  int value;
}

/// ==================
/// DEMO APP
/// ==================

class DropdownCustom extends StatefulWidget {
  const DropdownCustom({super.key});

  @override
  State<DropdownCustom> createState() => _DropdownCustomState();
}

class _DropdownCustomState extends State<DropdownCustom> {
  final items = [
    Mapper(label: 'Item 1', value: 1),
    Mapper(label: 'Item 2', value: 2),
    Mapper(label: 'Item 3', value: 3),
    Mapper(label: 'Item 4', value: 4),
    Mapper(label: 'Item 5', value: 5),
    Mapper(label: 'Item 6', value: 6),
  ];

  final items2 = List.generate(
    20,
        (i) => Mapper(label: 'Item $i', value: i),
  );

  int? value1Selected;
  int? value2Selected;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 500,
                child: Row(
                  children: [
                    Expanded(
                      child: CustomDropdownMapper(
                        items: items,
                        initialValue: value1Selected,
                        onChanged: (v) {
                          setState(() => value1Selected = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomDropdownMapper(
                        items: items2,
                        initialValue: value2Selected,
                        onChanged: (v) {
                          setState(() => value2Selected = v);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Selected 1: $value1Selected'),
                  InkWell(
                    onTap: (){
                      if(value1Selected == null){
                        value1Selected = 1;
                      }else{
                        value1Selected = (value1Selected??1)+1;
                      }
                      setState(() {});
                    },
                      child: Icon(Icons.add))
                ],
              ),
              Text('Selected 2: $value2Selected'),
            ],
          ),
        ),
      ),
    );
  }
}

/// =================
/// DROPDOWN
/// =================
class CustomDropdownMapper extends StatefulWidget {
  const CustomDropdownMapper({
    super.key,
    required this.items,
    this.initialValue,
    this.onChanged,
  });

  final List<Mapper> items;
  final int? initialValue;
  final ValueChanged<int>? onChanged;

  @override
  State<CustomDropdownMapper> createState() => _CustomDropdownMapperState();
}

class _CustomDropdownMapperState extends State<CustomDropdownMapper> {
  final LayerLink _layerLink = LayerLink();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  OverlayEntry? _overlayEntry;
  Mapper? _selectedItem;
  List<Mapper> _filteredItems = [];
  bool _isOpen = false;

  static const double _itemHeight = 40;
  static const int _maxVisibleItems = 5;

  // @override
  // void initState() {
  //   super.initState();
  //   var tempSelected = widget.items.where(
  //         (e) => e.value == widget.initialValue,
  //   );
  //   if(tempSelected.isNotEmpty){
  //     _selectedItem = tempSelected.first;
  //   }
  //   _filteredItems = List.from(widget.items);
  // }

  void _toggle() => _isOpen ? _close() : _open();

  void _open() {
    FocusScope.of(context).unfocus();

    _searchController.clear();
    _filteredItems = List.from(widget.items);

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);

    setState(() => _isOpen = true);

    /// ⚠️ CHỜ FRAME SAU → ScrollController mới attach
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final index = widget.items.indexWhere(
            (e) => e.value == _selectedItem?.value,
      );

      if (index != -1) {
        _scrollController.jumpTo(index * _itemHeight);
      }
    });
  }

  void _close() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          /// CLICK OUTSIDE
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _close,
            ),
          ),

          /// DROPDOWN
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              offset: Offset(0, size.height + 4),
              showWhenUnlinked: false,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(4),
                child: _buildDropdownContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// SEARCH
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search...',
                isDense: true,
                prefixIcon: Icon(Icons.search, size: 18),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                _filteredItems = widget.items
                    .where(
                      (e) =>
                      e.label.toLowerCase().contains(v.toLowerCase()),
                )
                    .toList();

                _overlayEntry?.markNeedsBuild();
              },
            ),
          ),

          const Divider(height: 1),

          /// LIST
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: _itemHeight * _maxVisibleItems,
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: _filteredItems.map((item) {
                    final selected = item.value == _selectedItem?.value;

                    return InkWell(
                      onTap: () {
                        setState(() => _selectedItem = item);
                        widget.onChanged?.call(item.value);
                        _close();
                      },
                      child: Container(
                        height: _itemHeight,
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12),
                        alignment: Alignment.centerLeft,
                        color: selected
                            ? Colors.blue
                            : Colors.transparent,
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tempSelected = widget.items.where(
          (e) => e.value == widget.initialValue,
    );
    if(tempSelected.isNotEmpty){
      _selectedItem = tempSelected.first;
    }
    _filteredItems = List.from(widget.items);
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedItem?.label??"Choose",
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Icon(
                _isOpen
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
