import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class TreeViewComponentV2 extends StatefulWidget {
  TreeViewComponentV2({super.key, required this.rootTree});

  TreeNodeComponentDTO rootTree;

  @override
  State<TreeViewComponentV2> createState() => _TreeViewComponentV2State();
}

class _TreeViewComponentV2State extends State<TreeViewComponentV2> {
  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocus = FocusNode();

  late GlobalKey treeViewKey;
 // Key for TreeView
  @override
  Widget build(BuildContext context) {
    return Container(
        constraints: BoxConstraints(
          maxHeight: double.infinity,
        ),
        color: Colors.transparent,
        child: Column(
          children: [
            InkWell(onTap: (){
              setState(() {});
            },child:Text("CLICK")),
            SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (value){},
                decoration: InputDecoration(
                  hintText: "Search...",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {},
                  )
                      : null,
                ),
              ),
            ),
            Expanded(
                child: _TreeViewWidget(
                  dataTree: widget.rootTree.children,
                )
            ),
          ],
        ));
  }
}

class _TreeViewWidget extends StatefulWidget {
  _TreeViewWidget({required this.dataTree});

  List<TreeNodeComponentDTO> dataTree;

  @override
  State<_TreeViewWidget> createState() => _TreeViewWidgetState();
}

class _TreeViewWidgetState extends State<_TreeViewWidget> {
  final ScrollController _vertical = ScrollController();
  late List<TreeNodeComponentDTO> dataTree;


  @override
  void initState() {
    dataTree = [...widget.dataTree];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      thumbColor: Colors.black54,
      radius: Radius.circular(10),
      thickness: 10,
      controller: _vertical,
      trackVisibility: true,
      child: ListView.builder(
        controller: _vertical,
        itemCount: widget.dataTree.length,
        itemBuilder: (context, index) {
          return _TreeNodeWidget(
            nodeItem: widget.dataTree[index],
            keyword: "",
            selectedId: 0,
            onTap: () {},
          );
        },
      ),
    );
  }
}

class _TreeNodeWidget extends StatefulWidget {
  final TreeNodeComponentDTO nodeItem;
  final String keyword;
  int? selectedId;
  final VoidCallback onTap;

  _TreeNodeWidget({
    required this.nodeItem,
    required this.keyword,
    this.selectedId,
    required this.onTap,
  });

  @override
  State<_TreeNodeWidget> createState() => _TreeNodeWidgetState();
}

class _TreeNodeWidgetState extends State<_TreeNodeWidget> {

  @override
  Widget build(BuildContext context) {
    bool hasChild = widget.nodeItem.children.isNotEmpty;
    bool selected = widget.nodeItem.id == widget.selectedId;

    return Column(
      children: [
        InkWell(
          onTap: () {
            if (hasChild) {
              setState(() {
                widget.nodeItem.expanded = !widget.nodeItem.expanded;
              });
            }else{
              widget.onTap();
            }
          },
          child: Container(
            color: selected ? Colors.blue.shade100 : null,
            // padding: EdgeInsets.only(left: data.level * 20, top: 8, bottom: 8),
            child: Row(
              children: [
                if (hasChild)
                  AnimatedRotation(
                    turns: widget.nodeItem.expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.arrow_right, size: 20),
                  )
                else
                  const SizedBox(width: 20),
                Icon(Icons.folder_open,size: 20,),
                const SizedBox(width: 6),
                _highlightText(widget.nodeItem.title),
              ],
            ),
          ),
        ),
        if(widget.nodeItem.expanded) AnimatedContainer(
          duration: Duration(milliseconds: 300),
          child: Container(
            margin: EdgeInsets.only(left: 20),
            child: Column(
                children: List.generate(widget.nodeItem.children.length, (index){
                  return _TreeNodeWidget(
                    nodeItem: widget.nodeItem.children[index],
                    keyword: "",
                    selectedId: 0,
                    onTap: () {},
                  );
                })
            ),
          ),
        )
      ],
    );
  }

  /// Highlight search
  Widget _highlightText(String text) {
    if (widget.keyword.isEmpty) return Text(text);

    final lower = text.toLowerCase();
    final search = widget.keyword.toLowerCase();
    int index = lower.indexOf(search);

    if (index < 0) return Text(text);

    return RichText(
      text: TextSpan(style: const TextStyle(color: Colors.black), children: [
        TextSpan(text: text.substring(0, index)),
        TextSpan(
          text: text.substring(index, index + widget.keyword.length),
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        TextSpan(text: text.substring(index + widget.keyword.length)),
      ]),
    );
  }
}

class TreeNodeComponentDTO {
  String title;
  String subTitle;
  int id;
  bool expanded;
  List<TreeNodeComponentDTO> children;

  TreeNodeComponentDTO(this.title, this.id, {this.expanded = false, this.subTitle = "", this.children = const []});

  bool hasDescendant(String kw) {
    kw = kw.toLowerCase();
    for (var c in children) {
      if (c.title.toLowerCase().contains(kw) || c.subTitle.toLowerCase().contains(kw)) return true;
      if (c.hasDescendant(kw)) return true;
    }
    return false;
  }
}

class DataHistoryStockModel {
  String codeMCK; //mã chứng khoán
  int periodsPerYear;
  List<double> listPrices; // Danh sách prices
  DataHistoryStockModel(this.codeMCK, this.periodsPerYear, this.listPrices);
}
