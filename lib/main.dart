import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'isar/Todo.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();

  final isar = await Isar.open(
    schemas: [TodoSchema],
    directory: dir.path,
  );
  runApp(MyApp(isar: isar));
}

class MyApp extends StatelessWidget {
  final Isar isar;
  const MyApp({Key? key, required this.isar}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Isar DB', isar: isar),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
    required this.isar,
  }) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  final Isar isar;
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String search = '';

  Future<List<Todo>> getTodos() async {
    print("dentro getTodos()");
    final res = await widget.isar.todos
        .filter()
        .titleContains(search)
        .sortByPublishDateDesc()
        .findAll();
    return res;
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          child: Column(
            // Column is also a layout widget. It takes a list of children and
            // arranges them vertically. By default, it sizes itself to fit its
            // children horizontally, and tries to be as tall as its parent.
            //
            // Invoke "debug painting" (press "p" in the console, choose the
            // "Toggle Debug Paint" action from the Flutter Inspector in Android
            // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
            // to see the wireframe for each widget.
            //
            // Column has various properties to control how it sizes itself and
            // how it positions its children. Here we use mainAxisAlignment to
            // center the children vertically; the main axis here is the vertical
            // axis because Columns are vertical (the cross axis would be
            // horizontal).
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 200,
                width: double.infinity,
                child: Container(
                    margin: EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: SingleChildScrollView(
                      child: FutureBuilder(
                        future: getTodos(),
                        builder: (context, dataSnapshot) {
                          print(dataSnapshot.connectionState);

                          if (dataSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(
                              child: Text("in lavorazione"),
                            );
                          } else {
                            if (dataSnapshot.error != null) {
                              return Center(
                                child: Text('An error occured'),
                              );
                            } else {
                              final a = (dataSnapshot.data as List).map((item) {
                                return rowTodo(item);
                                //return Text(item.title);
                              }).toList();
                              if (a.length == 0)
                                return Text('No results to show');
                              return Column(children: a);
                            }
                          }
                        },
                      ),
                    )),
              ),
              Divider(),
              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: TextFormField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      child: const Text('Save (title)'),
                      onPressed: () async {
                        if (_controller.text.trim().toString() == '') return;

                        final todo = Todo()
                          ..title = _controller.text.trim()
                          ..description = 'aaaaa'
                          ..publishDate = new DateTime.now();

                        await widget.isar.writeTxn((isar) async {
                          todo.id = await isar.todos.put(todo);
                        });
                        setState(() {
                          _controller.text = '';
                        });
                      },
                    ),
                  ),
                ],
              ),
              Divider(),
              Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        Text("Clear (and press Search) to not apply filters",
                            style: TextStyle(
                              fontSize: 10,
                            )),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        ElevatedButton(
                          child: const Text('Search (title)'),
                          onPressed: () async {
                            setState(() {
                              search = _searchController.text;
                            });
                          },
                        ),
                        Text("",
                            style: TextStyle(
                              fontSize: 10,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget rowTodo(Todo todo) {
    return new Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              new Expanded(flex: 1, child: Text(todo.id.toString())),
              new Expanded(flex: 5, child: Text(todo.title)),
              new Expanded(flex: 7, child: Text(todo.description)),
              Expanded(
                flex: 3,
                child: Text(
                  textAlign: TextAlign.end,
                  DateFormat('dd/MM/yyyy HH:mm')
                      .format(todo.publishDate)
                      .toString(),
                ),
              ),
            ],
          ),
        ));
  }
}
