import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io' as io;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NotePad 7001513',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Widget _currentPage;
  int _currentIndex = 0;
  List _listPages = List();

  void _changePage(int selectedIndex) {
    setState(() {
      _currentIndex = selectedIndex;
      _currentPage = _listPages[selectedIndex];
    });
  }

  @override
  void initState() {
    super.initState();
    _listPages..add(All())..add(Favorites());
    _currentPage = All();
  }

  void _openPageAddNote(
      {BuildContext context, bool fullscreenDialog = false, Notes note}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: fullscreenDialog,
            builder: (context) => AddNote(todo: note)));
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      //backgroundColor: Colors.black12,
      appBar: AppBar(
        title: Text("NotePad 7001513"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch();
            },
          )
        ],
        backgroundColor: Colors.black87,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(1.0),
          child: _currentPage,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () => _openPageAddNote(
            context: context, fullscreenDialog: false, note: null),
        tooltip: 'Add',
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.white,
        onTap: (selectedIndex) => _changePage(selectedIndex),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.all_inclusive),
            title: Text('All Notes'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            title: Text('Favorite Notes'),
          ),
        ],
      ),
    );
  }
}

class All extends StatefulWidget {
  @override
  _AllPageState createState() => _AllPageState();
}

class _AllPageState extends State<All> {
  Future<List<Notes>> notes;
  int noteIdForUpdate;
  bool isUpdate = false;
  DBHelper dbHelper;

  @override
  void initState() {
    super.initState();
    dbHelper = DBHelper();
    refreshNoteList();
  }

  refreshNoteList() {
    setState(() {
      notes = dbHelper.getNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    notes = dbHelper.getNotes();
    // TODO: implement build
    return Scaffold(
        backgroundColor: Colors.black,
        body: Column(children: <Widget>[
          Expanded(
            child: FutureBuilder(
              future: notes,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  print("$snapshot");
                  return ListView.separated(
                      itemCount: snapshot.data.length,
                      padding: const EdgeInsets.all(8),
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(),
                      itemBuilder: (BuildContext context, int index) {
                        //generateList2(snapshot.data[index],context);
                        return Column(
                          children: <Widget>[
                            generateList2(snapshot.data[index], context)
                          ],
                        );
                      });
                }
                return CircularProgressIndicator();
              },
            ),
          ),
          Center(
            child: Text(notes != null ? "No Note has been created" : null),
          )
        ]));
    ;
  }

  void _openPageAddNote(
      {BuildContext context, bool fullscreenDialog = false, Notes note}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: fullscreenDialog,
            builder: (context) => AddNote(todo: note)));
  }

  Container generateList2(Notes note, BuildContext context) {
    return Container(
      color: Colors.amberAccent,
      alignment: Alignment.center,
      height: 125,
      child: ListTile(
          title: Text(
              note.name.length > 15 ? note.name.substring(0, 15) : note.name,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          subtitle: Text(
              note.content.length > 40
                  ? note.content.substring(0, 40)
                  : note.content,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.normal)),
          onTap: () {
            _openPageAddNote(
                context: context, fullscreenDialog: false, note: note);
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: Icon(
                    note.fav == 0 ? Icons.favorite_border : Icons.favorite,
                    color: Colors.red),
                onPressed: () {
                  if (note.fav == 1) {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text("Note deleted from favorites"),
                    ));
                    dbHelper
                        .update(Notes(note.id, note.name, note.content, 0))
                        .then((data) {
                      setState(() {
                        isUpdate = false;
                      });
                    });
                  } else {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text("Note added to favorites"),
                    ));
                    dbHelper
                        .update(Notes(note.id, note.name, note.content, 1))
                        .then((data) {
                      setState(() {
                        isUpdate = false;
                      });
                    });
                  }
                  refreshNoteList();
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.black,
                ),
                onPressed: () {
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text("Note deleted"),
                  ));
                  dbHelper.delete(note.id);
                  refreshNoteList();
                },
              ),
            ],
          )),
    );
  }
}

class AddNote extends StatefulWidget {
  final Notes todo;

