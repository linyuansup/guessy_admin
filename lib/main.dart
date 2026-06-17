import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:scribble/scribble.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
      home: const ServerConfigPage(),
    );
  }
}

class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({super.key});

  @override
  State<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController(text: 'localhost');
  final _portController = TextEditingController(text: '5198');

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (_formKey.currentState!.validate()) {
      final host = _hostController.text.trim();
      final port = _portController.text.trim();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(host: host, port: port),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('服务器配置'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dns,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: '服务器地址',
                  hintText: '例如: 192.168.1.100',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.computer),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入服务器地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: '端口号',
                  hintText: '例如: 8080',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入端口号';
                  }
                  final port = int.tryParse(value.trim());
                  if (port == null || port < 1 || port > 65535) {
                    return '请输入有效的端口号 (1-65535)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _onConfirm,
                  child: const Text('确定'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String host;
  final String port;

  const HomePage({super.key, required this.host, required this.port});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  List<Widget> get _pages => [
    QuestionsPage(host: widget.host, port: widget.port),
    RoundsPage(host: widget.host, port: widget.port),
    PlayersPage(host: widget.host, port: widget.port),
    SettingsPage(host: widget.host, port: widget.port),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.help_outline),
            selectedIcon: Icon(Icons.help),
            label: '问题',
          ),
          NavigationDestination(
            icon: Icon(Icons.sync_outlined),
            selectedIcon: Icon(Icons.sync),
            label: '回合',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '玩家',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}

class QuestionsPage extends StatefulWidget {
  final String host;
  final String port;

  const QuestionsPage({super.key, required this.host, required this.port});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  List<dynamic> _questions = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://${widget.host}:${widget.port}/api/getProblem?page=$_currentPage&pageSize=$_pageSize',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          if (refresh || _currentPage == 1) {
            _questions = data;
          } else {
            _questions.addAll(data);
          }
          _hasMore = data.length >= _pageSize;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '加载失败: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '请求失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadQuestions(refresh: true);
  }

  void _loadMore() {
    if (!_isLoading && _hasMore) {
      _currentPage++;
      _loadQuestions();
    }
  }

  void _showAddQuestionDialog() {
    final contentController = TextEditingController();
    final hintsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加问题'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '问题内容',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: hintsController,
                decoration: const InputDecoration(
                  labelText: '提示（用逗号分隔）',
                  hintText: '提示1, 提示2, 提示3',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final content = contentController.text.trim();
              if (content.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入问题内容')));
                return;
              }

              final hints = hintsController.text
                  .split(',')
                  .map((h) => h.trim())
                  .where((h) => h.isNotEmpty)
                  .toList();

              final question = {
                'content': content,
                'hints': hints.map((h) => {'value': h}).toList(),
              };

              try {
                final response = await http.post(
                  Uri.parse(
                    'http://${widget.host}:${widget.port}/api/updateProblem',
                  ),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(question),
                );

                if (!context.mounted) return;

                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  _refresh();
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('添加成功')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('添加失败: ${response.statusCode}')),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('请求失败: $e')));
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditQuestionDialog(Map<String, dynamic> question) {
    final contentController = TextEditingController(
      text: question['content'] ?? '',
    );
    final hintsController = TextEditingController(
      text: (question['hints'] as List? ?? [])
          .map((h) => h['value'] ?? '')
          .join(', '),
    );
    bool used = question['useState'] != 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('编辑问题'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '问题内容',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: hintsController,
                  decoration: const InputDecoration(
                    labelText: '提示（用逗号分隔）',
                    hintText: '提示1, 提示2, 提示3',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('已使用'),
                  value: used,
                  onChanged: (value) {
                    setDialogState(() {
                      used = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final content = contentController.text.trim();
                if (content.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('请输入问题内容')));
                  return;
                }

                final hints = hintsController.text
                    .split(',')
                    .map((h) => h.trim())
                    .where((h) => h.isNotEmpty)
                    .toList();

                final requestBody = {
                  'content': content,
                  'hints': hints.map((h) => {'value': h}).toList(),
                  'used': used,
                };

                try {
                  final response = await http.post(
                    Uri.parse(
                      'http://${widget.host}:${widget.port}/api/updateProblem',
                    ),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(requestBody),
                  );

                  if (!context.mounted) return;

                  if (response.statusCode == 200) {
                    Navigator.pop(context);
                    _refresh();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('编辑成功')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('编辑失败: ${response.statusCode}')),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('请求失败: $e')));
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('问题'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: '刷新',
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _refresh, child: _buildBody()),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuestionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refresh, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_questions.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _questions.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _questions.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final question = _questions[index];
          final useState = question['useState'] ?? 0;
          final content = question['content'] ?? '';
          final hints = question['hints'] as List? ?? [];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(content),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditQuestionDialog(question),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: useState == 1
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          useState == 1 ? '未使用' : '已使用',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${hints.length} 个提示',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  if (hints.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: hints.map<Widget>((hint) {
                        return Chip(
                          label: Text(
                            hint['value'] ?? '',
                            style: const TextStyle(fontSize: 12),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RoundsPage extends StatefulWidget {
  final String host;
  final String port;

  const RoundsPage({super.key, required this.host, required this.port});

  @override
  State<RoundsPage> createState() => _RoundsPageState();
}

class _RoundsPageState extends State<RoundsPage> {
  List<dynamic> _rounds = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  final _queryController = TextEditingController();
  _RoundSearchType _searchType = _RoundSearchType.all;

  @override
  void initState() {
    super.initState();
    _loadRounds();
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadRounds({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final query = _queryController.text.trim();
    final useSearch = _searchType != _RoundSearchType.all && query.isNotEmpty;

    final url = useSearch
        ? _buildSearchUrl(query)
        : 'http://${widget.host}:${widget.port}/api/getRoundArchive?page=$_currentPage&pageSize=$_pageSize';

    try {
      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          if (refresh || _currentPage == 1 || useSearch) {
            _rounds = data;
          } else {
            _rounds.addAll(data);
          }
          _hasMore = !useSearch && data.length >= _pageSize;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '加载失败: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '请求失败: $e';
        _isLoading = false;
      });
    }
  }

  String _buildSearchUrl(String query) {
    final encoded = Uri.encodeComponent(query);
    if (_searchType == _RoundSearchType.question) {
      return 'http://${widget.host}:${widget.port}/api/findRoundArchiveByQuestion?question=$encoded';
    }
    return 'http://${widget.host}:${widget.port}/api/findRoundArchiveByDrawerId?drawerId=$encoded';
  }

  Future<void> _refresh() async {
    await _loadRounds(refresh: true);
  }

  void _loadMore() {
    if (_searchType != _RoundSearchType.all) return;
    if (!_isLoading && _hasMore) {
      _currentPage++;
      _loadRounds();
    }
  }

  void _onSearch() {
    if (_queryController.text.trim().isEmpty) {
      setState(() {
        _searchType = _RoundSearchType.all;
      });
    }
    _loadRounds(refresh: true);
  }

  void _onChangeSearchType(_RoundSearchType type) {
    if (_searchType == type) return;
    setState(() {
      _searchType = type;
      if (type == _RoundSearchType.all) {
        _queryController.clear();
      }
    });
    _loadRounds(refresh: true);
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    if (value is Map && value['value'] != null) {
      return value['value'].toString();
    }
    return value.toString();
  }

  String _getField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) {
        return _asString(data[key]);
      }
    }
    return '';
  }

  Widget _buildSearchBar() {
    final hintText = _searchType == _RoundSearchType.question
        ? '按问题搜索'
        : _searchType == _RoundSearchType.drawer
        ? '按画师手环 ID 搜索'
        : '查看所有对局';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('全部'),
                selected: _searchType == _RoundSearchType.all,
                onSelected: (_) => _onChangeSearchType(_RoundSearchType.all),
              ),
              ChoiceChip(
                label: const Text('按问题'),
                selected: _searchType == _RoundSearchType.question,
                onSelected: (_) =>
                    _onChangeSearchType(_RoundSearchType.question),
              ),
              ChoiceChip(
                label: const Text('按画师 ID'),
                selected: _searchType == _RoundSearchType.drawer,
                onSelected: (_) => _onChangeSearchType(_RoundSearchType.drawer),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  decoration: InputDecoration(
                    labelText: '搜索条件',
                    hintText: hintText,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _queryController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _queryController.clear();
                              _onSearch();
                            },
                          ),
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(onPressed: _onSearch, child: const Text('搜索')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_isLoading && _rounds.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_error != null && _rounds.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 180),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _refresh, child: const Text('重试')),
              ],
            ),
          ),
        ],
      );
    }

    if (_rounds.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 200),
          Center(child: Text('暂无数据')),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _rounds.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _rounds.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final raw = _rounds[index];
          final data = raw is Map
              ? Map<String, dynamic>.from(raw as Map)
              : <String, dynamic>{'data': raw};

          final questionData = data['question'] is Map
              ? Map<String, dynamic>.from(data['question'] as Map)
              : <String, dynamic>{};
          final questionContent = _asString(questionData['content']);
          final hints = questionData['hints'] as List? ?? [];
          final drawerId = _asString(data['drawerId']);
          final answers = data['answers'] as List? ?? [];
          final correctAnswers = data['correctAnswers'] as List? ?? [];
          final incorrectAnswers = data['incorrectAnswers'] as List? ?? [];
          final hasDrawing = _asString(
            data['drawingBoard'] is Map
                ? (data['drawingBoard'] as Map)['schema']
                : data['drawingBoard'],
          ).isNotEmpty;
          final roundId = _getField(data, ['roundId', 'id', 'archiveId']);
          final startTime = _getField(data, [
            'startTime',
            'startedAt',
            'startAt',
            'createdAt',
            'createTime',
          ]);
          final endTime = _getField(data, [
            'endTime',
            'endedAt',
            'endAt',
            'finishTime',
          ]);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(questionContent.isEmpty ? '未命名问题' : questionContent),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RoundDetailPage(round: data),
                  ),
                );
              },
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (drawerId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('画师手环: $drawerId'),
                  ],
                  const SizedBox(height: 4),
                  Text('提示数: ${hints.length}'),
                  const SizedBox(height: 4),
                  Text(
                    '答案: ${answers.length} | 正确: ${correctAnswers.length} | 错误: ${incorrectAnswers.length}',
                  ),
                  const SizedBox(height: 4),
                  Text(hasDrawing ? '画板: 有' : '画板: 无'),
                  if (roundId.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('对局 ID: $roundId'),
                  ],
                  if (startTime.isNotEmpty || endTime.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '时间: ${startTime.isEmpty ? '-' : startTime} ~ ${endTime.isEmpty ? '-' : endTime}',
                    ),
                  ],
                  if (hints.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: hints.map<Widget>((hint) {
                        final text = _asString(
                          hint is Map ? (hint as Map)['value'] : hint,
                        );
                        return Chip(
                          label: Text(
                            text,
                            style: const TextStyle(fontSize: 12),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回合'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: '刷新',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(onRefresh: _refresh, child: _buildList()),
          ),
        ],
      ),
    );
  }
}

