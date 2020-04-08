import 'dart:async';

import 'package:bachelorprojektrpm/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:google_fonts/google_fonts.dart';
import 'mess_screen.dart';

void main() {
  runApp(FlutterBlueApp());
}

class FlutterBlueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        accentColor: Color(0xff00082c),
        primaryColor: Color(0xff485dff),
        highlightColor: Color(0xff485dff),
        backgroundColor: Colors.blueGrey[50],
        primaryTextTheme: GoogleFonts.mavenProTextTheme(
          Theme.of(context).primaryTextTheme,
        ),
        textTheme: GoogleFonts.mavenProTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      debugShowCheckedModeBanner: false,
      color: Theme.of(context).primaryColor,
      home: StreamBuilder<BluetoothState>(
          stream: FlutterBlue.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return FindDevicesScreen();
            }
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key key, this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).accentColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Theme.of(context).primaryColor,
            ),
            Text(
              'Bluetooth Adapter is ${state.toString().substring(15)}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subhead
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String id = "50:51:A9:FD:95:5D";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('Meine Messgeräte'),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map((d) => ListTile(
                            title: Text('Profiltiefenmesser'),
                            trailing: StreamBuilder<BluetoothDeviceState>(
                              stream: d.state,
                              initialData: BluetoothDeviceState.disconnected,
                              builder: (c, snapshot) {
                                if (snapshot.data ==
                                    BluetoothDeviceState.connected) {
                                  return RaisedButton(
                                    child: Text(
                                      'Verbinden',
                                      style: TextStyle(
                                        color: Theme.of(context).accentColor,
                                      ),
                                    ),
                                    onPressed: () => Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: (context) =>
                                                MessScreen(device: d))),
                                  );
                                }
                                return Text(snapshot.data.toString());
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                  stream: FlutterBlue.instance.scanResults,
                  initialData: [],
                  builder: (c, snapshot) => Column(
                        children: snapshot.data.map((r) {
                          if (r.device.id.toString() == id) {
                            return ScanResultTile(
                              result: r,
                              onTap: () => Navigator.of(context)
                                  .push(MaterialPageRoute(builder: (context) {
                                r.device.connect();
                                return MessScreen(device: r.device);
                              })),
                            );
                          }
                          return Container(
                            height: 0,
                          );
                        }).toList(),
                      )),
            ],
          ),
        ),
      ),

      // Such Floating Button -> Findet etwas ja oder nein

      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                backgroundColor: Theme.of(context).accentColor,
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}
