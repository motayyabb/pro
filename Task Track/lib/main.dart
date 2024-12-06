import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'task_database.dart';
import 'task.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool isDarkMode = false;
  bool areNotificationsEnabled = true;

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  // Request notification permission
  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.notification.request();
    if (status.isGranted) {
      print("Notification permission granted");
    } else {
      print("Notification permission denied");
    }
  }

  void _initializeNotifications() async {
    // Request permissions before initializing
    await _requestPermissions();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('app_icon'); // Ensure app_icon exists in drawable folder
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);


    bool? initialized = await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    if (initialized == null || !initialized) {
      print("Notification initialization failed.");
    } else {
      print("Notification initialized successfully.");
    }
  }

  Future<void> _showNotification(String title, String body) async {
    if (!areNotificationsEnabled) return;

    AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      channelDescription: 'Your channel description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      styleInformation: BigTextStyleInformation(
        body,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
      ),
      color: Colors.blueAccent,
      largeIcon: DrawableResourceAndroidBitmap('app_icon'),  // Correct reference to the drawable icon
      icon: 'app_icon',  // Set the small icon in the notification (also from the drawable folder)
    );

    NotificationDetails generalNotificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      generalNotificationDetails,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _screens = [
      HomeScreen(notificationCallback: _showNotification),
      AddTaskScreen(notificationCallback: _showNotification),
      CompletedTasksScreen(),
      RepeatedTasksScreen(notificationCallback: _showNotification),
      SettingsScreen(
        onDarkModeToggle: (bool value) {
          setState(() {
            isDarkMode = value;
          });
        },
        onNotificationToggle: (bool value) {
          setState(() {
            areNotificationsEnabled = value;
          });
        },
        isDarkMode: isDarkMode,
        areNotificationsEnabled: areNotificationsEnabled,
      ),
    ];

    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Task Management',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
          backgroundColor: Colors.blueAccent,
          elevation: 5.0,
          actions: [
            IconButton(
              icon: Icon(Icons.pie_chart, size: 30.0),  // Choose an appropriate icon
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProgressReport()), // Navigate to ProgressReport screen
                );
              },
            ),
          ],
        ),
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.blue,  // Blue background
          selectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white  // White text in dark mode
              : Colors.black, // Black text in light mode
          unselectedItemColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.white70  // Lighter white in dark mode
              : Colors.black54, // Lighter black in light mode
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Task'),
            BottomNavigationBarItem(icon: Icon(Icons.check), label: 'Completed'),
            BottomNavigationBarItem(icon: Icon(Icons.repeat), label: 'Repeated'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
//tracking screen
class ProgressReport extends StatefulWidget {
  @override
  _ProgressReportState createState() => _ProgressReportState();
}

class _ProgressReportState extends State<ProgressReport> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _updateProgress();
  }

  // Method to update the progress from the database
  Future<void> _updateProgress() async {
    final progress = await TaskDatabaseHelper.instance.getCompletionProgress();
    setState(() {
      _progress = progress / 100; // Convert percentage to 0.0 - 1.0 scale
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Progress Report'),
        actions: [
          IconButton(
            icon: Icon(Icons.pie_chart, size: 30.0),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProgressReport()),  // Navigate to ProgressReport
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Completion Progress: ${(_progress * 100).toStringAsFixed(2)}%',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              color: Colors.green,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateProgress,
              child: Text('Refresh Progress'),
            ),
          ],
        ),
      ),
    );
  }
}

// CompletedTasksScreen - Displays all completed tasks
class CompletedTasksScreen extends StatefulWidget {
  @override
  _CompletedTasksScreenState createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Completed Tasks')),
      body: FutureBuilder<List<Task>>(
        future: TaskDatabaseHelper.instance.getTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No completed tasks found.'));
          }

