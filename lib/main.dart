import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui_web' as ui; // ✅ bắt buộc cho Flutter Web mới
import 'package:demo_1/table_v3/test_table_new_v3.dart';
import 'package:demo_1/tree_ui/tree_view_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, rootBundle;

import 'dropdown_custom/dropdown_custom.dart';
import 'token_manager/token_manager_monitor.dart';
import 'tree_ui/demo_tree_view.dart';


void main() {
  // runApp(DropdownCustom());
  runApp(Web2App());
}

class Web2App extends StatelessWidget {
  Web2App({super.key});

  final tree = TreeNodeComponentDTO("Root", 9999, children: [
    ...List.generate(50, (index) {
      return TreeNodeComponentDTO("Tree node ${index + 1}", index + 1, expanded: true, children: [
        ...List.generate(5, (subIndex) {
          return TreeNodeComponentDTO(
              "sub tree node ${index}00${subIndex + 1}", int.parse("${index}00${subIndex + 1}"),
              expanded: true,
              children: [
                ...List.generate(5, (subLevel2Index) {
                  return TreeNodeComponentDTO(
                    "sub tree node ${subLevel2Index}000${subLevel2Index + 1}",
                    int.parse("${subLevel2Index}000${subLevel2Index + 1}"),
                    expanded: true,
                  );
                }),
              ]);
        }),
      ]);
    }),
  ]);

  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    GlobalUserActivityDetector(); // Khởi tạo 1 lần
    return MaterialApp(
      // home: DemoTableV3()
      home: Scaffold(body: Row(
        children: [
          Expanded(flex: 1, child: TreeViewComponentV2(rootTree: tree,)),
          Expanded(flex: 4, child: Container(
            color: Colors.blue,
          )),
        ],
      ))
      // home: Scaffold(
      //   appBar: AppBar(title: const Text('Web2 Container')),
      //   body: const Web1Frame(),
      // ),
    );
  }
}

class Web1Frame extends StatefulWidget {
  const Web1Frame({super.key});

  @override
  State<Web1Frame> createState() => _Web1FrameState();
}

class _Web1FrameState extends State<Web1Frame> {
  late html.IFrameElement iframe;
  String status = 'Chưa có dữ liệu';

  @override
  void initState() {
    super.initState();

    // Lắng nghe phản hồi từ web1
    html.window.onMessage.listen((event) {
      if (event.origin == 'http://localhost:4200') {
        setState(() => status = '${event.data}');
      }
    });
  }

  Future<void> _sendToWeb1() async {
    final bytes = await rootBundle.load('assets/sample.pdf');
    final base64 = base64Encode(bytes.buffer.asUint8List());
    //
    _InputDataListen fakeData = _InputDataListen(
      employeeUserADs: ["lanhdaont", "phuonglt10"],
      pdfBase64: base64,
    );

    iframe.contentWindow?.postMessage(jsonEncode(fakeData.toJson()), 'http://localhost:4200');
    // setState(() => status = 'base64: $base64');
  }

  @override
  Widget build(BuildContext context) {
    iframe = html.IFrameElement()
      ..src = 'http://localhost:4200/#/add-image-to-file'
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '80%';

    // ✅ đăng ký viewType cho iframe
    ui.platformViewRegistry.registerViewFactory('iframeWeb1', (int _) => iframe);

    return Column(
      children: [
        ElevatedButton(
          onPressed: _sendToWeb1,
          child: const Text('Gửi PDF + List<String> sang Web1'),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
              onTap: (){
                Clipboard.setData(ClipboardData(text: status));
              },
              child: Text(status)),
        ),
        Expanded(child: Center(child: HtmlElementView(viewType: 'iframeWeb1'))),
      ],
    );
  }
}

class _InputDataListen {
  List<String>? employeeUserADs;
  String? pdfBase64;
  List<SignImageLocationDTO>? lstSignImageLocationDto;

  _InputDataListen({
    this.employeeUserADs,
    this.pdfBase64,
    this.lstSignImageLocationDto,
  });

  factory _InputDataListen.fromJson(Map<String, dynamic> json) {
    return _InputDataListen(
      employeeUserADs: (json['employeeUserADs'] as List?)?.map((e) => e as String).toList(),
      pdfBase64: json['pdfBase64'] as String?,
      lstSignImageLocationDto: (json['lstSignImageLocationDto'] as List?)?.map((e) => SignImageLocationDTO.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'employeeUserADs': employeeUserADs,
    'pdfBase64': pdfBase64,
    'lstSignImageLocationDto': lstSignImageLocationDto?.map((e) => e.toJson()).toList(),
  };
}

class SignImageLocationDTO {
  int? signImageId;
  double? pageWidth; //Chiều rộng page PDF khi người dùng edit
  double? pageHeight;//Chiều rộng page PDF khi người dùng edit
  double? locationX;
  double? locationY;
  double? imageWidth;
  double? imageHeight;
  int? page;

  SignImageLocationDTO(
      {this.pageWidth,
        this.pageHeight,
        required this.signImageId,
        required this.locationX,
        required this.locationY,
        required this.imageWidth,
        required this.imageHeight,
        required this.page});

  SignImageLocationDTO.fromJson(Map<String, dynamic> json) {
    signImageId = json['signImageId'];
    locationX = json['locationX'];
    locationY = json['locationY'];
    imageWidth = json['imageWidth'];
    imageHeight = json['imageHeight'];
    pageWidth = json['pageWidth'];
    pageHeight = json['pageHeight'];
    page = json['page'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['signImageId'] = signImageId;
    data['locationX'] = locationX;
    data['locationY'] = locationY;
    data['imageWidth'] = imageWidth;
    data['imageHeight'] = imageHeight;
    data['pageHeight'] = pageHeight;
    data['pageWidth'] = pageWidth;
    data['page'] = page;
    return data;
  }
}

