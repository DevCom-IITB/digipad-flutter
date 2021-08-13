import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:io';

class SocketManager {
  var ipAddress;
  var port;
  var socket;
  late StreamSubscription socketListener;

  SocketManager(ip){
    ipAddress = ip;
    port = 4567;
  }

  void setIP(String ip){
    ipAddress = ip;
  }

  void connectSocket() async {
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
  }

  Future<void> sendMessage(String message) async {
    message = message + '#';
    print('Client: $message');
    socket.write(message);
    await Future.delayed(Duration(milliseconds:100 ));
  }

  void disconnectSocket() {
    sendMessage("Client Disconnecting ..");
    socketListener.cancel();
    socket.destroy();
  }

}