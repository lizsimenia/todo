import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:todo/main.dart';
import 'package:todo/task_model.dart';

import 'package:todo/pages/today_page.dart';

import 'package:intl/intl.dart';

Map<String, List<Task>> groupTasksByDate(Box<Task> tasks) {
  final Map<String, List<Task>> groupedTasks = {};
  final dateFormat = DateFormat('yyyy-MM-dd');

  List<Task> allTasks = tasks.values.toList();
  allTasks.sort((a, b) => a.priority.index.compareTo(b.priority.index));

  for (var task in allTasks) {
    final dateKey = dateFormat.format(task.date!);
    if (!groupedTasks.containsKey(dateKey)) {
      groupedTasks[dateKey] = [];
    }
    groupedTasks[dateKey]!.add(task);
  }
  return groupedTasks;
}


class IncomingPage extends StatelessWidget {
  const IncomingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService().taskBox.listenable(),
      builder: (context, Box<Task> box, _) {
    final groupedTasks = groupTasksByDate(HiveService().taskBox);
    final dateKeys = groupedTasks.keys.toList()..sort();
    if (groupedTasks.isEmpty) {
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
    itemCount: groupedTasks.length,
    itemBuilder: (context, index) {
    final dateKey = dateKeys[index];
    final tasksForDate = groupedTasks[dateKey];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateKey,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        ...tasksForDate!.map((task) {
          final taskKey = box.keyAt(box.values.toList().indexOf(task));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
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
          key: Key(taskKey.toString()),
          background: Container(color: Colors.red),
          onDismissed: (_) => box.delete(taskKey),
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
      box.delete(taskKey);
      }
      },
      ),
      title: Text(task.title),
      ),
      ),
      );
      }
        ),
      ],
    );
    },
    );}
      },
    );
  }
}

