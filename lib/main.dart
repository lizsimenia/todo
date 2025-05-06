import 'package:flutter/material.dart';
import 'package:todo/task_model.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:todo/pages/today_page.dart';
import 'package:todo/pages/incoming_page.dart';
import 'package:todo/pages/projects_page.dart';
import 'package:todo/pages/calendar_page.dart';


import 'package:windows_notification/windows_notification.dart';
import 'package:windows_notification/notification_message.dart';

final winNotifyPlugin = WindowsNotification(applicationId: 'com.todo.todo');
Future<void> showTodayTasksNotification(List<Task> todayTasks) async {
  String message = 'Сегодня по планам:';
  for (int i = 0; i < todayTasks.length; i++) {
    message += '\n${i + 1}. ${todayTasks[i].title}';
  }

  final notificationMessage = NotificationMessage.fromPluginTemplate(
    'today_tasks',           // Идентификатор уведомления
    'Ваши задачи на сегодня', // Заголовок уведомления
    message,                  // Текст уведомления
  );

  await winNotifyPlugin.showNotificationPluginTemplate(notificationMessage);
}


class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  Box<Task>? _taskBox;
  Box<Project>? _projectBox;

  Future<void> init() async {
    final applicationDocumentDir = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(applicationDocumentDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TaskAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(PriorityAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(ProjectAdapter());
    }

    _taskBox = await Hive.openBox<Task>('tasks');
    _projectBox = await Hive.openBox<Project>('projects');
  }

  Box<Task> get taskBox {
    if (_taskBox == null) throw Exception('Hive box not initialized');
    return _taskBox!;
  }

  Box<Project> get projectBox {
    if (_projectBox == null) throw Exception('Hive box not initialized');
    return _projectBox!;
  }
}

class TaskProjectSwitcher extends StatefulWidget {
  final Function(bool isTask) onChanged;
  final bool isTask;

  const TaskProjectSwitcher({
    super.key,
    required this.onChanged,
    required this.isTask,
  });

  @override
  State<TaskProjectSwitcher> createState() => _TaskProjectSwitcherState();
}

class _TaskProjectSwitcherState extends State<TaskProjectSwitcher> {
  late bool _isTask;

  @override
  void initState() {
    super.initState();
    _isTask = widget.isTask;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: _isTask ? Alignment.centerLeft : Alignment.centerRight,
            duration: Duration(milliseconds: 200),
            curve: Curves.ease,
            child: Container(
              width: 90,
              height: 36,
              margin: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(50),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isTask = true;
                    });
                    widget.onChanged(true);
                  },
                  child: Center(
                    child: Text(
                      'Задача',
                      style: TextStyle(
                        color: _isTask ? Colors.black : Colors.grey,
                        fontWeight: _isTask ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isTask = false;
                    });
                    widget.onChanged(false);
                  },
                  child: Center(
                    child: Text(
                      'Проект',
                      style: TextStyle(
                        color: !_isTask ? Colors.black : Colors.grey,
                        fontWeight: !_isTask ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


void main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await HiveService().init();
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
  final parts = formatted.split(' - ');

  final datePart = parts[0];
  final dayPart = parts[1][0].toUpperCase() + parts[1].substring(1);
  return 'Сегодня – $datePart – $dayPart';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _notification = false;

  @override
  void initState() {
    super.initState();
      if (!_notification) {
        final box = HiveService().taskBox;
        final today = DateTime.now();
        final todayTasks = box.values.where((task) {
          final taskDate = task.date!;
          return taskDate.year == today.year &&
              taskDate.month == today.month &&
              taskDate.day == today.day;
        }).toList();

        if (todayTasks.isNotEmpty) {
          showTodayTasksNotification(todayTasks);
          _notification = true;
        }
      }
  }

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

  void _selectAdd() {
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
              child: AddForm()
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            "${getGreeting()}  ${getTodayDateText()}",
            style: TextStyle(fontWeight: FontWeight.bold)),

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
          onPressed: _selectAdd,
          child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

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
    super.key,
    required this.selectedPriority,
    required this.onChanged,
  });

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
    super.key,
    required this.selectedDate,
    required this.onChanged,
  });

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
      childAspectRatio: 4,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
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