          var tasks = snapshot.data!.where((task) => task.isCompleted).toList();
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                elevation: 8,
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                child: ListTile(
                  title: Text(task.name, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(task.description),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// RepeatedTasksScreen - Displays tasks that have been inserted with the same name
class RepeatedTasksScreen extends StatefulWidget {
  final Future<void> Function(String, String) notificationCallback;

  RepeatedTasksScreen({required this.notificationCallback});

  @override
  _RepeatedTasksScreenState createState() => _RepeatedTasksScreenState();
}

class _RepeatedTasksScreenState extends State<RepeatedTasksScreen> {
  Future<void> _generateAndPrintPDF(List<Task> tasks) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Repeated Tasks List", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            ...tasks.map((task) {
              return pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  "${task.name}: ${task.description}",
                  style: pw.TextStyle(fontSize: 18),
                ),
              );
            }).toList(),
          ],
        );
      },
    ));

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Repeated Tasks',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 5.0,
        actions: [
          IconButton(
            icon: Icon(Icons.print, size: 30.0),
            onPressed: () async {
              // Fetch the repeated tasks currently displayed on the screen
              var tasks = await TaskDatabaseHelper.instance.getRepeatedTasks();
              // Generate and print the PDF for the repeated tasks
              _generateAndPrintPDF(tasks);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: TaskDatabaseHelper.instance.getRepeatedTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No repeated tasks found.'));
          }

          // Filter out completed tasks from the list to display only incomplete tasks
          var tasks = snapshot.data!.where((task) => !task.isCompleted).toList();

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                elevation: 8,
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                child: ListTile(
                  title: Text(
                    task.name,
                    style: TextStyle(
                      decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(task.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditTaskScreen(task: task),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await TaskDatabaseHelper.instance.deleteTask(task.id!);
                          setState(() {});
                          widget.notificationCallback("Task Deleted", "${task.name} has been deleted.");
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () async {
                          task.isCompleted = true;
                          await TaskDatabaseHelper.instance.updateTask(task);
                          setState(() {});
                          widget.notificationCallback("Task Completed", "${task.name} is marked as completed.");
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// HomeScreen - Displays all tasks
class HomeScreen extends StatefulWidget {
  final Future<void> Function(String, String) notificationCallback;

  HomeScreen({required this.notificationCallback});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _generateAndPrintPDF(List<Task> tasks) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Task List", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            ...tasks.map((task) {
              return pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 10),
                child: pw.Text(
                  "${task.name}: ${task.description}",
                  style: pw.TextStyle(fontSize: 18),
                ),
              );
            }).toList(),
          ],
        );
      },
    ));

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home screen',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 5.0,
        actions: [
          IconButton(
            icon: Icon(Icons.print, size: 30.0),
            onPressed: () async {
              // Fetch the tasks currently displayed on the screen
              var tasks = await TaskDatabaseHelper.instance.getTasks();
              // Filter tasks based on the current screen's state, e.g., only display incomplete tasks
              var displayedTasks = tasks.where((task) => !task.isCompleted).toList();
              // Generate and print the PDF for the displayed tasks
              _generateAndPrintPDF(displayedTasks);
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: TaskDatabaseHelper.instance.getTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tasks found.'));
          }

          // Filter out completed tasks from the list to display only incomplete tasks
          var tasks = snapshot.data!.where((task) => !task.isCompleted).toList();

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Card(
                elevation: 8,
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                child: ListTile(
                  title: Text(
                    task.name,
                    style: TextStyle(
                      decoration: task.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(task.description),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditTaskScreen(task: task),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await TaskDatabaseHelper.instance.deleteTask(task.id!);
                          setState(() {});
                          widget.notificationCallback("Task Deleted", "${task.name} has been deleted.");
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.check),
                        onPressed: () async {
                          task.isCompleted = true;
                          await TaskDatabaseHelper.instance.updateTask(task);
                          setState(() {});
                          widget.notificationCallback("Task Completed", "${task.name} is marked as completed.");
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


// AddTaskScreen - Add a new task

class AddTaskScreen extends StatefulWidget {
  final Future<void> Function(String, String) notificationCallback;

  AddTaskScreen({required this.notificationCallback});

  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _isRepeat = false; // Track repeat status
  List<String> _selectedDays = []; // Store selected days

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  void _addTask() async {
    if (_formKey.currentState!.validate()) {
      String taskName = _nameController.text;

      // Check if task already exists
      var existingTasks = await TaskDatabaseHelper.instance.getTasks();
      bool taskExists = existingTasks.any((task) => task.name == taskName);

      if (taskExists) {
        widget.notificationCallback("Task Exists", "The task '${taskName}' already exists.");
        return;
      }

      // Create new task object with repeat option
      Task task = Task(
        name: _nameController.text,
        description: _descriptionController.text,
        repeat: _isRepeat,
        repeatDays: _selectedDays,  // Assuming this is the selected repeat days
      );


      // Insert task into the database
      await TaskDatabaseHelper.instance.insertTask(task);

      // Trigger the notification after the task is added
      widget.notificationCallback("New Task Added", "The task '$taskName' has been added.");

      // Navigate back after the task is added
      Navigator.pop(context);

      // Optionally, show a Snackbar to confirm task addition
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Task added')));
    }
  }

  // Show a dialog to select repeat days
  void _selectRepeatDays() async {
    final List<String> allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final List<String> selected = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(allDays: allDays, initialSelected: _selectedDays);
      },
    ) ?? [];

    setState(() {
      _selectedDays = selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Task Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Task Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a task description';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: Text('Repeat task'),
                value: _isRepeat,
                onChanged: (value) {
                  setState(() {
                    _isRepeat = value;
                  });
                },
              ),
              if (_isRepeat)
                ElevatedButton(
                  onPressed: _selectRepeatDays,
                  child: Text('Select Days'),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                ),
                child: Text(
                  'Add Task',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MultiSelectDialog extends StatelessWidget {
  final List<String> allDays;
  final List<String> initialSelected;

  MultiSelectDialog({required this.allDays, required this.initialSelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Select Repeat Days'),
      content: SingleChildScrollView(
        child: Column(
          children: allDays.map((day) {
            return CheckboxListTile(
              title: Text(day),
              value: initialSelected.contains(day),
              onChanged: (bool? value) {
                if (value == true) {
                  initialSelected.add(day);
                } else {
                  initialSelected.remove(day);
                }
                (context as Element).markNeedsBuild();
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, initialSelected);
          },
          child: Text('Done'),
        ),
      ],
    );
  }
}

// EditTaskScreen - Edit an existing task
class EditTaskScreen extends StatefulWidget {
  final Task task;

  EditTaskScreen({required this.task});

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task.name);
    _descriptionController = TextEditingController(text: widget.task.description);
  }

  void _saveTask() async {
    Task updatedTask = Task(
      id: widget.task.id,
      name: _nameController.text,
      description: _descriptionController.text,
      isCompleted: widget.task.isCompleted,
    );

    await TaskDatabaseHelper.instance.updateTask(updatedTask);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Task Name'),
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Task Description'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTask,
              child: Text('Save Task'),
            ),
          ],
        ),
      ),
    );
  }
}

// SettingsScreen - Toggle settings for dark mode and notifications
class SettingsScreen extends StatelessWidget {
  final Function(bool) onDarkModeToggle;
  final Function(bool) onNotificationToggle;
  final bool isDarkMode;
  final bool areNotificationsEnabled;

  SettingsScreen({
    required this.onDarkModeToggle,
    required this.onNotificationToggle,
    required this.isDarkMode,
    required this.areNotificationsEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: Text('Dark Mode'),
              value: isDarkMode,
              onChanged: onDarkModeToggle,
            ),
            SwitchListTile(
              title: Text('Enable Notifications'),
              value: areNotificationsEnabled,
              onChanged: onNotificationToggle,
            ),
          ],
        ),
      ),
    );
  }
}
