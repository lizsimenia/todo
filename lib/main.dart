import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo/task_model.dart';

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:todo/pages/today_page.dart';
import 'package:todo/pages/incoming_page.dart';
import 'package:todo/pages/projects_page.dart';
import 'package:todo/pages/calendar_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService().init();

  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TaskAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(PriorityAdapter());
  }
  await initializeDateFormatting('ru', null);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlanApp',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const HomeScreen(),
    );
  }
}

String getGreeting() {
  final hour = DateTime.now().hour;
  if (hour >= 5 && hour < 12) {
    return 'Доброе утро!';
  } else if (hour >= 12 && hour < 18) {
    return 'Добрый день!';
  } else {
    return 'Добрый вечер!';
  }
}

String getTodayDateText() {
  final now = DateTime.now();
  final formatter = DateFormat('d MMMM - EEEE', 'ru');
  final formatted = formatter.format(now);
  final capitalized = formatted.replaceFirstMapped(
    RegExp(r'-\s(\w)'),
        (match) => '- ${match.group(1)!.toUpperCase()}',
  );
  return 'Сегодня – $formatted';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndexPage = 0;

  final List<Widget> _pages = const[
    TodayPage(),
    IncomingPage(),
    CalendarPage(),
    ProjectsPage(),
  ];

  void _selectNewPage(int index) {
    setState(() {
      _selectedIndexPage = index;
    });
  }

  void _selectAddTask() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        builder: (context) {
          return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery
                    .of(context)
                    .viewInsets
                    .bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: _AddTaskForm()
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getGreeting() + "  " + getTodayDateText()),

      ),
      body: _pages[_selectedIndexPage],
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndexPage,
        onTap: _selectNewPage,
        type: BottomNavigationBarType.fixed,
        items: const[
          BottomNavigationBarItem(icon: Icon(Icons.today),label: "Сегодня"),
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: "Входящие"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Календарь"),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: "Проект"),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: _selectAddTask,
          child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

// class Task {
//   final String title;
//   final Priority priority;
//   final DateTime? date;
//   final String project;
//
//   Task({
//     required this.title,
//     required this.priority,
//     this.date,
//     required this.project,
//   });
// }

// enum Priority {
//   urgentImportant,
//   urgentNotImportant,
//   notUrgentImportant,
//   notUrgentNotImportant
// }

final Map<Priority, Color> priorityColors = {
  Priority.urgentImportant: Colors.redAccent,
  Priority.urgentNotImportant: Colors.deepOrangeAccent,
  Priority.notUrgentImportant: Colors.amberAccent,
  Priority.notUrgentNotImportant: Colors.greenAccent,
};

class PrioritySelector extends StatelessWidget {
  final Priority? selectedPriority;
  final ValueChanged<Priority> onChanged;

  const PrioritySelector({
    Key? key,
    required this.selectedPriority,
    required this.onChanged,
  }) : super(key: key);

  static const Map<Priority, String> _labels = {
    Priority.urgentImportant: 'Срочно и важно',
    Priority.urgentNotImportant: 'Срочно и неважно',
    Priority.notUrgentImportant: 'Несрочно и важно',
    Priority.notUrgentNotImportant: 'Несрочно и неважно',
  };

  @override
  Widget build(BuildContext context) {
    return GridView.count(
        shrinkWrap: true,
        crossAxisCount: 4,
        childAspectRatio: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        physics: const NeverScrollableScrollPhysics(),
        children: Priority.values.map((priority){
          final isSelected = priority == selectedPriority;
          return GestureDetector(
            onTap: () => onChanged(priority),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? priorityColors[priority]: Colors.white10,
                borderRadius: BorderRadius.circular(100),
              ),
                alignment: Alignment.center,
            child: Text(
              _labels[priority]!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              )
            )
            )
          );
        }).toList(),
    );
  }
}


enum Date {
  today,
  tomorrow,
  dayAfterTomorrow,
  calendar
}

class DateSelector extends StatelessWidget {
  final Date? selectedDate;
  final ValueChanged<Date> onChanged;

  const DateSelector({
    Key? key,
    required this.selectedDate,
    required this.onChanged,
  }) : super(key: key);

  static const Map<Date, String> _labels = {
    Date.today: 'Сегодня',
    Date.tomorrow: 'Завтра',
    Date.dayAfterTomorrow: 'Послезавтра',
    Date.calendar: 'Выбрать дату',
  };

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      childAspectRatio: 6,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: Date.values.map((date){
        final isSelected = date == selectedDate;
        return GestureDetector(
            onTap: () => onChanged(date),
            child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  color: isSelected ? Colors.white10: Colors.grey.shade400,
                ),
                alignment: Alignment.center,
                child: Text(
                    _labels[date]!,
                    textAlign: TextAlign.center,
                )
            )
        );
      }).toList(),
    );
  }
}

class _AddTaskForm extends StatefulWidget {
  const _AddTaskForm({super.key});

  @override
  State<_AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<_AddTaskForm> {
  final _textController = TextEditingController();

  Priority? _selectedPriority;
  Date? _selectedDate;
  String? _selectedProject;

  bool _priorityError = false;
  bool _dateError = false;
  bool _textError = false;

  DateTime? _pickedDate;
  Color _sendButtonColor = Colors.teal;


  void _onSubmit() async{
    setState(() {
      _textError = _textController.text
          .trim()
          .isEmpty;
      _priorityError = _selectedPriority == null;
      _dateError = _selectedDate == null;
    });

    if (_textError || _priorityError || _dateError) {
      setState(() {
        _sendButtonColor = Colors.red;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _sendButtonColor = Colors.teal;
          });
        }
      });
      return;
    }

    DateTime taskDate;
    final now = DateTime.now();
    switch (_selectedDate!) {
      case Date.today:
        taskDate = now;
        break;
      case Date.tomorrow:
        taskDate = now.add(const Duration(days: 1));
        break;
      case Date.dayAfterTomorrow:
        taskDate = now.add(const Duration(days: 2));
        break;
      case Date.calendar:
        taskDate = _pickedDate ?? now;
        break;
    }

    final task = Task(
      title: _textController.text.trim(),
      priority: _selectedPriority!,
      date: taskDate,
      project: _selectedProject ?? 'Без проекта',
    );

    await HiveService().taskBox.add(task);
    Navigator.pop(context);
  }


  @override
  void initState(){
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child:
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                      hintText: "Введите задачу...",
                  )
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: _sendButtonColor,
                  onPressed: _onSubmit,
                  tooltip: 'Добавить задачу',
                ),
              ]
          ),
          const SizedBox(height: 20),
          PrioritySelector(
              selectedPriority: _selectedPriority,
              onChanged: (priority){
                setState(() {
                  _selectedPriority = priority;
                });
              }),
          const SizedBox(height: 20),
          DateSelector(
              selectedDate: _selectedDate,
              onChanged: (date) async{
                if (date == Date.calendar){
                  final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                  );
                }
                setState(() {
                  _selectedDate = date;
                });
              })
        ],
      )
    );

  }
}







