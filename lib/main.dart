import 'dart:ffi';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: DigiCanvas(),
  ));
}
class DigiCanvas extends StatefulWidget {
  const DigiCanvas({Key? key}) : super(key: key);

  @override
  _DigiCanvasState createState() => _DigiCanvasState();
}

class _DigiCanvasState extends State<DigiCanvas> {

  final pts = <Offset>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent[100],
      body: GestureDetector(
          onPanStart: (details) {
            setState(() {
              final renderbox = context.findRenderObject() as RenderBox;
              final localposition = renderbox.globalToLocal(details.globalPosition);
              pts.add(localposition);
            });
          },
          onPanUpdate: (details) {
            setState(() {
              final renderbox = context.findRenderObject() as RenderBox;
              final localposition = renderbox.globalToLocal(details.globalPosition);
              pts.add(localposition);
            });
          },
          onPanEnd: (details) {
            setState(() {
              pts.add(Offset.zero);
            });
          },
          child: CustomPaint(
            painter: DigiPainter(pts),
            child: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
            ),
          )
      ),
    );;
  }
}


class DigiPainter extends CustomPainter{

  final pts;
  DigiPainter(this.pts):super();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
    ..color = Colors.black
    ..strokeWidth = 3.0
    ..isAntiAlias = true;
    for(var i =0; i<pts.length;i++){
      if(pts[i]!=Offset.zero&& pts[i+1]!=Offset.zero){
        canvas.drawLine(pts[i], pts[i+1], paint);
      }
      else if(pts[i]!=Offset.zero&&pts[i+1]==Offset.zero){
        canvas.drawPoints(PointMode.points, [pts[i]], paint);
      }
    }

  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

}