import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class Task {
  String title;
  bool isCompleted;

  Task(this.title, this.isCompleted);

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      json['title'] as String,
      json['isCompleted'] as bool,
    );
  }
}

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  void addTask(String title) {
    _tasks.add(Task(title, false));
    _saveTasks();
    notifyListeners();
  }

  void deleteTask(int index) {
    _tasks.removeAt(index);
    _saveTasks();
    notifyListeners();
  }

  void editTask(int index, String newTitle) {
    _tasks[index].title = newTitle;
    _saveTasks();
    notifyListeners();
  }

  void toggleTaskCompletion(int index) {
    _tasks[index].isCompleted = !_tasks[index].isCompleted;
    _saveTasks();
    notifyListeners();
  }

  void reorderTasks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final task = _tasks.removeAt(oldIndex);
    _tasks.insert(newIndex, task);
    _saveTasks();
    notifyListeners();
  }

  void setTasks(List<Task> loadedTasks) {
    _tasks = loadedTasks;
    notifyListeners();
  }

  void _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskListJson =
        json.encode(_tasks.map((task) => task.toJson()).toList());
    prefs.setString('tasks', taskListJson);
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final taskListJson = prefs.getString('tasks');
    if (taskListJson != null) {
      final taskList = json.decode(taskListJson) as List<dynamic>;
      _tasks = taskList.map((taskMap) => Task.fromJson(taskMap)).toList();
      notifyListeners();
    }
  }

  Future<void> persistData() async {
    final prefs = await SharedPreferences.getInstance();
    final taskListJson = prefs.getString('tasks');
    if (taskListJson != null) {
      final taskList = json.decode(taskListJson) as List<dynamic>;
      final loadedTasks =
          taskList.map((taskMap) => Task.fromJson(taskMap)).toList();

      setTasks(loadedTasks);
    }
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskProvider()..loadTasks(),
      child: MaterialApp(
        title: 'To-do List App',
        home: TaskListScreen(),
      ),
    );
  }
}

class TaskListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('To-do List'),
      ),
      body: ReorderableListView.builder(
        itemCount: taskProvider.tasks.length,
        itemBuilder: (context, index) {
          final task = taskProvider.tasks[index];
          return Dismissible(
            key: Key(task.title),
            onDismissed: (_) => taskProvider.deleteTask(index),
            child: ListTile(
              title: Text(task.title),
              leading: Checkbox(
                value: task.isCompleted,
                onChanged: (_) => taskProvider.toggleTaskCompletion(index),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => taskProvider.deleteTask(index),
                    child: Icon(Icons.delete, color: Colors.red),
                  ),
                  SizedBox(width: 16),
                ],
              ),
              onTap: () async {
                final newTitle = await showDialog(
                  context: context,
                  builder: (context) =>
                      EditTaskDialog(initialValue: task.title),
                );
                if (newTitle != null) {
                  taskProvider.editTask(index, newTitle);
                }
              },
            ),
          );
        },
        onReorder: (oldIndex, newIndex) {
          taskProvider.reorderTasks(oldIndex, newIndex);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await showDialog(
            context: context,
            builder: (context) => NewTaskDialog(),
          );
          if (newTask != null) {
            taskProvider.addTask(newTask);
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class NewTaskDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String newTaskTitle = '';

    return AlertDialog(
      title: Text('New Task'),
      content: TextField(
        onChanged: (value) {
          newTaskTitle = value;
        },
        decoration: InputDecoration(hintText: 'Enter task title'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (newTaskTitle.isNotEmpty) {
              Navigator.of(context).pop(newTaskTitle);
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}

class EditTaskDialog extends StatelessWidget {
  final String initialValue;

  const EditTaskDialog({required this.initialValue});

  @override
  Widget build(BuildContext context) {
    String updatedTaskTitle = initialValue;

    return AlertDialog(
      title: Text('Edit Task'),
      content: TextField(
        controller: TextEditingController(text: initialValue),
        onChanged: (value) {
          updatedTaskTitle = value;
        },
        decoration: InputDecoration(hintText: 'Enter updated task title'),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (updatedTaskTitle.isNotEmpty) {
              Navigator.of(context).pop(updatedTaskTitle);
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

// void persistData() async {
//   final prefs = await SharedPreferences.getInstance();
//   final taskListJson = prefs.getString('tasks');
//   if (taskListJson != null) {
//     final taskList = json.decode(taskListJson) as List<dynamic>;

//     final taskProvider =
//         Provider.of<TaskProvider>(navigatorKey.currentContext!, listen: false);
//     final loadedTasks =
//         taskList.map((taskMap) => Task.fromJson(taskMap)).toList();
//     taskProvider.setTasks(loadedTasks);
//   }
// }