enum _RoundSearchType { all, question, drawer }

class RoundDetailPage extends StatefulWidget {
  final Map<String, dynamic> round;

  const RoundDetailPage({super.key, required this.round});

  @override
  State<RoundDetailPage> createState() => _RoundDetailPageState();
}

class _RoundDetailPageState extends State<RoundDetailPage> {
  ScribbleNotifier? _notifier;
  Sketch? _sketch;

  @override
  void initState() {
    super.initState();
    _sketch = _parseSketch();
    if (_sketch != null) {
      _notifier = ScribbleNotifier(sketch: _sketch);
    }
  }

  @override
  void dispose() {
    _notifier?.dispose();
    super.dispose();
  }

  Sketch? _parseSketch() {
    try {
      final drawingBoard = widget.round['drawingBoard'];
      final schema = drawingBoard is Map
          ? drawingBoard['schema']?.toString()
          : drawingBoard?.toString();
      if (schema == null || schema.trim().isEmpty) return null;
      final decoded = jsonDecode(schema);
      if (decoded is Map<String, dynamic>) {
        return Sketch.fromJson(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    if (value is Map && value['value'] != null) {
      return value['value'].toString();
    }
    return value.toString();
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return [];
  }

  Future<void> _exportImage() async {
    if (_notifier == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有画板数据')));
      return;
    }

    try {
      final bytes = await _notifier!.renderImage(pixelRatio: 2.0);
      if (!mounted) return;
      final data = bytes.buffer.asUint8List();
      final base64 = base64Encode(data);
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导出图片'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(data),
                ),
                const SizedBox(height: 12),
                Text(
                  'Base64 长度: ${base64.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('关闭'),
            ),
            FilledButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: base64));
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('已复制 Base64')));
              },
              child: const Text('复制 Base64'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出失败: $e')));
    }
  }

  Widget _buildAnswerSection(String title, List<dynamic> answers) {
    if (answers.isEmpty) {
      return const Text('暂无');
    }

    return Column(
      children: answers.map<Widget>((item) {
        final answer = item is Map<String, dynamic>
            ? item
            : <String, dynamic>{'answer': item};
        final playerId = _asString(answer['playerId']);
        final content = _asString(answer['answer']);
        final time = _asString(answer['submittedAt']);
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(content.isEmpty ? '-' : content),
          subtitle: Text(
            '玩家: ${playerId.isEmpty ? '-' : playerId}  时间: ${time.isEmpty ? '-' : time}',
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionData = widget.round['question'] is Map
        ? Map<String, dynamic>.from(widget.round['question'] as Map)
        : <String, dynamic>{};
    final questionContent = _asString(questionData['content']);
    final hints = _asList(questionData['hints']);
    final drawerId = _asString(widget.round['drawerId']);
    final answers = _asList(widget.round['answers']);
    final correctAnswers = _asList(widget.round['correctAnswers']);
    final incorrectAnswers = _asList(widget.round['incorrectAnswers']);

    return Scaffold(
      appBar: AppBar(title: const Text('对局详情'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      questionContent.isEmpty ? '未命名问题' : questionContent,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('画师手环: ${drawerId.isEmpty ? '-' : drawerId}'),
                    const SizedBox(height: 8),
                    Text('提示数: ${hints.length}'),
                    if (hints.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: hints.map<Widget>((hint) {
                          final text = _asString(
                            hint is Map ? (hint as Map)['value'] : hint,
                          );
                          return Chip(
                            label: Text(
                              text,
                              style: const TextStyle(fontSize: 12),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '画板',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        FilledButton.icon(
                          onPressed: _exportImage,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('导出图片'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _notifier == null
                            ? const Center(child: Text('暂无画板数据'))
                            : IgnorePointer(
                                child: Scribble(
                                  notifier: _notifier!,
                                  drawPen: false,
                                  drawEraser: false,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '答案列表 (${answers.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildAnswerSection('答案', answers),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '正确答案 (${correctAnswers.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildAnswerSection('正确', correctAnswers),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '错误答案 (${incorrectAnswers.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildAnswerSection('错误', incorrectAnswers),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayersPage extends StatefulWidget {
  final String host;
  final String port;

  const PlayersPage({super.key, required this.host, required this.port});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  List<dynamic> _players = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'http://${widget.host}:${widget.port}/api/getPlayers?page=$_currentPage&pageSize=$_pageSize',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          if (refresh || _currentPage == 1) {
            _players = data;
          } else {
            _players.addAll(data);
          }
          _hasMore = data.length >= _pageSize;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '加载失败: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '请求失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadPlayers(refresh: true);
  }

  void _loadMore() {
    if (!_isLoading && _hasMore) {
      _currentPage++;
      _loadPlayers();
    }
  }

  Future<void> _deletePlayer(String braceletId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除手环 $braceletId 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.get(
        Uri.parse(
          'http://${widget.host}:${widget.port}/api/deletePlayer?braceletId=$braceletId',
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _refresh();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('删除成功')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('删除失败: ${response.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请求失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('玩家'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: '刷新',
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: _refresh, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _players.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _refresh, child: const Text('重试')),
          ],
        ),
      );
    }

    if (_players.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.extentAfter < 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _players.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _players.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final player = _players[index];
          final braceletId = player['braceletId']?['value'] ?? '';
          final deviceId = player['deviceId']?['value'] ?? '';
          final score = player['score']?['value'] ?? 0;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  (index + 1).toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text('手环: $braceletId'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('设备: $deviceId'),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '积分: $score',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _deletePlayer(braceletId),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  final String host;
  final String port;

  const SettingsPage({super.key, required this.host, required this.port});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _displayTopCountController = TextEditingController(text: '5');
  final _durationController = TextEditingController(text: '60');
  final _selectQuestionCountController = TextEditingController(text: '10');

  List<Map<String, int>> _rankRewards = [
    {'rank': 1, 'playerScore': 10, 'drawerScore': 5},
    {'rank': 2, 'playerScore': 8, 'drawerScore': 4},
    {'rank': 3, 'playerScore': 5, 'drawerScore': 3},
  ];
  bool _isLoading = false;

  @override
  void dispose() {
    _displayTopCountController.dispose();
    _durationController.dispose();
    _selectQuestionCountController.dispose();
    super.dispose();
  }

  Future<void> _stop() async {
    setState(() => _isLoading = true);

    try {
      await http.get(
        Uri.parse('http://${widget.host}:${widget.port}/api/stop'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已发送停止请求')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请求失败: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addRankReward() {
    final lastRank = _rankRewards.isEmpty ? 0 : _rankRewards.last['rank']!;
    setState(() {
      _rankRewards.add({
        'rank': lastRank + 1,
        'playerScore': 5,
        'drawerScore': 3,
      });
    });
  }

  void _removeRankReward(int index) {
    setState(() {
      _rankRewards.removeAt(index);
    });
  }

  void _updateRankReward(int index, String field, int value) {
    setState(() {
      _rankRewards[index][field] = value;
    });
  }

  Future<void> _saveConfig() async {
    final displayTopCount = int.tryParse(_displayTopCountController.text);
    final duration = int.tryParse(_durationController.text);
    final selectQuestionCount = int.tryParse(
      _selectQuestionCountController.text,
    );

    if (displayTopCount == null || displayTopCount < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的展示前几名')));
      return;
    }

    if (duration == null || duration < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的游戏时间')));
      return;
    }

    if (selectQuestionCount == null || selectQuestionCount < 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入有效的题目数量')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://${widget.host}:${widget.port}/api/config'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'displayTopCount': displayTopCount,
          'duration': duration,
          'selectQuestionCount': selectQuestionCount,
          'rankRewards': _rankRewards
              .map(
                (reward) => {
                  'rank': reward['rank'],
                  'playerScore': reward['playerScore'],
                  'drawerScore': reward['drawerScore'],
                },
              )
              .toList(),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存成功')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存失败: ${response.statusCode}')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('请求失败: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '游戏配置',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _displayTopCountController,
                      decoration: const InputDecoration(
                        labelText: '展示前几名',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.leaderboard),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _durationController,
                      decoration: const InputDecoration(
                        labelText: '游戏时间（秒）',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.timer),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _selectQuestionCountController,
                      decoration: const InputDecoration(
                        labelText: '可选题目数',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.quiz),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isLoading ? null : _saveConfig,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('保存配置'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '排名奖励规则',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _addRankReward,
                          tooltip: '添加奖励规则',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._rankRewards.asMap().entries.map((entry) {
                      final index = entry.key;
                      final reward = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: reward['rank'].toString(),
                                decoration: const InputDecoration(
                                  labelText: '排名',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final rank = int.tryParse(value);
                                  if (rank != null) {
                                    _updateRankReward(index, 'rank', rank);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: reward['playerScore'].toString(),
                                decoration: const InputDecoration(
                                  labelText: '玩家得分',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final score = int.tryParse(value);
                                  if (score != null) {
                                    _updateRankReward(
                                      index,
                                      'playerScore',
                                      score,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue: reward['drawerScore'].toString(),
                                decoration: const InputDecoration(
                                  labelText: '画师得分',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final score = int.tryParse(value);
                                  if (score != null) {
                                    _updateRankReward(
                                      index,
                                      'drawerScore',
                                      score,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeRankReward(index),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _stop,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('强制结束游戏'),
            ),
          ],
        ),
      ),
    );
  }
}
