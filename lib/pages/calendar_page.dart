import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:todo/main.dart';
import 'package:todo/pages/today_page.dart';

import 'package:todo/task_model.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Task>> _tasksByDate = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _groupTasksByDate(Box<Task> box) {
    final Map<DateTime, List<Task>> grouped = {};

    for (var task in HiveService().taskBox.values) {
      final date = DateTime(task.date!.year, task.date!.month, task.date!.day);
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(task);
    }
    _tasksByDate = grouped;
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _tasksByDate[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar<Task>(
          firstDay: DateTime.utc(2000, 1, 1),
          lastDay: DateTime.utc(2100, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          eventLoader: _getTasksForDay,
          calendarFormat: _calendarFormat,
          onDaySelected: (selectedDay, focusedDay) {
            if (!mounted) return;
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });},
          onFormatChanged: (format) {
            if (!mounted) return;
              setState(() {
                _calendarFormat = format;
              });
            },
            headerStyle: HeaderStyle(
            formatButtonVisible: true,
            ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width:20,
                    height: 20,
                    // padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${events.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _buildTaskList(),
        ),
      ],
    );
  }

  Widget _buildTaskList() {
    return ValueListenableBuilder(
        valueListenable: HiveService().taskBox.listenable(),
        builder: (context, Box<Task> box, _) {
          _groupTasksByDate(box);
        final tasks = _selectedDay == null ? [] : _getTasksForDay(_selectedDay!);
        if (tasks.isEmpty) {
          return const Center(child: Text('Задачи отсутствуют'));
        }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          title: Text("${index+1}. ${task.title}"),
          trailing: _priorityIndicator(task.priority),
          onTap: () {
            openEditTaskDialog(context, task);
          },
        );
      },
    );
  });
  }

  Widget _priorityIndicator(Priority priority) {
    final color = priorityColors[priority];
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
