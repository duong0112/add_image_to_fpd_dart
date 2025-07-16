import 'dart:nativewrappers/_internal/vm/lib/typed_data_patch.dart';

import 'package:demo_1/pdf_editer.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Dialog Demo',
      home: PDFViewerPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class PDFViewerPage extends StatefulWidget {
  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  late PdfControllerPinch _pdfController;
  int _totalPages = 0;
  bool _isLoaded = false;
  final List<Uint8List> _pageImages = [];

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    PdfDocument doc = await PdfDocument.openAsset('assets/sample.pdf');
    _totalPages = doc.pagesCount;
    _pdfController = PdfControllerPinch(document: PdfDocument.openAsset('assets/sample.pdf'));
    setState(() {
      _isLoaded = true;
    });
  }

  void _showPdfPageDialog(int pageNumber) async {
    PdfDocument pdfDoc = await _pdfController.document;
    PdfPageImage? pageImage = await pdfDoc.getPage(pageNumber).then((page) {
      page.width;
      page.height;
      return page.render(
        width: 600,
        height: 800,
        format: PdfPageImageFormat.png,
      );
    });
    if(pageImage!= null){
      List<LocationData> result = await PdfEditerCustom.router(context, pageImage: pageImage);
      for (var data in result) {
        print("===========image ${data.idImage} : (${data.x}:${data.y})");
      }
    }
  }

  Widget _buildPageSelector() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Chọn trang để hiển thị:', style: TextStyle(fontSize: 20)),
        SizedBox(height: 20),
        Wrap(
          spacing: 10,
          children: List.generate(_totalPages, (index) {
            final page = index + 1;
            return ElevatedButton(
              onPressed: () => _showPdfPageDialog(page),
              child: Text('$page'),
            );
          }),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF Dialog Demo'),
      ),
      body: Center(
        child: _isLoaded
            ? _buildPageSelector()
            : CircularProgressIndicator(),
      ),
    );
  }
}
