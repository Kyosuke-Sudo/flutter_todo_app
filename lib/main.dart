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
  String text;
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

  factory TodoItem.fromJson(
    Map<String, dynamic> json,
  ) {
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

  // 日付変更時全削除
  Future<void> _checkDateReset() async {
    final prefs =
        await SharedPreferences.getInstance();

    final now = DateTime.now();

    final today =
        "${now.year}-${now.month}-${now.day}";

    final savedDate =
        prefs.getString('last_open_date');

    if (savedDate != null &&
        savedDate != today) {
      await prefs.remove('todos');
    }

    await prefs.setString(
      'last_open_date',
      today,
    );
  }

  // ToDo追加
  void _addTodo() {
    final text = _controller.text.trim();

    if (text.isEmpty) return;

    setState(() {
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

      if (todo.completed) return;

      todo.completed = true;

      _todos.removeAt(index);

      // 完了は下へ
      _todos.add(todo);
    });

    _saveTodos();
  }

  // 元に戻す
  void _restoreTodo(String id) {
    setState(() {
      final index =
          _todos.indexWhere((t) => t.id == id);

      if (index == -1) return;

      final todo = _todos[index];

      todo.completed = false;

      _todos.removeAt(index);

      // 未完了は上へ
      _todos.insert(0, todo);
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

  // 編集
  Future<void> _editTodo(TodoItem todo) async {
    final controller =
        TextEditingController(text: todo.text);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'タスク編集',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: TextField(
            controller: controller,
            style: const TextStyle(
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: 'タスク名',
              hintStyle: const TextStyle(
                color: Colors.white54,
              ),
              filled: true,
              fillColor:
                  const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'キャンセル',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final newText =
                    controller.text.trim();

                if (newText.isEmpty) return;

                setState(() {
                  todo.text = newText;
                });

                _saveTodos();

                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // 削除確認
  Future<void> _showDeleteDialog(
    TodoItem todo,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor:
              const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            '削除確認',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          content: Text(
            '「${todo.text}」を削除しますか？',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text('いいえ'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text('はい'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _deleteTodo(todo.id);
    }
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

  Widget _mainButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    );
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
        backgroundColor:
            const Color(0xFF111827),
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
                  separatorBuilder:
                      (_, __) =>
                          const SizedBox(
                    height: 12,
                  ),
                  itemBuilder:
                      (context, index) {
                    final todo =
                        _todos[index];
                    return Dismissible(
                      key: ValueKey(todo.id),

                      direction:
                          DismissDirection.horizontal,

                      confirmDismiss:
                          (direction) async {
                        // =====================
                        // 未完了タスク
                        // =====================

                        if (!todo.completed) {
                          _completeTodo(todo.id);
                        }

                        // =====================
                        // 完了済みタスク
                        // =====================

                        else {
                          // 右スワイプ → 削除
                          if (direction ==
                              DismissDirection
                                  .startToEnd) {
                            _deleteTodo(todo.id);
                          }

                          // 左スワイプ → 戻す
                          else {
                            _restoreTodo(todo.id);
                          }
                        }

                        return false;
                      },

                      // =====================
                      // 左→右背景
                      // =====================

                      background: todo.completed
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
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
                                Icons.delete,
                                color: Colors.white,
                                size: 30,
                              ),
                            )

                          // 未完了時は背景なし
                          : null,

                      // =====================
                      // 右→左背景
                      // =====================

                      secondaryBackground:
                          todo.completed
                              ? Container(
                                  decoration:
                                      BoxDecoration(
                                    color: Colors.orange,
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
                                    Icons.undo,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                )

                              // 未完了時は背景なし
                              : null,

                      child: GestureDetector(
                        onDoubleTap: () {
                          _editTodo(todo);
                        },

                        onLongPress: () {
                          _showDeleteDialog(todo);
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
                                ? const Color(0xFF14532D)
                                : const Color(0xFF1E293B),
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
                                    color: Colors.white,
                                    fontSize: 18,
                                    decoration:
                                        todo.completed
                                            ? TextDecoration
                                                .lineThrough
                                            : null,
                                  ),
                                ),
                              ),

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

              const SizedBox(
                height: 16,
              ),

              // 入力欄
              TextField(
                controller: _controller,
                onSubmitted:
                    (_) => _addTodo(),
                style: const TextStyle(
                  color: Colors.white,
                ),
                decoration:
                    InputDecoration(
                  hintText: 'ToDoを入力',
                  hintStyle:
                      const TextStyle(
                    color:
                        Colors.white54,
                  ),
                  filled: true,
                  fillColor:
                      const Color(
                    0xFF1E293B,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                    borderSide:
                        BorderSide.none,
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                    borderSide:
                        const BorderSide(
                      color: Color(
                        0xFF334155,
                      ),
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),
                    borderSide:
                        const BorderSide(
                      color: Color(
                        0xFF60A5FA,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // ToDo追加ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _addTodo,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF2563EB,
                    ),
                    foregroundColor:
                        Colors.white,
                    padding:
                        const EdgeInsets.symmetric(
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
                          FontWeight
                              .bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // メニューボタン
              _mainButton(
                text: 'メニュー',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              const MenuPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================
// メニュー画面
// =========================

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  Widget _menuButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFF1E293B),
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(
            vertical: 18,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('メニュー'),
        centerTitle: true,
        backgroundColor:
            const Color(0xFF111827),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _menuButton(
              text: '使い方',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) =>
                            const UsagePage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            _menuButton(
              text: 'フィードバック',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) =>
                            const FeedbackPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// 使い方画面
// =========================

class UsagePage extends StatelessWidget {
  const UsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使い方'),
        centerTitle: true,
        backgroundColor:
            const Color(0xFF111827),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            '【使い方】\n\n'
            '・入力欄からタスク追加\n\n'
            '・未完了タスクを左右スワイプで完了\n\n'
            '・完了済みタスクを左スワイプで未完了へ戻す\n\n'
            '・完了済みタスクを右スワイプで削除\n\n'
            '・ダブルタップで編集\n\n'
            '・長押しで削除確認\n\n'
            '・日付変更で全タスク削除',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}

// =========================
// フィードバック画面
// =========================

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() =>
      _FeedbackPageState();
}

class _FeedbackPageState
    extends State<FeedbackPage> {
  final TextEditingController
      _feedbackController =
      TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('フィードバック'),
        centerTitle: true,
        backgroundColor:
            const Color(0xFF111827),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller:
                  _feedbackController,
              maxLines: 8,
              style: const TextStyle(
                color: Colors.white,
              ),
              decoration:
                  InputDecoration(
                hintText:
                    '要望・感想などを入力',
                hintStyle:
                    const TextStyle(
                  color:
                      Colors.white54,
                ),
                filled: true,
                fillColor:
                    const Color(
                  0xFF1E293B,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '送信ありがとうございました',
                      ),
                    ),
                  );

                  _feedbackController
                      .clear();
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF2563EB,
                  ),
                  foregroundColor:
                      Colors.white,
                  padding:
                      const EdgeInsets.symmetric(
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
                  '送信',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}