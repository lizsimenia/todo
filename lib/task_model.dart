import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class Task {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final Priority priority;

  @HiveField(2)
  final DateTime? date;

  @HiveField(3)
  final Project? project;

  Task({
    required this.title,
    required this.priority,
    this.date,
    required this.project,
  });
}

@HiveType(typeId: 1)
enum Priority {
  @HiveField(0) urgentImportant,
  @HiveField(1) urgentNotImportant,
  @HiveField(2) notUrgentImportant,
  @HiveField(3) notUrgentNotImportant,
}

@HiveType(typeId: 2)
class Project{
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String? description;

  Project({required this.name, this.description});
}

