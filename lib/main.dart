import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo App',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const TodoPage(),
    );
  }
}

class TodoItem {
  final String id;
  final String text;
  bool completed;

  TodoItem({
    required this.id,
    required this.text,
    this.completed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'completed': completed,
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      text: json['text'],
      completed: json['completed'],
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _controller =
      TextEditingController();

  List<TodoItem> _todos = [];

  @override
  void initState() {
    super.initState();
    _initializeTodos();
  }

  // 初期化
  Future<void> _initializeTodos() async {
    await _checkDateReset();
    await _loadTodos();
  }

  // 日付変更チェック
  Future<void> _checkDateReset() async {
    final prefs =
        await SharedPreferences.getInstance();

    final today = DateTime.now();

    final currentDate =
        "${today.year}-${today.month}-${today.day}";

    final savedDate =
        prefs.getString('last_open_date');

    // 日付変わってたら削除
    if (savedDate != null &&
        savedDate != currentDate) {
      await prefs.remove('todos');
    }

    await prefs.setString(
      'last_open_date',
      currentDate,
    );
  }

  // ToDo追加
  void _addTodo() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
      // 新規タスクを一番上へ
      _todos.insert(
        0,
        TodoItem(
          id: DateTime.now()
              .microsecondsSinceEpoch
              .toString(),
          text: text,
        ),
      );
    });

    _controller.clear();

    _saveTodos();
  }

  // 完了
  void _completeTodo(String id) {
    setState(() {
      final index =
          _todos.indexWhere((t) => t.id == id);

      if (index == -1) return;

      final todo = _todos[index];

      // 既に完了済みなら何もしない
      if (todo.completed) return;

      todo.completed = true;

      // 一旦削除
      _todos.removeAt(index);

      // 一番下へ移動
      _todos.add(todo);
    });

    _saveTodos();
  }

  // 削除
  void _deleteTodo(String id) {
    setState(() {
      _todos.removeWhere(
        (todo) => todo.id == id,
      );
    });

    _saveTodos();
  }

  // 保存
  Future<void> _saveTodos() async {
    final prefs =
        await SharedPreferences.getInstance();

    final jsonList = _todos
        .map((todo) => jsonEncode(todo.toJson()))
        .toList();

    await prefs.setStringList(
      'todos',
      jsonList,
    );
  }

  // 読み込み
  Future<void> _loadTodos() async {
    final prefs =
        await SharedPreferences.getInstance();

    final jsonList =
        prefs.getStringList('todos');

    if (jsonList == null) return;

    setState(() {
      _todos = jsonList
          .map(
            (jsonString) => TodoItem.fromJson(
              jsonDecode(jsonString),
            ),
          )
          .toList();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDo App'),
        centerTitle: true,
        backgroundColor: const Color(0xFF111827),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ToDo一覧
              Expanded(
                child: ListView.separated(
                  itemCount: _todos.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final todo = _todos[index];

                    return Dismissible(
                      key: ValueKey(todo.id),

                      // 完了済みはスワイプ不可
                      direction: todo.completed
                          ? DismissDirection.none
                          : DismissDirection.horizontal,

                      // スワイプで完了
                      confirmDismiss: (_) async {
                        _completeTodo(todo.id);
                        return false;
                      },

                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                        alignment:
                            Alignment.centerLeft,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      secondaryBackground:
                          Container(
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                        ),
                        alignment:
                            Alignment.centerRight,
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),

                      child: GestureDetector(
                        // 完了済みをダブルタップ削除
                        onDoubleTap: () {
                          if (todo.completed) {
                            _deleteTodo(todo.id);
                          }
                        },

                        child: AnimatedContainer(
                          duration: const Duration(
                            milliseconds: 250,
                          ),
                          width: double.infinity,
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: todo.completed
                                ? const Color(
                                    0xFF14532D)
                                : const Color(
                                    0xFF1E293B),
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                            border: Border.all(
                              color: todo.completed
                                  ? Colors.green
                                  : const Color(
                                      0xFF334155,
                                    ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  todo.text,
                                  style: TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize: 18,
                                    decoration:
                                        todo.completed
                                            ? TextDecoration
                                                .lineThrough
                                            : null,
                                  ),
                                ),
                              ),

                              // 完了マーク
                              if (todo.completed)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 入力欄
              TextField(
                controller: _controller,
                onSubmitted: (_) => _addTodo(),
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'ToDoを入力',
                  hintStyle: const TextStyle(
                    color: Colors.white54,
                  ),
                  filled: true,
                  fillColor:
                      const Color(0xFF1E293B),
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(20),
                    borderSide:
                        BorderSide.none,
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(20),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFF334155),
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(20),
                    borderSide:
                        const BorderSide(
                      color:
                          Color(0xFF60A5FA),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 追加ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addTodo,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                            0xFF2563EB),
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 18,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                  ),
                  child: const Text(
                    'ToDo追加',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}