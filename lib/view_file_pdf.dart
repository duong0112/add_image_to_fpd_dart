import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

// void main() {
//   runApp(const MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: PDFScrollableViewerPage(),
//   ));
// }

class PDFScrollableViewerPage extends StatefulWidget {
  const PDFScrollableViewerPage({super.key});

  @override
  State<PDFScrollableViewerPage> createState() => _PDFScrollableViewerPageState();
}

class _PDFScrollableViewerPageState extends State<PDFScrollableViewerPage> {
  final List<String> pdfFiles = [
    'assets/sample.pdf',
    'assets/sample2.pdf',
    'assets/sample3.pdf',
    'assets/sample4.pdf',
    'assets/sample5.pdf',
  ];

  String? selectedPdfPath;
  PdfDocument? pdfDoc;
  int pageCount = 0;

  double zoom = 1.0;
  double rotation = 0;

  @override
  void initState() {
    super.initState();
    selectedPdfPath = pdfFiles.first;
    loadPdf(selectedPdfPath!);
  }

  Future<void> loadPdf(String path) async {
    final doc = await PdfDocument.openAsset(path);
    setState(() {
      selectedPdfPath = path;
      pdfDoc = doc;
      pageCount = doc.pagesCount;
      zoom = 1.0;
      rotation = 0;
    });
  }

  Widget buildSidebar() {
    return Container(
      width: 200,
      color: Colors.grey.shade200,
      child: ListView(
        children: pdfFiles.map((path) {
          final fileName = path.split('/').last;
          return ListTile(
            title: Text(fileName),
            selected: selectedPdfPath == path,
            onTap: () => loadPdf(path),
          );
        }).toList(),
      ),
    );
  }

  Widget buildPage(int index) {
    return FutureBuilder(
      future: pdfDoc!.getPage(index),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ));
        }

        final page = snapshot.data! as PdfPage;
        return FutureBuilder(
          future: page.render(
            width: page.width * zoom,
            height: page.height * zoom,
            format: PdfPageImageFormat.png,
          ),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox.shrink();
            final image = snap.data! as PdfPageImage;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Transform.rotate(
                angle: rotation,
                child: Image.memory(image.bytes),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    pdfDoc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer - Scroll & Zoom'),
        actions: [
          IconButton(icon: const Icon(Icons.zoom_in), onPressed: () => setState(() => zoom += 0.1)),
          IconButton(icon: const Icon(Icons.zoom_out), onPressed: () => setState(() => zoom = (zoom - 0.1).clamp(0.5, 5.0))),
          IconButton(icon: const Icon(Icons.rotate_left), onPressed: () => setState(() => rotation -= math.pi / 2)),
          IconButton(icon: const Icon(Icons.rotate_right), onPressed: () => setState(() => rotation += math.pi / 2)),
        ],
      ),
      body: Row(
        children: [
          buildSidebar(),
          const VerticalDivider(width: 1),
          if (pdfDoc == null)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: pageCount,
                  itemBuilder: (_, index) => buildPage(index + 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
