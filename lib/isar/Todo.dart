import 'package:isar/isar.dart';

part 'Todo.g.dart';

@Collection()
class Todo {
  @Id()
  int id = Isar.autoIncrement;

  late String title;

  late String description;

  @Index()
  late DateTime publishDate;
}
