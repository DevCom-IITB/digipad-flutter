# digipad

The Cross-Platform Mobile Application for the Digipad Project - which will essentially allow the user to use a custom made stylus along with their phone as a replacement for a writing pad.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Js Server code

```
const net = require('net');

const server = net.createServer((socket) => {
    console.log('client connected');

    socket.on('data', (data) => {
        console.log(data.toString());
        if(data.toString()==="Hi"){
            socket.write('hi!');
        } else if(data.toString()==="Eraser"){
            socket.write('I cannot erase on my side');
        } else if(data.toString()==="Pencil"){
            socket.write('I can draw');
        }

    });


    socket.on('end', () => {
        console.log('Client disconnected');
    });
});

server.on('error', (err) => {
    console.error(error);
});

server.listen(4567, () => {
    console.log('opened server on', server.address());
});


```