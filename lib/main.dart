//@dart=2.9

import 'dart:async';
import 'dart:ffi';
import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:digipad/settings.dart';
import 'package:digipad/socket_manager.dart';
import 'package:ping_discover_network/ping_discover_network.dart';
import 'package:wifi/wifi.dart';

void main() {
  runApp(MaterialApp(
    routes: {
      '/': (context) => DigiCanvas(),
    },
  ));
}

class DigiCanvas extends StatefulWidget {
  const DigiCanvas({Key key}) : super(key: key);

  @override
  _DigiCanvasState createState() => _DigiCanvasState();
}

class _DigiCanvasState extends State<DigiCanvas> with WidgetsBindingObserver {
  // Automatic detection of orientation change to change window size in desktop
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      setState(() {
        messageManager("initialize");
      });
    });
  }

  @override
  void initState() {
    super.initState();
    print("init");
    WidgetsBinding.instance?.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  final pts = <Offset>[];
  bool isDrawing = false;
  bool isScreenMoving = false;
  bool isConnected = false;
  String ipAddress =
      '192.168.1.6'; //default value for local host while using emulator
  var socket;
  StreamSubscription socketListener;
  String JSONmessage = "";
  Timer _timer;
  int timerStep = 0;
  int selectedIndex = -1;

  void messageManager(String action, [double dx, double dy]) {
    var message;
    switch (action) {
      case "initialize":
        message = {
          "action": action,
          "mobileWidth": (MediaQuery.of(context).size.width).toString(),
          "mobileHeight": (MediaQuery.of(context).size.height).toString(),
        };
        break;
      case "right-click":
      case "left-click":
        message = {"action": action};
        break;
      case "zoom":
        message = {"action": action, "dx": dx};
        break;
      default: //Move commands
        message = {"action": action, "dx": dx, "dy": dy};
        break;
    }
    var jsonMessage = json.encode(message);
    sendMessage(jsonMessage);
  }

  //listen to the server
  void comm() async {
    print(ipAddress);
    socket = await Socket.connect(ipAddress, 4567);
    print('Connected to: ${socket.remoteAddress.address}:${socket.remotePort}');

    //sendInitialData();
    messageManager("initialize");

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
  }

  //send message to the server
  Future<void> sendMessage(String message) async {
    message = message + '#';
    print('Client: $message');
    //JSONmessage = JSONmessage + message;
    //if(timerStep>10){
    socket.write(message);
    //JSONmessage = "";
    //timerStep = 0;
    await Future.delayed(Duration(milliseconds: 100));
    //}
  }

  /*Future<List<String>> getListOfDevices() async {
    final String ip = await Wifi.ip;
    print(ip);
    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    print(subnet);
    final int port = 4567;

    List<String> deviceList = [];

    final stream = NetworkAnalyzer.discover2(
      subnet,
      port,
      timeout: Duration(milliseconds: 5000),
    );
    stream.listen((NetworkAddress address) {
      print("It's Showtime");
      if (address.exists) {
        print("HEY!\n");
        deviceList.add(address.ip);
      }
    }).onDone(
      () {
        print(deviceList);
        return deviceList;
      },
    );
  }*/

  Future<dynamic> createAlertDialog(BuildContext context) async {
    //TextEditingController controller = new TextEditingController();
    final String ip = await Wifi.ip;
    final String subnet = ip.substring(0, ip.lastIndexOf('.'));
    final int port = 4567;

    List<String> deviceList = [];

    final stream = NetworkAnalyzer.discover2(
      subnet,
      port,
    );
    stream.listen((NetworkAddress address) {
      if (address.exists) {
        deviceList.add(address.ip);
      }
    }).onDone(
      () {
        List<Widget> widgetList = [];
        //print(deviceList);

        for (int i = 0; i < deviceList.length; i++) {
          widgetList.add(
            ElevatedButton(
              onPressed: () {
                setState(() {
                  ipAddress = deviceList[i];
                  //print('IP Address: ');
                  print(ipAddress);
                  comm();
                  isConnected = true;
                });
              },
              child: Text(deviceList[i]),
            ),
          );
        }

        return showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text("Found Devices"),
              actions: widgetList,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        extendBody: true,
        backgroundColor: Colors.redAccent[100],
        body: GestureDetector(
            onPanStart: (details) {
              //TODO Start timer
              // if(_timer==null){
              //   _timer = Timer.periodic(Duration(milliseconds: 10), (timer) {
              //     timerStep++;
              //   });
              // }
              setState(() {
                final renderBox = context.findRenderObject() as RenderBox;
                final localPosition =
                    renderBox.globalToLocal(details.globalPosition);
                if (isDrawing) {
                  pts.add(localPosition);
                }
                var dx = localPosition.dx / renderBox.size.width;
                var dy = localPosition.dy / renderBox.size.height;
                messageManager("move", dx, dy);
              });
            },
            onPanUpdate: (details) {
              setState(() {
                final renderBox = context.findRenderObject() as RenderBox;
                final localPosition =
                    renderBox.globalToLocal(details.globalPosition);
                var dx = localPosition.dx / renderBox.size.width;
                var dy = localPosition.dy / renderBox.size.height;
                if (isDrawing) {
                  pts.add(localPosition);
                  messageManager("drag", dx, dy);
                } else if (isScreenMoving) {
                  messageManager("screen", dx, dy);
                } else {
                  messageManager("move", dx, dy);
                }
              });
            },
            onPanEnd: (details) {
              setState(() {
                pts.add(Offset.zero);
                // if(_timer==null){
                //   _timer!.cancel();
                // }
              });
            },
            onDoubleTap: () {
              messageManager("right-click");
            },
            onTap: () {
              messageManager("left-click");
            },
            child: CustomPaint(
              painter: DigiPainter(pts),
              child: Container(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
              ),
            )),
        bottomNavigationBar: FractionallySizedBox(
          widthFactor:
              MediaQuery.of(context).orientation == Orientation.portrait
                  ? 1
                  : 0.4,
          alignment: Alignment.bottomLeft,
          child: Padding(
              padding: EdgeInsets.all(15.0),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    color: Colors.blue[500]),
                padding: EdgeInsets.all(
                    MediaQuery.of(context).orientation == Orientation.portrait
                        ? 10
                        : 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                        onPressed: () {
                          setState(() {
                            if (!isScreenMoving) {
                              isDrawing = !isDrawing;
                              pts.clear();
                            } else {
                              isDrawing = true;
                              isScreenMoving = false;
                            }
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
                          isScreenMoving = !isScreenMoving;
                          pts.clear();
                        });
                      },
                      icon: Icon(
                        Icons.fit_screen,
                        size: 30,
                        color: isScreenMoving ? Colors.white : Colors.black,
                      ),
                    ),
                    IconButton(
                        onPressed: () {
                          if (isConnected) {
                            setState(() {
                              socketListener
                                  .cancel(); //terminate listening to server
                              socket.destroy(); //terminate socket connection
                              pts.clear();
                              isConnected = false;
                              isDrawing = false;
                              isScreenMoving = false;
                            });
                          } else {
                            createAlertDialog(context);
                          }
                        },
                        icon: Icon(
                          Icons.bluetooth,
                          size: 30,
                          color: isConnected ? Colors.white : Colors.black,
                        )),
                  ],
                ),
              )),
        ));
  }
}

class DigiPainter extends CustomPainter {
  final pts;
  DigiPainter(this.pts) : super();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 5.0
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
/*

createAlertDialog(context).then((value) {
setState(() {
print('Value: ');
print(value);
ipAddress = value;
print('IP Address: ');
print(ipAddress);
comm();
isConnected = true;
});
});
*/
