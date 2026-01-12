import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';


class DialogAddImageToPDF extends StatefulWidget {
  PdfPageImage pageImage;
  double width;
  double height;

  static final double maxVolumePdf = 800;

  static Future<List<LocationData>> router(BuildContext context, {required FutureOr<Uint8List> dataFile, required int indexPage}) async {
    double heightView = maxVolumePdf;
    double widthView = maxVolumePdf;
    List<LocationData> result =[];
    PdfDocument pdfDoc = await PdfDocument.openData(dataFile);
    PdfPageImage? pageImage = await pdfDoc.getPage(indexPage).then((page) {
      bool isPdfVertical = page.height > page.width;

      if(isPdfVertical){
        double scale = scaleVolume(originalVolume: page.height);
        widthView = calculatorVolume(valueScale: scale, scale: page.width);
      }else{
        double scale = scaleVolume(originalVolume: page.width);
        heightView = calculatorVolume(valueScale: scale, scale: page.height);
      }
      return page.render(
        width: widthView,
        height: heightView,
        format: PdfPageImageFormat.png,
      );
    });

    if(pageImage!= null && context.mounted){
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DialogAddImageToPDF(pageImage: pageImage, width: widthView + 32, height: heightView + 60,)),
      ).then((value){
        if(value != null && value is List<LocationData>){
          result = value;
        }
      });
    }

    return result;
  }

  static double scaleVolume({required double originalVolume}){
    return originalVolume/maxVolumePdf;
  }

  static double calculatorVolume({required double valueScale, required double scale,}){
    return scale * valueScale;
  }

  DialogAddImageToPDF({super.key, required this.pageImage, required this.width, required this.height});

  @override
  _DialogAddImageToPDFState createState() => _DialogAddImageToPDFState();
}

class _DialogAddImageToPDFState extends State<DialogAddImageToPDF> {
  Offset position = Offset(100, 100); // Vị trí ban đầu của widget con
  // Offset position2 = Offset(200, 200); // Vị trí ban đầu của widget con

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chèn ảnh chữ ký"),
        actions: [
          InkWell(
              onTap: (){
                Navigator.pop(context,[
                  LocationData(x:position.dx, y: position.dy,idImage: 1 ),
                  // LocationData(x:position2.dx, y: position2.dy,idImage: 2 ),
                ]);
              },
              child: Text("Confirm", style: TextStyle(fontSize: 16),))
        ],
      ),
      body: Center(
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Center(
                        child: Container(
                          color: Colors.blue[50],
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.memory(
                                  widget.pageImage.bytes,
                                  fit: BoxFit.fitHeight, // ✔ fit theo chiều cao của Dialog
                                  alignment: Alignment.center,
                                ),
                              ),
                              Positioned(
                                left: position.dx,
                                top: position.dy,
                                child: GestureDetector(
                                  onPanUpdate: (details) {
                                    setState(() {
                                      // Cập nhật vị trí nhưng giữ trong giới hạn container
                                      double newX = position.dx + details.delta.dx;
                                      double newY = position.dy + details.delta.dy;
                                      // Giới hạn theo kích thước container
                                      newX = newX.clamp(0.0, constraints.maxWidth - 50.0);
                                      newY = newY.clamp(0.0, constraints.maxHeight - 50.0);

                                      position = Offset(newX, newY);
                                    });
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              // Positioned(
                              //   left: position2.dx,
                              //   top: position2.dy,
                              //   child: GestureDetector(
                              //     onPanUpdate: (details) {
                              //       setState(() {
                              //         // Cập nhật vị trí nhưng giữ trong giới hạn container
                              //         double newX = position2.dx + details.delta.dx;
                              //         double newY = position2.dy + details.delta.dy;
                              //
                              //         // Giới hạn theo kích thước container
                              //         newX = newX.clamp(0.0, constraints.maxHeight - 50.0);
                              //         newY = newY.clamp(0.0, constraints.maxWidth - 50.0);
                              //
                              //         position2 = Offset(newX, newY);
                              //       });
                              //     },
                              //     child: Container(
                              //       width: 50,
                              //       height: 50,
                              //       decoration: const BoxDecoration(
                              //         color: Colors.blue,
                              //       ),
                              //     ),
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      );
                    }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LocationData{
  double x;
  double y;
  int idImage;

  LocationData({required this.x, required this.y, required this.idImage});

}

