import 'dart:ffi';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:digipad/settings.dart';

void main() {
  runApp(MaterialApp(
    routes: {
      '/': (context) => DigiCanvas(),
      '/settings':(context) => Settings(),
    },
  ));
}
class DigiCanvas extends StatefulWidget {
  const DigiCanvas({Key? key}) : super(key: key);

  @override
  _DigiCanvasState createState() => _DigiCanvasState();
}

class _DigiCanvasState extends State<DigiCanvas> {

  final pts = <Offset>[];
  bool isDrawing = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent[100],
      body: GestureDetector(
          onPanStart: (details) {
            setState(() {
              final renderbox = context.findRenderObject() as RenderBox;
              final localposition = renderbox.globalToLocal(details.globalPosition);
              if(isDrawing){
                pts.add(localposition);
              }else{
                for(var i=0;i<pts.length;i++ ){
                  if((pts[i]-localposition).distance<5) pts[i] = Offset.zero;
                }
              }
            });
          },
          onPanUpdate: (details) {
            setState(() {
              final renderbox = context.findRenderObject() as RenderBox;
              final localposition = renderbox.globalToLocal(details.globalPosition);
              if(isDrawing){
                pts.add(localposition);
              }else{
                for(var i=0;i<pts.length;i++ ){
                  if((pts[i]-localposition).distance<5) pts[i] = Offset.zero;
                }
              }
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
      ), bottomNavigationBar: Padding(
        padding: EdgeInsets.all(15.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            color: Colors.blue[500]
          ),
          padding: EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(onPressed: () {
                setState(() {
                  isDrawing = true;
                });
              }, icon: Icon(Icons.edit,size: 30,color: isDrawing?Colors.white:Colors.black,)),
              IconButton(onPressed: () {
                setState(() {
                  isDrawing = false;
                });
              }, icon: Icon(Icons.auto_fix_high,size: 30,color: isDrawing?Colors.black:Colors.white,)),
              IconButton(onPressed: () {
                setState(() {
                  pts.clear();
                });
              }, icon: Icon(Icons.clear,size: 30,)),
              IconButton(onPressed: () {
                Navigator.pushNamed(context, '/settings');
              }, icon: Icon(Icons.settings,size: 30,)),
            ],
          ),
        ),
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