class AddTaskForm extends StatefulWidget {
  final Task? task;
  final Project? initialProject;

  const AddTaskForm({super.key, this.task, this.initialProject});

  @override
  State<AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends State<AddTaskForm> {
  final _textController = TextEditingController();

  Priority? _selectedPriority;
  Date? _selectedDate;
  Project? _selectedProject;

  bool _priorityError = false;
  bool _dateError = false;
  bool _textError = false;

  DateTime? _pickedDate;
  Color _sendButtonColor = Colors.teal;

  @override
  void initState() {
    super.initState();

    _textController.text = widget.task?.title ?? '';
    _selectedPriority = widget.task?.priority;
    _selectedProject = widget.task?.project ?? widget.initialProject;

    if (widget.task?.date != null) {
      final now = DateTime.now();
      final taskDate = widget.task!.date!;
      final difference = taskDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      if (difference == 0) {
        _selectedDate = Date.today;
      } else if (difference == 1) {
        _selectedDate = Date.tomorrow;
      } else if (difference == 2) {
        _selectedDate = Date.dayAfterTomorrow;
      } else {
        _selectedDate = Date.calendar;
        _pickedDate = taskDate;
      }
    }
  }

  void _onSubmit() async {
    setState(() {
      _priorityError = _selectedPriority == null;
      _dateError = _selectedDate == null;
      _textError = _textController.text == '';
    });

    if (_priorityError || _dateError || _textError) {
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

    if (widget.task == null) {
      final task = Task(
        title: _textController.text.trim(),
        priority: _selectedPriority!,
        date: taskDate,
        project: _selectedProject,
      );
      await HiveService().taskBox.add(task);
    } else {
      final taskIndex = HiveService().taskBox.values.toList().indexOf(
          widget.task!);
      if (taskIndex != -1) {
        final updatedTask = Task(
          title: _textController.text.trim(),
          priority: _selectedPriority!,
          date: taskDate,
          project: _selectedProject,
        );
        await HiveService().taskBox.putAt(taskIndex, updatedTask);
      }
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
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
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = Date.calendar;
                      _pickedDate = pickedDate;
                    });
                  }
                } else {
                  setState(() {
                    _selectedDate = date;
                    _pickedDate = null;
                  });
                }
              }),
          const SizedBox(height: 20),
          const Text('Задача относится к проекту?'),
          ProjectSelector(
            selectedProject: _selectedProject,
            onChanged: (project) {
              setState(() {
                _selectedProject = project;
              });
            },
          ),
        ],

      )
    );

  }
}


class ProjectSelector extends StatelessWidget {
  final Project? selectedProject;
  final ValueChanged<Project?> onChanged;

