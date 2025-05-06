import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:todo/task_model.dart';
import 'package:todo/main.dart';
import 'package:todo/pages/today_page.dart';

void openEditProjectDialog(BuildContext context, Project project) {
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
            child: AddProjectForm(project: project),
          ),
        );
      }
  );
}

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  bool _checkedEmptyProjects = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checkedEmptyProjects) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndSuggestDeleteEmptyProjects();
      });
      _checkedEmptyProjects = true;
    }
  }
  void _checkAndSuggestDeleteEmptyProjects() async {
    final projectBox = HiveService().projectBox;
    final taskBox = HiveService().taskBox;

    final emptyProjects = projectBox.values.where((project) {
      return !taskBox.values.any((task) => task.project?.name == project.name);
    }).toList();
    if (emptyProjects.isNotEmpty) {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удалить пустые проекты?'),
          content: Text(
            'Найдены проекты без задач:\n' +
                emptyProjects.map((p) => '• ${p.name}').join('\n'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Нет'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Удалить'),
            ),
          ],
        ),
      );
      if (shouldDelete == true) {
        for (final project in emptyProjects) {
          final key = projectBox.keyAt(projectBox.values.toList().indexOf(project));
          await projectBox.delete(key);
        }
        if (mounted) setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService().projectBox.listenable(),
      builder: (context, Box<Project> projectBox, _) {
        final projects = projectBox.values.toList();
        if (projects.isEmpty) {
          return const Center(child: Text('Нет проектов'));
        }
        return ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ProjectExpansionTile(project: project);
          },
        );
      },
    );
  }
}

class ProjectExpansionTile extends StatelessWidget {
  final Project project;
  const ProjectExpansionTile({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: project.description != null && project.description!.isNotEmpty
            ? Text(project.description!)
            : null,
        trailing:
            Row(
                mainAxisSize: MainAxisSize.min,
                children:[
                  IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Удалить проект',
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удалить проект?'),
                        content: const Text('Все задачи, связанные с проектом удалятся.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Удалить')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final taskBox = HiveService().taskBox;
                      final tasksToDelete = taskBox.values
                          .where((task) => task.project?.name == project.name)
                          .toList();
                      for (final task in tasksToDelete) {
                        final key = taskBox.keyAt(taskBox.values.toList().indexOf(task));
                        await taskBox.delete(key);
                      }
                      final box = HiveService().projectBox;
                      final key = box.keyAt(box.values.toList().indexOf(project));
                      await box.delete(key);
                    }
                  },
                ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: 'Редактировать проект',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: AddProjectForm(project: project),
                            );
                          },
                        );
                      }
                  )
        ]
            ),
        children: [
          ProjectTasksList(project: project),
        ],
      ),
    );
  }
}

class ProjectTasksList extends StatelessWidget {
  final Project project;
  const ProjectTasksList({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: HiveService().taskBox.listenable(),
      builder: (context, Box<Task> taskBox, _) {
        final tasks = taskBox.values
            .where((task) => task.project?.name == project.name)
            .toList();
        if (tasks.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Нет задач в этом проекте'),
          );
        }
        return Column(
          children: tasks.map((task) => ProjectTaskTile(task: task)).toList(),
        );
      },
    );
  }
}

class ProjectTaskTile extends StatelessWidget {
  final Task task;
  const ProjectTaskTile({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: false,
        onChanged: (val) {
          HiveService().taskBox.deleteAt(HiveService().taskBox.values.toList().indexOf(task));
        },
      ),
      title: Text(task.title),
      subtitle: Text(
        task.date != null
            ? 'Дата: ${task.date!.day}.${task.date!.month}.${task.date!.year}'
            : 'Без даты',
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        tooltip: 'Изменить задачу',
        onPressed: () async {
            openEditTaskDialog(context, task);
          }
      ),
    );
  }
}
