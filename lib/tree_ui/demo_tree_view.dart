import 'dart:async';
import 'package:flutter/material.dart';

class TreeViewComponent extends StatefulWidget {
  final Function(TreeNodeComponentDTODemo node)? onNodeSelected;

  const TreeViewComponent({super.key, this.onNodeSelected});

  @override
  State<TreeViewComponent> createState() => _TreeViewComponentState();
}

class _TreeViewComponentState extends State<TreeViewComponent> {
  final TextEditingController searchCtrl = TextEditingController();
  final ScrollController scrollCtrl = ScrollController();

  String keyword = "";
  int? selectedId;
  Timer? _debounce;

  List<TreeNodeComponentDTODemo> tree = [];
  List<VisibleNode> visibleNodes = [];

  @override
  void initState() {
    super.initState();

    /// Fake tree demo
    tree = [
      ...List.generate(50, (index) {
        return TreeNodeComponentDTODemo("Tree node ${index + 1}", index + 1,
            expanded: false, children: [
              ...List.generate(5, (subIndex) {
                return TreeNodeComponentDTODemo(
                  "sub tree node ${index}00${subIndex + 1}",
                  int.parse("${index}00${subIndex + 1}"),
                  expanded: false,
                  children: [
                    ...List.generate(5, (subLevel2Index) {
                      return TreeNodeComponentDTODemo(
                          "sub tree node ${subLevel2Index}000${subLevel2Index + 1}",
                          int.parse("${subLevel2Index}000${subLevel2Index + 1}"),
                          expanded: false,
                      );
                    }),
                  ]
                );
              }),
            ]);
      }),
    ];

    visibleNodes = flattenTree(tree);
  }

  void _onSearchChange(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      setState(() => keyword = value.trim());
      visibleNodes = flattenTree(tree, keyword: keyword);
    });
  }

  /// Khi clear search → tự động scroll đến node được chọn
  void _scrollToSelected() {
    if (selectedId == null) return;

    final index = visibleNodes.indexWhere((e) => e.node.id == selectedId);
    if (index < 0) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      scrollCtrl.animateTo(
        index * 40.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    visibleNodes = flattenTree(tree, keyword: keyword);

    return Container(
      width: 300,
      color: Colors.grey.shade100,
      child: Column(
        children: [
          /// Search box
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              onChanged: _onSearchChange,
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: keyword.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      keyword = "";
                      searchCtrl.clear();
                      visibleNodes = flattenTree(tree);
                    });
                    _scrollToSelected();
                  },
                )
                    : null,
              ),
            ),
          ),

          /// Tree view list
          Expanded(
            child: ListView.builder(
              controller: scrollCtrl,
              itemCount: visibleNodes.length,
              itemBuilder: (context, index) {
                VisibleNode item = visibleNodes[index];

                return _TreeNodeWidget(
                  data: item,
                  keyword: keyword,
                  selectedId: selectedId,
                  onExpand: () {
                    setState(() {
                      item.node.expanded = !item.node.expanded;
                    });
                  },
                  onTap: () {
                    setState(() {
                      selectedId = item.node.id;
                    });

                    widget.onNodeSelected?.call(item.node);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// DATA STRUCTURE
////////////////////////////////////////////////////////////

class VisibleNode {
  final TreeNodeComponentDTODemo node;
  final int level;
  VisibleNode(this.node, this.level);
}

class TreeNodeComponentDTODemo {
  String title;
  int id;
  bool expanded;
  List<TreeNodeComponentDTODemo> children;

  TreeNodeComponentDTODemo(
      this.title,
      this.id, {
        this.expanded = false,
        this.children = const []
      });

  bool hasDescendant(String kw) {
    kw = kw.toLowerCase();
    for (var c in children) {
      if (c.title.toLowerCase().contains(kw)) return true;
      if (c.hasDescendant(kw)) return true;
    }
    return false;
  }
}

////////////////////////////////////////////////////////////
/// FLATTEN TREE
////////////////////////////////////////////////////////////

List<VisibleNode> flattenTree(List<TreeNodeComponentDTODemo> list,
    {String keyword = ""}) {
  List<VisibleNode> result = [];

  void dfs(TreeNodeComponentDTODemo node, int level) {
    // Filter
    if (keyword.isNotEmpty &&
        !node.title.toLowerCase().contains(keyword.toLowerCase()) &&
        !node.hasDescendant(keyword)) {
      return;
    }

    result.add(VisibleNode(node, level));

    if (node.expanded) {
      for (var c in node.children) dfs(c, level + 1);
    }
  }

  for (var n in list) dfs(n, 0);

  return result;
}

////////////////////////////////////////////////////////////
/// TREE NODE UI
////////////////////////////////////////////////////////////

class _TreeNodeWidget extends StatelessWidget {
  final VisibleNode data;
  final String keyword;
  final int? selectedId;
  final VoidCallback onExpand;
  final VoidCallback onTap;

  const _TreeNodeWidget({
    required this.data,
    required this.keyword,
    required this.selectedId,
    required this.onExpand,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool hasChild = data.node.children.isNotEmpty;
    bool selected = data.node.id == selectedId;

    return InkWell(
      onTap: () {
        if (hasChild) onExpand();
        onTap();
      },
      child: Container(
        color: selected ? Colors.blue.shade100 : null,
        padding: EdgeInsets.only(left: data.level * 20, top: 8, bottom: 8),
        child: Row(
          children: [
            if (hasChild)
              AnimatedRotation(
                turns: data.node.expanded ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.arrow_right, size: 20),
              )
            else
              const SizedBox(width: 20),

            const SizedBox(width: 6),
            _highlightText(data.node.title),
          ],
        ),
      ),
    );
  }

  /// Highlight search
  Widget _highlightText(String text) {
    if (keyword.isEmpty) return Text(text);

    final lower = text.toLowerCase();
    final search = keyword.toLowerCase();
    int index = lower.indexOf(search);

    if (index < 0) return Text(text);

    return RichText(
      text: TextSpan(style: const TextStyle(color: Colors.black), children: [
        TextSpan(text: text.substring(0, index)),
        TextSpan(
          text: text.substring(index, index + keyword.length),
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        TextSpan(text: text.substring(index + keyword.length)),
      ]),
    );
  }
}