  const AddNote({Key key, @required this.todo}) : super(key: key);

  @override
  _AddNoteState createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  final GlobalKey<FormState> _formStateKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _formStateKey2 = GlobalKey<FormState>();

  Future<List<Notes>> notes;
  int noteIdForUpdate;
  String _noteName;
  String _content;
  bool isUpdate = false;
  DBHelper dbHelper;
  final _noteNameController = TextEditingController();
  final _noteNameController2 = TextEditingController();

  @override
  void initState() {
    super.initState();
    dbHelper = DBHelper();
    if (widget.todo != null) {
      _noteNameController.text = widget.todo.name;
      _noteNameController2.text = widget.todo.content;
    }
  }

  refreshNoteList() {
    setState(() {
      notes = dbHelper.getNotes();
    });
  }

  Future<void> _showMyDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('You must fill out all the blank spaces'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return WillPopScope(
        onWillPop: () async {
          _formStateKey.currentState.save();
          _formStateKey2.currentState.save();
          if (_noteName.isEmpty) {
            _noteName = "No name";
          }
          if (!_content.isEmpty) {
            if (widget.todo != null) {
              dbHelper.update(
                  Notes(widget.todo.id, _noteName, _content, widget.todo.fav));
            } else {
              dbHelper.add(Notes(null, _noteName, _content, 0));
            }
          }
          refreshNoteList();
          return true;
        },
        child: Scaffold(
            appBar: AppBar(
              title: Text(widget.todo == null ? "Add Note" : "Edit note"),
              backgroundColor: Colors.black87,
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () {
                    _formStateKey.currentState.save();
                    _formStateKey2.currentState.save();
                    if (_noteName.isEmpty || _content.isEmpty) {
                      _showMyDialog(context);
                    } else {
                      if (widget.todo != null) {
                        dbHelper.update(Notes(widget.todo.id, _noteName,
                            _content, widget.todo.fav));
                      } else {
                        dbHelper.add(Notes(null, _noteName, _content, 0));
                      }
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
            backgroundColor: Colors.black,
            body: Container(
              color: Colors.amberAccent,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.all(5),
                children: <Widget>[
                  Form(
                    key: _formStateKey,
                    autovalidate: true,
                    child: Padding(
                      padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                      child: TextFormField(
                        cursorColor: Colors.black,
                        validator: (value) =>
                            value.isEmpty ? 'Please Enter Note Name' : null,
                        onSaved: (value) => _noteName = value,
                        controller: _noteNameController,
                        decoration: InputDecoration(
                            hintText: "Note name",
                            labelText: "Note name",
                            labelStyle: TextStyle(
                              color: Colors.black,
                            )),
                      ),
                    ),
                  ),
                  Form(
                    key: _formStateKey2,
                    autovalidate: true,
                    child: Padding(
                        padding:
                            EdgeInsets.only(left: 10, right: 10, bottom: 10),
                        child: Container(
                          height: 400,
                          child: TextFormField(
                            validator: (value) => value.isEmpty
                                ? 'Please Enter the data in the note'
                                : null,
                            onSaved: (value) => _content = value,
                            maxLines: 30,
                            cursorColor: Colors.black,
                            controller: _noteNameController2,
                            decoration:
                                InputDecoration(hintText: "Write your text"),
                          ),
                        )),
                  ),
                ],
              ),
            )));
  }
}

class Favorites extends StatefulWidget {
  @override
  _FavoritesState createState() => _FavoritesState();
}

class _FavoritesState extends State<Favorites> {
  Future<List<Notes>> notes;
  int noteIdForUpdate;
  bool isUpdate = false;
  DBHelper dbHelper;

  @override
  void initState() {
    super.initState();
    dbHelper = DBHelper();
    refreshNoteList();
  }

  refreshNoteList() {
    setState(() {
      notes = dbHelper.getFavNotes();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    refreshNoteList();
    if (state == AppLifecycleState.resumed) {
      setState(() {
        refreshNoteList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    notes = dbHelper.getFavNotes();
    return Scaffold(
        backgroundColor: Colors.black,
        body: Column(children: <Widget>[
          Expanded(
            child: FutureBuilder(
              future: notes,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.separated(
                      itemCount: snapshot.data.length,
                      padding: const EdgeInsets.all(8),
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(),
                      itemBuilder: (BuildContext context, int index) {
                        //generateList2(snapshot.data[index],context);
                        return Column(
                          children: <Widget>[
                            generateList2(snapshot.data[index], context)
                          ],
                        );
                      });
                }
                return CircularProgressIndicator();
              },
            ),
          ),
        ]));
    ;
  }

  void _openPageAddNote(
      {BuildContext context, bool fullscreenDialog = false, Notes note}) {
    Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: fullscreenDialog,
            builder: (context) => AddNote(todo: note)));
  }

  Container generateList2(Notes note, BuildContext context) {
    return Container(
      color: Colors.amberAccent,
      alignment: Alignment.center,
      height: 125,
      child: ListTile(
          title: Text(
            note.name.length > 20 ? note.name.substring(0, 20) : note.name,
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            note.content.length > 40
                ? note.content.substring(0, 40)
                : note.content,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.normal),
          ),
          onTap: () {
            _openPageAddNote(
                context: context, fullscreenDialog: false, note: note);
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: Icon(
                    note.fav == 0 ? Icons.favorite_border : Icons.favorite,
                    color: Colors.red),
                onPressed: () {
                  if (note.fav == 1) {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: Text("Note deleted from favorites"),
                    ));
                    dbHelper
                        .update(Notes(note.id, note.name, note.content, 0))
                        .then((data) {
                      setState(() {
                        isUpdate = false;
                      });
                    });
                  } else {
                    dbHelper
                        .update(Notes(note.id, note.name, note.content, 1))
                        .then((data) {
                      setState(() {
                        isUpdate = false;
                      });
                    });
                  }
                  refreshNoteList();
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Colors.black,
                ),
                onPressed: () {
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: Text("Note deleted"),
                  ));
                  dbHelper.delete(note.id);
                  refreshNoteList();
                },
              ),
            ],
          )),
    );
  }
}

