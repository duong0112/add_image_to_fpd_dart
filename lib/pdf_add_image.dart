import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:syncfusion_flutter_pdf/pdf.dart';

Future<Uint8List> insertImagesToPdf() async {
  // Load PDF gốc
  final pdfData = await rootBundle.load('assets/sample.pdf');
  final document = PdfDocument(inputBytes: pdfData.buffer.asUint8List());

  // Load ảnh từ assets
  final image1 = await rootBundle.load('assets/img1.jpg');
  final image2 = await rootBundle.load('assets/img2.jpg');
  final image3 = await rootBundle.load('assets/img3.jpg');

  final imgBytes1 = image1.buffer.asUint8List();
  final imgBytes2 = image2.buffer.asUint8List();
  final imgBytes3 = image3.buffer.asUint8List();

  // Chèn ảnh vào từng trang (tọa độ giả định)
  document.pages[0].graphics.drawImage(
    PdfBitmap(imgBytes1),
    const Rect.fromLTWH(100, 100, 100, 100),
  );
  document.pages[1].graphics.drawImage(
    PdfBitmap(imgBytes2),
    const Rect.fromLTWH(200, 150, 100, 100),
  );
  document.pages[2].graphics.drawImage(
    PdfBitmap(imgBytes3),
    const Rect.fromLTWH(50, 200, 120, 120),
  );

  // Xuất file PDF mới
  List<int> output = await document.save();
  document.dispose();

  return Uint8List.fromList(output);
}
