import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'todo.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Todo> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTasks = prefs.getString('tasks');

    if (savedTasks != null) {
      final List<dynamic> decoded = jsonDecode(savedTasks);
      _tasks = decoded.map((json) => Todo.fromJson(json)).toList();
      setState(() {
        _isLoading = false;
      });
    } else {
      await fetchTodosFromApi();
    }
  }

  Future<void> saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> tasksJson =
    _tasks.map((task) => task.toJson()).toList();
    await prefs.setString('tasks', jsonEncode(tasksJson));
  }

  Future<void> fetchTodosFromApi() async {
    try {
      final response = await http.get(
        Uri.parse('https://jsonplaceholder.typicode.com/todos'),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'FlutterApp',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        final List<Todo> loadedTasks =
        jsonData.take(10).map((json) => Todo.fromJson(json)).toList();

        setState(() {
          _tasks = loadedTasks;
          _isLoading = false;
        });

        await saveTasks();
      } else {
        throw Exception('Failed to load todos');
      }
    } catch (error) {
      print('API fetch error: $error');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load tasks')),
      );
    }
  }

  void _toggleComplete(int index) {
    setState(() {
      _tasks[index].completed = !_tasks[index].completed;
    });
    saveTasks();
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text("Home Screen", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? const Center(child: Text("No tasks found."))
          : ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Checkbox(
                value: task.completed,
                onChanged: (_) => _toggleComplete(index),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: task.completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteTask(index),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          );

          if (result != null && result.toString().trim().isNotEmpty) {
            setState(() {
              _tasks.add(Todo(
                id: _tasks.length + 1,
                title: result,
                completed: false,
              ));
            });
            await saveTasks();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