class Notes {
  int id;
  String name;
  String content;
  int fav;

  Notes(this.id, this.name, this.content, this.fav);

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'name': name,
      'content': content,
      'favorite': fav
    };
    return map;
  }

  Notes.fromMap(Map<String, dynamic> map) {
    id = map['id'];
    name = map['name'];
    content = map['content'];
    fav = map['favorite'];
  }
}

class DBHelper {
  static Database _db;

  Future<Database> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDatabase();
    return _db;
  }

  initDatabase() async {
    io.Directory documentDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentDirectory.path, 'notes5.db');
    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  _onCreate(Database db, int version) async {
    await db.execute(
        'CREATE TABLE notes5 (id INTEGER PRIMARY KEY, name TEXT, content TEXT, favorite INTEGER)');
  }

  Future<Notes> add(Notes note) async {
    var dbClient = await db;
    note.id = await dbClient.insert('notes5', note.toMap());
    return note;
  }

  Future<List<Notes>> getNotes() async {
    var dbClient = await db;
    List<Map> maps = await dbClient
        .query('notes5', columns: ['id', 'name', 'content', 'favorite']);
    List<Notes> notes = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        notes.add(Notes.fromMap(maps[i]));
      }
    }
    return notes;
  }

  Future<List<Notes>> getFavNotes() async {
    var dbClient = await db;
    List<Map> maps = await dbClient
        .query('notes5', columns: ['id', 'name', 'content', 'favorite']);
    List<Notes> notes = [];
    if (maps.length > 0) {
      for (int i = 0; i < maps.length; i++) {
        if (Notes.fromMap(maps[i]).fav == 1) {
          notes.add(Notes.fromMap(maps[i]));
        }
      }
    }
    return notes;
  }

  Future<int> delete(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'notes5',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> update(Notes note) async {
    var dbClient = await db;
    return await dbClient.update(
      'notes5',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future close() async {
    var dbClient = await db;
    dbClient.close();
  }
}