  const ProjectSelector({
    super.key,
    required this.selectedProject,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final projects = HiveService().projectBox.values.toList();

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      childAspectRatio: 4,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        GestureDetector(
          onTap: () => onChanged(null),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: selectedProject == null
                  ? Colors.white10
                  : Colors.grey.shade400,
            ),
            alignment: Alignment.center,
            child: const Text(
              'Без проекта',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        ...projects.map((project) {
          final isSelected = project == selectedProject;
          return GestureDetector(
            onTap: () => onChanged(project),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: isSelected ? Colors.white10 : Colors.grey.shade400,
              ),
              alignment: Alignment.center,
              child: Text(
                project.name,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}



class AddProjectForm extends StatefulWidget {
  final Project? project;
  const AddProjectForm({super.key, this.project});

  @override
  State<AddProjectForm> createState() => _AddProjectFormState();
}

class _AddProjectFormState extends State<AddProjectForm> {
  final _projectNameController = TextEditingController();
  final _projectDescController = TextEditingController();

  bool _isNameDuplicate = false;
  Project? _savedProject;
  bool get _canSaveProject {
    final name = _projectNameController.text.trim();
    final desc = _projectDescController.text.trim();
    if (name.isEmpty) return false;
    if (widget.project == null) {
      return true;
    } else {
      return name != widget.project!.name || desc != (widget.project!.description ?? '');
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _projectNameController.text = widget.project!.name;
      _projectDescController.text = widget.project!.description ?? '';
      _savedProject = widget.project;
    }
    _projectNameController.addListener(_onProjectNameChanged);
    _projectDescController.addListener(_onProjectFieldChanged);
  }

  @override
  void dispose() {
    _projectNameController.removeListener(_onProjectNameChanged);
    _projectDescController.removeListener(_onProjectFieldChanged);
    _projectNameController.dispose();
    _projectDescController.dispose();
    super.dispose();
  }

  void _onProjectFieldChanged() {
    setState(() {
    });
  }
  void _onProjectNameChanged() {
    if (_savedProject != null &&
        _savedProject!.name != _projectNameController.text.trim()) {
      setState(() {
        _savedProject = null;
      });
    }
    setState(() {});
  }

  Future<void> _saveProject() async {
    final name = _projectNameController.text.trim();
    final desc = _projectDescController.text.trim();
    if (name.isEmpty) return;

    checkDuplicate();
    final exists = HiveService().projectBox.values.any((p) => p.name == name);
    if (exists) {return ;}

    if (widget.project == null) {
      final project = Project(
        name: name,
        description: desc,
      );
      await HiveService().projectBox.add(project);
      setState(() {
        _savedProject = project;
      });
    }
    else{
      final index = HiveService().projectBox.values.toList().indexOf(widget.project!);
      if (index != -1) {
        final updatedProject = Project(name: name, description: desc);
        await HiveService().projectBox.putAt(index, updatedProject);

        final taskBox = HiveService().taskBox;
        final tasksToUpdate = taskBox.values
            .where((task) => task.project?.name == widget.project!.name)
            .toList();
        for (final task in tasksToUpdate) {
          final taskIndex = taskBox.values.toList().indexOf(task);
          final updatedTask = Task(
            title: task.title,
            date: task.date,
            priority: task.priority,
            project: updatedProject,
          );
          await taskBox.putAt(taskIndex, updatedTask);
        }
        setState(() {
          _savedProject = updatedProject;
        });
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addTaskToProject() async {
    if (_savedProject == null) return;
    showDialog<Task>(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: const EdgeInsets.all(16),
        content: SizedBox(
          width: 700,
          child: AddTaskForm(initialProject: _savedProject),
        ),
      ),
    );
  }

  void checkDuplicate() {
    final name = _projectNameController.text.trim();
    final isEditing = widget.project != null;
    final exists = HiveService().projectBox.values.any((p) =>
    p.name == name && (!isEditing || p != widget.project)
    );

    if (!isEditing && exists) {
      setState(() {
        _isNameDuplicate = true;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: _projectNameController,
            decoration: InputDecoration(
              labelText: 'Название проекта',
              errorText: _isNameDuplicate ? 'Проект уже существует' : null,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _projectDescController,
            decoration: const InputDecoration(
              labelText: 'Описание',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _canSaveProject
                      ? _saveProject
                      : null,
                  child: const Text('Сохранить проект'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить задачу'),
                  onPressed: _savedProject != null ? _addTaskToProject : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder(
            valueListenable: HiveService().taskBox.listenable(),
            builder: (context, Box<Task> box, _) {
              final tasks = box.values
                  .where((task) => task.project?.name == _savedProject?.name)
                  .toList();

              if (tasks.isEmpty) return const SizedBox();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text(
                    'Задачи проекта:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  ...tasks.map((task) => ListTile(
                    title: Text(task.title),
                    subtitle: Text(
                      task.date != null
                          ? DateFormat('dd.MM.yyyy').format(task.date!)
                          : 'Без даты',
                    ),
                  )),
                ],
              );
            },
          )

        ],
      ),
    );
  }
}


class AddForm extends StatefulWidget {
  final Task? task;

  const AddForm({super.key, this.task});

  @override
  State<AddForm> createState() => _AddFormState();
}

class _AddFormState extends State<AddForm> {
  bool isTask = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
    width: 700,
      height: 320,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TaskProjectSwitcher(
          isTask: isTask,
          onChanged: (value) {
            setState(() {
              isTask = value;
            });
          },
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
          child: isTask
              ? AddTaskForm(task: widget.task) : AddProjectForm(),
        ),
        )
      ],
    ),
    );
  }
}







