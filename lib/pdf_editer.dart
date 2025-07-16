import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfEditerCustom extends StatefulWidget {
  PdfPageImage pageImage;

  static Future<List<LocationData>> router(BuildContext context, {required PdfPageImage pageImage}) async {
     List<LocationData> result =[];
     await showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.all(20),
        child: PdfEditerCustom(pageImage: pageImage),
      ),
    ).then((value){
      if(value != null && value is List<LocationData>){
        result = value;
      }
    });
     return result;
  }

  PdfEditerCustom({required this.pageImage});

  @override
  _PdfEditerCustomState createState() => _PdfEditerCustomState();
}

class _PdfEditerCustomState extends State<PdfEditerCustom> {
  Offset position = Offset(100, 100); // Vị trí ban đầu của widget con
  Offset position2 = Offset(200, 200); // Vị trí ban đầu của widget con

  @override
  Widget build(BuildContext context) {
    return Column(
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
                              newX = newX.clamp(0.0, constraints.maxHeight - 50.0);
                              newY = newY.clamp(0.0, constraints.maxWidth - 50.0);

                              position = Offset(newX, newY);
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: position2.dx,
                        top: position2.dy,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              // Cập nhật vị trí nhưng giữ trong giới hạn container
                              double newX = position2.dx + details.delta.dx;
                              double newY = position2.dy + details.delta.dy;

                              // Giới hạn theo kích thước container
                              newX = newX.clamp(0.0, constraints.maxHeight - 50.0);
                              newY = newY.clamp(0.0, constraints.maxWidth - 50.0);

                              position2 = Offset(newX, newY);
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
        ),
        InkWell(
          onTap: (){
            Navigator.pop(context,[
              LocationData(x:position.dx, y: position.dy,idImage: 1 ),
              LocationData(x:position2.dx, y: position2.dy,idImage: 2 ),
            ]);
          },
            child: Text("Confirm", style: TextStyle(fontSize: 16),))
      ],
    );
  }
}

class LocationData{
  double x;
  double y;
  int idImage;

  LocationData({required this.x, required this.y, required this.idImage});

}
