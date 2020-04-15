import 'package:flutter/material.dart';
import 'package:neumorphic/neumorphic.dart';

class MeasureCard extends StatelessWidget {

  const MeasureCard({
    Key key,
    @required this.measureStream,
    @required this.title,
    @required this.buttonBarChildren,
});

  final Stream measureStream;
  final String title;
  final List<Widget> buttonBarChildren;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: NeuCard(
        curveType: CurveType.concave,
        bevel: 6,
        decoration:
        NeumorphicDecoration(borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: <Widget>[
            StreamBuilder(
              stream: measureStream,
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
              children: buttonBarChildren,
            ),
          ],
        ),
      ),
    );
  }
}

class MeasureButton extends StatelessWidget {
  const MeasureButton({
    Key key,
    @required this.onTap,
    this.curveType,
    this.color,
    this.buttonText,

});
  final VoidCallback onTap;
  final CurveType curveType;
  final Color color;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    return  GestureDetector(
      onTap: onTap,
      child: NeuCard(
        padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
        curveType: curveType != null ? curveType : CurveType.flat,
        bevel: 7,
        decoration: NeumorphicDecoration(
            borderRadius: BorderRadius.circular(10)),
        child: Center(
          child: Text(
            buttonText,
            style: TextStyle(
              color: color != null ? color : Theme.of(context).accentColor,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

