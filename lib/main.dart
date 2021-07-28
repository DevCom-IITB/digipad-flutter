import 'dart:async';
import 'dart:ffi';
import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:digipad/settings.dart';

void main() {
  runApp(MaterialApp(
    routes: {
      '/': (context) => DigiCanvas(),
      '/settings': (context) => Settings(),
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
  bool isConnected = false;
  String ipAddress =
      '192.168.1.6'; //default value for local host while using emulator
  var socket;
  late StreamSubscription socketListener;

  //listen to the server
  void comm() async {
    socket = await Socket.connect(ipAddress, 4567);
    print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

    // listen for responses from the server
    socketListener = socket.listen(
      // handle data from the server
      (Uint8List data) {
        final serverResponse = String.fromCharCodes(data);
        print('Server: $serverResponse');
      },

      // handle errors
      onError: (error) {
        print(error);
        socket.destroy();
      },

      // handle server ending connection
      onDone: () {
        print('Server left.');
        socket.destroy();
      },
    );

    // send some messages to the server
    sendMessage("Hi");
  }

  //send message to the server
  Future<void> sendMessage(String message) async {
    print('Client: $message');
    socket.write(message);
    await Future.delayed(Duration(seconds: 2));
  }

  Future<dynamic> createAlertDialog(BuildContext context) {
    TextEditingController controller = new TextEditingController();

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("IP Address"),
            content: TextField(
              controller: controller,
            ),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(controller.text.toString());
                },
                child: Text("Connect"),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent[100],
      body: GestureDetector(
          onPanStart: (details) {
            setState(() {
              final renderbox = context.findRenderObject() as RenderBox;
              final localposition =
                  renderbox.globalToLocal(details.globalPosition);
              if (isDrawing) {
                pts.add(localposition);
              } else {
                for (var i = 0; i < pts.length; i++) {
                  if ((pts[i] - localposition).distance < 5)
                    pts[i] = Offset.zero;
                }
              }
            });
          },
          onPanUpdate: (details) {
            setState(() {
              final renderbox = context.findRenderObject() as RenderBox;
              final localposition =
                  renderbox.globalToLocal(details.globalPosition);
              if (isDrawing) {
                pts.add(localposition);
                sendMessage((localposition.dx/renderbox.size.width).toString() + ',' + (localposition.dy/renderbox.size.height).toString());
              } else {
                for (var i = 0; i < pts.length; i++) {
                  if ((pts[i] - localposition).distance < 5)
                    pts[i] = Offset.zero;
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
          )),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(15.0),
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              color: Colors.blue[500]),
          padding: EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                  onPressed: () {
                    setState(() {
                      isDrawing = true;
                      sendMessage(
                          "Pencil"); // send message to the server that pencil is selected
                    });
                  },
                  icon: Icon(
                    Icons.edit,
                    size: 30,
                    color: isDrawing ? Colors.white : Colors.black,
                  )),
              IconButton(
                  onPressed: () {
                    setState(() {
                      isDrawing = false;
                      sendMessage(
                          "Eraser"); //send message to server that eraser is selected
                    });
                  },
                  icon: Icon(
                    Icons.auto_fix_high,
                    size: 30,
                    color: isDrawing ? Colors.black : Colors.white,
                  )),
              IconButton(
                  onPressed: () {
                    setState(() {
                      pts.clear();
                      socketListener.cancel(); //terminate listening to server
                      socket.destroy(); //terminate socket connection
                      isConnected = false;
                    });
                  },
                  icon: Icon(
                    Icons.clear,
                    size: 30,
                  )),
              IconButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                  icon: Icon(
                    Icons.settings,
                    size: 30,
                  )),
              IconButton(
                  onPressed: () {
                    createAlertDialog(context).then((value) {
                      setState(() {
                        ipAddress = value;
                        comm();
                        isConnected = true;
                      });
                    });
                  },
                  icon: Icon(
                    Icons.bluetooth,
                    size: 30,
                    color: isConnected ? Colors.white : Colors.black,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class DigiPainter extends CustomPainter {
  final pts;
  DigiPainter(this.pts) : super();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.0
      ..isAntiAlias = true;
    for (var i = 0; i < pts.length - 1; i++) {
      if (pts[i] != Offset.zero && pts[i + 1] != Offset.zero) {
        canvas.drawLine(pts[i], pts[i + 1], paint);
      } else if (pts[i] != Offset.zero && pts[i + 1] == Offset.zero) {
        canvas.drawPoints(PointMode.points, [pts[i]], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
