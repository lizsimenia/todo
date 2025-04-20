import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo/task_model.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  Box<Task>? _taskBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    _taskBox = await Hive.openBox<Task>('tasks');
  }

  Box<Task> get taskBox {
    if (_taskBox == null) throw Exception('Hive box not initialized');
    return _taskBox!;
  }
}


class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService().taskBox.listenable(),
      builder: (context, Box<Task> box, _) {
        final tasks = box.values.toList();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Dismissible(
              key: Key(task.title),
              background: Container(color: Colors.red),
              onDismissed: (_) => box.deleteAt(index),
              child: ListTile(
                title: Text(task.title)
              ),
            );
          },
        );
      },
    );
  }

  // void _showEditTaskDialog(BuildContext context, Task task, int index) {
  //   // Реализация формы редактирования аналогична _AddTaskForm
  // }
  //
  // String _formatDate(DateTime? date) { ... }
}
