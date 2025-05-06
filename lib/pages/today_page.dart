import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:todo/main.dart';
import 'package:todo/task_model.dart';


void openEditTaskDialog(BuildContext context, Task task) {
  showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.all(16),
          content: SizedBox(
            width: 700,
            child: AddTaskForm(task: task),
          ),
        );
      }
  );
}

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService().taskBox.listenable(),
      builder: (context, Box<Task> box, _) {
        final tasks = box.values.toList();
        final today = DateTime.now();
        final todayTasks = tasks.where((task) {
          final taskDate = task.date!;
          return taskDate.year == today.year &&
              taskDate.month == today.month &&
              taskDate.day == today.day;
        }).toList();
        todayTasks.sort((a, b) => a.priority.index.compareTo(b.priority.index));
        if (todayTasks.isEmpty) {
          return Center(
            child: SvgPicture.asset(
              'assets/pics/aim.svg',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          );
        } else {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: todayTasks.length,
          itemBuilder: (context, index) {
            final task = todayTasks[index];
            return Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
            child: Dismissible(
              key: Key(task.title),
              background: Container(color: Colors.red),
              onDismissed: (_) => box.deleteAt(box.values.toList().indexOf(task)),
              child: ListTile(
                onTap: () {
                  openEditTaskDialog(context, task);
                },
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: priorityColors[task.priority],
                    shape: BoxShape.circle,
                  ),
                ),
                leading: Checkbox(
                  value: false,
                  onChanged: (bool? checked) {
                    if (checked == true) {
                      final taskIndex = box.values.toList().indexOf(task);
                      box.deleteAt(taskIndex);
                    }
                  },
                ),
                title: Text(task.title),
              ),
            )
            );
          },
        );
        }
      },
    );
  }
}

