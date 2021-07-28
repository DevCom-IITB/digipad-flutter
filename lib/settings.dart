import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //TODO Make latency slider
    //TODO Set device name
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
      ),
      body:Center(
        child: Text("Work in Progress"),

      ) ,
    );;
  }
}
