import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Database table and column names
final String tableWords = 'words';
final String columnId = '_id';
final String columnWord = 'word';
final String columnFrequency = 'frequency';

// Data model class
class Word {
  int id;
  String word;
  int frequency;

  // Constructor to initialize fields
  Word({required this.id, required this.word, required this.frequency});

  // Convenience constructor to create a Word object from a map
  Word.fromMap(Map<String, dynamic> map)
      : id = map[columnId],
        word = map[columnWord],
        frequency = map[columnFrequency];

  // Convenience method to create a Map from this Word object
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnWord: word,
      columnFrequency: frequency,
    };
    if (id != null) {
      map[columnId] = id;
    }
    return map;
  }
}

// Singleton class to manage the database
class DatabaseHelper {
  // Database filename
  static final _databaseName = "MyDatabase.db";
  // Database version
  static final _databaseVersion = 1;

  // Make this a singleton class
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Single open connection to the database
  static Database? _database;
  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // Open the database
  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  // SQL string to create the database
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $tableWords (
            $columnId INTEGER PRIMARY KEY,
            $columnWord TEXT NOT NULL,
            $columnFrequency INTEGER NOT NULL
          )
          ''');
  }

  // Database helper methods:

  Future<int> insert(Word word) async {
    Database? db = await database;
    return await db!.insert(tableWords, word.toMap());
  }

  Future<Word?> queryWord(int id) async {
    Database? db = await database;
    List<Map> maps = await db!.query(tableWords,
        columns: [columnId, columnWord, columnFrequency],
        where: '$columnId = ?',
        whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Word.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Word>?> queryAllWords() async {
    Database? db = await database;
    List<Map> maps = await db!.query(tableWords);
    if (maps.isNotEmpty) {
      return maps.map((map) => Word.fromMap(map)).toList();
    }
    return null;
  }

  Future<int> deleteWord(int id) async {
    Database? db = await database;
    return await db!.delete(tableWords, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> update(Word word) async {
    Database? db = await database;
    return await db!.update(tableWords, word.toMap(),
        where: '$columnId = ?', whereArgs: [word.id]);
  }
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saving data'),
      ),
      body: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              child: Text('Read'),
              onPressed: () {
                _read();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                _save();
              },
            ),
          ),
        ],
      ),
    );
  }

  // Shared preferences

  _read() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'my_int_key';
    final value = prefs.getInt(key) ?? 0;
    print('read: $value');
  }

  _save() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'my_int_key';
    final value = 42;
    prefs.setInt(key, value);
    print('saved: $value');
  }

  // Uncomment to use Database
  /*
  _read() async {
    DatabaseHelper helper = DatabaseHelper.instance;
    int rowId = 1;
    Word? word = await helper.queryWord(rowId);
    if (word == null) {
      print('read row $rowId: empty');
    } else {
      print('read row $rowId: ${word.word} ${word.frequency}');
    }
  }

  _save() async {
    Word word = Word(id: 1, word: 'hello', frequency: 15);
    DatabaseHelper helper = DatabaseHelper.instance;
    int id = await helper.insert(word);
    print('inserted row: $id');
  }
  */

  // Uncomment to use File
  /*
  _read() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/my_file.txt');
      String text = await file.readAsString();
      print(text);
    } catch (e) {
      print("Couldn't read file");
    }
  }

  _save() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/my_file.txt');
    final text = 'Hello World!';
    await file.writeAsString(text);
    print('saved');
  }
  */
}
