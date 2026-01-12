import 'package:flutter/material.dart';

class ImageResizeDemo extends StatefulWidget {
  const ImageResizeDemo({super.key});

  @override
  State<ImageResizeDemo> createState() => _ImageResizeDemoState();
}

class _ImageResizeDemoState extends State<ImageResizeDemo> {
  double top = 100;
  double left = 100;
  double width = 200;
  double height = 200;
  bool isResizing = false;
  bool isDragging = false;

  Offset? lastFocalPoint;

  double top2 = 300;
  double left2 = 300;
  double width2 = 200;
  double height2 = 200;
  bool isResizing2 = false;
  bool isDragging2 = false;

  Offset? lastFocalPoint2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resize Image - Flutter Web')),

      body: Stack(
        children: [
          Positioned(
            top: top,
            left: left,
            child: GestureDetector(
              onPanStart: (details) {
                final localPos = details.localPosition;
                final isInResizeCorner = localPos.dx > width - 20 && localPos.dy > height - 20;
                if (isInResizeCorner) {
                  isResizing = true;
                } else {
                  isDragging = true;
                }
                lastFocalPoint = details.globalPosition;
              },
              onPanUpdate: (details) {
                if (lastFocalPoint == null) return;

                final dx = details.globalPosition.dx - lastFocalPoint!.dx;
                final dy = details.globalPosition.dy - lastFocalPoint!.dy;

                setState(() {
                  if (isDragging) {
                    left += dx;
                    top += dy;
                  } else if (isResizing) {
                    width += dx;
                    height += dy;
                    width = width.clamp(50, 1000);
                    height = height.clamp(50, 1000);
                  }
                });

                lastFocalPoint = details.globalPosition;
              },
              onPanEnd: (_) {
                isDragging = false;
                isResizing = false;
                lastFocalPoint = null;
              },
              child: Stack(
                children: [
                  Container(
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: Image.asset(
                      'assets/img1.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Resize handle (bottom-right corner)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpLeftDownRight,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          border: Border.all(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: top2,
            left: left2,
            child: GestureDetector(
              onPanStart: (details) {
                final localPos = details.localPosition;
                final isInResizeCorner = localPos.dx > width2 - 20 && localPos.dy > height2 - 20;
                if (isInResizeCorner) {
                  isResizing2 = true;
                } else {
                  isDragging2 = true;
                }
                lastFocalPoint2 = details.globalPosition;
              },
              onPanUpdate: (details) {
                if (lastFocalPoint2 == null) return;

                final dx = details.globalPosition.dx - lastFocalPoint2!.dx;
                final dy = details.globalPosition.dy - lastFocalPoint2!.dy;

                setState(() {
                  if (isDragging2) {
                    left2 += dx;
                    top2 += dy;
                  } else if (isResizing2) {
                    width2 += dx;
                    height2 += dy;
                    width2 = width2.clamp(50, 1000);
                    height2 = height2.clamp(50, 1000);
                  }
                });

                lastFocalPoint2 = details.globalPosition;
              },
              onPanEnd: (_) {
                isDragging2 = false;
                isResizing2 = false;
                lastFocalPoint2 = null;
              },
              child: Stack(
                children: [
                  Container(
                    width: width2,
                    height: height2,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: Image.asset(
                      'assets/img1.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Resize handle (bottom-right corner)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.resizeUpLeftDownRight,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          border: Border.all(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
