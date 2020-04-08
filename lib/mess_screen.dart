import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:neumorphic/neumorphic.dart';

import 'dbmanager.dart';
import 'models/controller.dart';
import 'models/kunden_form.dart';

class MessScreen extends StatefulWidget {
  const MessScreen({Key key, this.device}) : super(key: key);
  final BluetoothDevice device;

  @override
  _MessScreenState createState() => _MessScreenState();
}

class _MessScreenState extends State<MessScreen> {
  // Variablen
  StreamController<String> valFrontLeft;
  StreamController<String> valFrontRight;
  StreamController<String> valBackLeft;
  StreamController<String> valBackRight;

  BluetoothCharacteristic char;
  String tmp = "0"; // stores the current value

  final DbManager dbmanager = new DbManager();
  Reifen reifen;
  List<Reifen> reifenList;

  final _zeichenController = TextEditingController();
  final _formKey = new GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int updateIndex;
  List<String> messung = new List(4);

  @override
  // wird bei Start der App ausgeführt
  void initState() {
    super.initState();
    valFrontLeft = StreamController();
    valFrontRight = StreamController();
    valBackLeft = StreamController();
    valBackRight = StreamController();

    widget.device.discoverServices();
  }



  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width / 1.5;

    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      key: _scaffoldKey,

      // Appbar mit Bluetooth Verbindung
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          "Profiltiefenmesser",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: widget.device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => widget.device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => widget.device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return FlatButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        .copyWith(color: Colors.white, fontSize: 12),
                  ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: <Widget>[
                      // Kennzeichen
                      TextFormField(
                        decoration:
                            new InputDecoration(labelText: 'Kennzeichen'),
                        controller: _zeichenController,
                        validator: (val) => val.isNotEmpty
                            ? null
                            : 'Bitte Kennzeichen eingeben.',
                      ),
                    ],
                  ),
                )),

            // Device Services
            StreamBuilder<List<BluetoothService>>(
              stream: widget.device.services,
              initialData: [],
              builder: (c, snapshot) {
                var services = snapshot.data;

                // aktuellen Messwert anzeigen
                return Column(children: <Widget>[
                  Row(
                    children: <Widget>[
                      buildCard(services, valFrontLeft, "VORNE LINKS", 0),
                      buildCard(services, valFrontRight, "VORNE RECHTS", 1),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Row(
                      children: <Widget>[
                        buildCard(services, valBackLeft, "HINTEN LINKS", 2),
                        buildCard(services, valBackRight, "HINTEN RECHTS", 3),
                      ],
                    ),
                  ),
                ]);
              },
            ),

            Container(
              padding: EdgeInsets.only(top: 20, bottom: 30),
              height: 100,
              child: FlatButton(
                textColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                child: Container(
                    width: width,
                    child: Text(
                      "Hinzufügen",
                      textAlign: TextAlign.center,
                    )),
                onPressed: () {
                  _submit(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Neumorphic Measure Cards
  buildCard(List<BluetoothService> services, var wheel, var title, int index) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: NeuCard(
        width: 150,
        height: 140,
        curveType: CurveType.concave,
        bevel: 6,
        decoration:
            NeumorphicDecoration(borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: <Widget>[
            StreamBuilder(
              stream: wheel.stream,
              initialData: "0",
              builder: (BuildContext ctx, AsyncSnapshot snapshot) {
                if (snapshot.hasData && !snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 15, bottom: 10),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            "RAD " + title + ":",
                            style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).accentColor),
                          ),
                        ),
                        Center(
                          child: Text(snapshot.data,
                              style: TextStyle(
                                fontSize: 22,
                                color: Theme.of(context).primaryColor,
                              ),
                              maxLines: 1),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Center(
                    child: Text("Error occured in Stream"),
                  );
                }
              },
            ),

            // Buttons zum Ändern des Messwertes
            ButtonBar(
              alignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    for (BluetoothService service in services) {
                      if (service.uuid.toString().substring(4, 8) == "ffe0") {
                        for (char in service.characteristics) {
                          if (char.uuid.toString().substring(4, 8) == "ffe1") {
                            print("Found!");
                            setNotification(char, wheel, index);

                          }
                        }
                      }
                    }
                  },
                  child: NeuCard(
                    width: 62,
                    height: 40,
                    curveType: CurveType.concave,
                    bevel: 7,
                    decoration: NeumorphicDecoration(
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Text(
                        "START",
                        style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    char.setNotifyValue(!char.isNotifying);
                    messung[index] = tmp;
                    wheel.close();
                  },
                  child: NeuCard(
                    width: 62,
                    height: 40,
                    curveType: CurveType.concave,
                    bevel: 7,
                    decoration: NeumorphicDecoration(
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Text(
                        "STOP",
                        style: TextStyle(
                          color: Theme.of(context).accentColor,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState.validate()) {
      KundenForm kundenForm = KundenForm(
        _zeichenController.text,
        messung[0],
        messung[1],
        messung[2],
        messung[3],
      );

      FormController formController = FormController((String response) {
        print(response);
        if (response == FormController.STATUS_SUCCESS) {
          _showSnackBar("Kunde wurde erfolgreich in die Tabelle hinzugefügt");
        } else {
          _showSnackBar("Fehler");
        }
      });
      if (reifen == null) {
        Reifen rf = new Reifen(
            zeichen: _zeichenController.text,
            vl: messung[0],
            vr: messung[1],
            hl: messung[2],
            hr: messung[3]);
        dbmanager.insertReifen(rf).then((id) => {
              _zeichenController.clear(),
              print('Reifen wurde in die Datenbank Nummer $id hinzugefügt')
            });
      } else {
        reifen.zeichen = _zeichenController.text;

        dbmanager.updateReifen(reifen).then((id) => {
              setState(() {
                reifenList[updateIndex].zeichen = _zeichenController.text;
                reifenList[updateIndex].vl = messung[0];
                reifenList[updateIndex].vr = messung[1];
                reifenList[updateIndex].hl = messung[2];
                reifenList[updateIndex].hr = messung[3];
              }),
              _zeichenController.clear(),
              reifen = null
            });
      }
      _showSnackBar("Kunde wird in die Tabelle hinzugefügt");
      formController.submitForm(kundenForm);
    }
  }

  _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
    );
    _scaffoldKey.currentState.showSnackBar(snackBar);
  }

  setNotification(BluetoothCharacteristic char, var wheel, int index) async {
    await char.setNotifyValue(true);
    char.value.listen((value) {
      final decoded = utf8.decode(value);
      _DataParser(decoded, wheel, index);
    });
  }

  _DataParser(String data, var wheel, int index) {
    if (data.isNotEmpty) {
      var value = data.split(",")[0];
      tmp = value;
      wheel.add(value);
      print("Messung: $value");
    }
  }
}
