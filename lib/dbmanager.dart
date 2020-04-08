import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DbManager {
  Database _database;

  // creating database
  Future openDb() async {
    if (_database == null) {
      _database = await openDatabase(
          join(await getDatabasesPath(), "reifen.db"),
          version: 1, onCreate: (Database db, int version) async {
        // creating table
        await db.execute(
            "CREATE TABLE reifen (id INTEGER PRIMARY KEY AUTOINCREMENT, zeichen TEXT, vl TEXT, vr TEXT, hl TEXT, hr TEXT)");
      });
    }
  }

  Future<int> insertReifen(Reifen reifen) async {
    await openDb();
    return await _database.insert('reifen', reifen.toMap());
  }

  Future<List<Reifen>> getReifenList() async {
    await openDb();
    final List<Map<String, dynamic>> maps = await _database.query('reifen');
    return List.generate(maps.length, (i) {
      return Reifen(
        id: maps[i]['id'],
        zeichen: maps[i]['zeichen'],
        vl: maps[i]['vl'],
        vr: maps[i]['vr'],
        hl: maps[i]['hl'],
        hr: maps[i]['hr'],
      );
    });
  }

  Future<int> updateReifen(Reifen reifen) async {
    await openDb();
    return await _database.update('reifen', reifen.toMap(),
        where: "id = ?", whereArgs: [reifen.id]);
  }

  Future<void> deleteReifen(int id) async {
    await openDb();
    await _database.delete('reifen', where: "id = ?", whereArgs: [id]);
  }
}



class Reifen {
  int id;
  String zeichen;
  String vl;
  String vr;
  String hl;
  String hr;

  Reifen(
      {@required this.zeichen,
        @required this.vl,
        @required this.vr,
        @required this.hl,
        @required this.hr,
        this.id});
  Map<String, dynamic> toMap() {
    return {'zeichen': zeichen, 'vl': vl, 'vr': vr, 'hl': hl, 'hr': hr};
  }
}

