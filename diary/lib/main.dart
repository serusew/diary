import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeDateFormatting('ru', null);
  await initializeDateFormatting('en', null);
  
  try {
    await DesktopWindow.setWindowSize(const Size(500, 900));
    await DesktopWindow.setMinWindowSize(const Size(500, 900));
    await DesktopWindow.setMaxWindowSize(const Size(500, 900));
  } catch (e) {
    // Игнорируем на мобильных платформах
  }

  runApp(const DiaryApp());
}

// --- СИСТЕМА ТЕМ ---
enum AppTheme { dark, light, pink }
enum AppLanguage { ru, en }

class ThemeConfig {
  final Color backgroundColor;
  final Color cardColor;
  final Color accentColor;
  final Color textColor;
  final String bgImageAsset;

  ThemeConfig({
    required this.backgroundColor,
    required this.cardColor,
    required this.accentColor,
    required this.textColor,
    required this.bgImageAsset,
  });

  static final darkConfig = ThemeConfig(
    backgroundColor: const Color(0xFF060B19), 
    cardColor: const Color(0xFF0F1B35),
    accentColor: const Color(0xFFFFA000), 
    textColor: const Color(0xFFE3EFFC),
    bgImageAsset: 'assets/images/синий.jpg',
  );

  static final lightConfig = ThemeConfig(
    backgroundColor: const Color(0xFF1D261C), 
    cardColor: const Color(0xFF2E3B2C),
    accentColor: const Color(0xFFD4AF37), 
    textColor: const Color(0xFFF1F8F0),
    bgImageAsset: 'assets/images/зеленый.jpg',
  );

  static final pinkConfig = ThemeConfig(
    backgroundColor: const Color(0xFF5A1827), 
    cardColor: const Color(0xFF8C263E),
    accentColor: const Color(0xFFFFB7C5), 
    textColor: const Color(0xFFFFF0F2),
    bgImageAsset: 'assets/images/розовый.jpg',
  );
}

// --- МОДЕЛИ ДАННЫХ ---
class PlacedSticker {
  final String id;
  final String emoji;
  Offset position;

  PlacedSticker({
    required this.id,
    required this.emoji,
    required this.position,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'emoji': emoji,
    'dx': position.dx,
    'dy': position.dy,
  };

  factory PlacedSticker.fromJson(Map<String, dynamic> json) => PlacedSticker(
    id: json['id'],
    emoji: json['emoji'],
    position: Offset(json['dx'], json['dy']),
  );
}

class BlockContent {
  final String type; 
  String value;      

  BlockContent({required this.type, required this.value});

  Map<String, dynamic> toJson() => {'type': type, 'value': value};
  factory BlockContent.fromJson(Map<String, dynamic> json) => BlockContent(type: json['type'], value: json['value']);
}

class DiaryEntry {
  String id;
  String title;
  List<BlockContent> blocks; 
  DateTime date;
  String moodEmoji;
  List<PlacedSticker> stickers; 

  DiaryEntry({
    required this.id,
    required this.title,
    required this.blocks,
    required this.date,
    this.moodEmoji = '😊',
    List<PlacedSticker>? stickers,
  }) : stickers = stickers ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'blocks': blocks.map((b) => b.toJson()).toList(),
    'date': date.toIso8601String(),
    'moodEmoji': moodEmoji,
    'stickers': stickers.map((s) => s.toJson()).toList(),
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    var blockList = (json['blocks'] as List? ?? []);
    var stickerList = (json['stickers'] as List? ?? []);
    
    return DiaryEntry(
      id: json['id'],
      title: json['title'],
      blocks: blockList.map((b) => BlockContent.fromJson(b)).toList(),
      date: DateTime.parse(json['date']),
      moodEmoji: json['moodEmoji'] ?? '😊',
      stickers: stickerList.map((s) => PlacedSticker.fromJson(s)).toList(),
    );
  }
}

// --- ГЛАВНОЕ ПРИЛОЖЕНИЕ ---
class DiaryApp extends StatefulWidget {
  const DiaryApp({super.key});

  @override
  State<DiaryApp> createState() => _DiaryAppState();
}

class _DiaryAppState extends State<DiaryApp> {
  AppTheme _currentTheme = AppTheme.dark;
  AppLanguage _currentLang = AppLanguage.ru;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = AppTheme.values[prefs.getInt('app_theme') ?? 0];
      _currentLang = AppLanguage.values[prefs.getInt('app_lang') ?? 0];
      _isLoading = false;
    });
  }

  Future<void> _updateTheme(AppTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _currentTheme = theme);
    await prefs.setInt('app_theme', theme.index);
  }

  Future<void> _updateLang(AppLanguage lang) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _currentLang = lang);
    await prefs.setInt('app_lang', lang.index);
  }

  ThemeConfig get currentConfig {
    switch (_currentTheme) {
      case AppTheme.light: return ThemeConfig.lightConfig;
      case AppTheme.pink: return ThemeConfig.pinkConfig;
      case AppTheme.dark: return ThemeConfig.darkConfig;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    final cfg = currentConfig;
    return MaterialApp(
      title: 'My Diary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: cfg.backgroundColor,
        cardColor: cfg.cardColor,
        colorScheme: ColorScheme.dark(primary: cfg.accentColor, surface: cfg.cardColor),
        textTheme: ThemeData.dark().textTheme.apply(bodyColor: cfg.textColor, displayColor: cfg.textColor),
      ),
      home: DiaryHomePage(
        config: cfg,
        currentTheme: _currentTheme,
        currentLang: _currentLang,
        onThemeChanged: _updateTheme,
        onLangChanged: _updateLang,
      ),
    );
  }
}

// --- ГЛАВНЫЙ ЭКРАН ---
class DiaryHomePage extends StatefulWidget {
  final ThemeConfig config;
  final AppTheme currentTheme;
  final AppLanguage currentLang;
  final ValueChanged<AppTheme> onThemeChanged;
  final ValueChanged<AppLanguage> onLangChanged;

  const DiaryHomePage({
    super.key, 
    required this.config, 
    required this.currentTheme, 
    required this.currentLang, 
    required this.onThemeChanged, 
    required this.onLangChanged
  });

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  final List<DiaryEntry> _allEntries = []; 
  List<DiaryEntry> _filteredEntries = [];
  bool _isSearching = false;
  double _scrollOffset = 0.0; // Отслеживание прокрутки списка заметок
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEntriesFromStorage();
    _searchController.addListener(_runSearch);
  }

  Future<void> _loadEntriesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? cachedData = prefs.getString('diary_entries');
    if (cachedData != null) {
      final List<dynamic> decoded = jsonDecode(cachedData);
      setState(() {
        _allEntries.clear();
        _allEntries.addAll(decoded.map((item) => DiaryEntry.fromJson(item)).toList());
        _runSearch();
      });
    }
  }

  Future<void> _saveEntriesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_allEntries.map((e) => e.toJson()).toList());
    await prefs.setString('diary_entries', encoded);
  }

  void _runSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEntries = query.isEmpty 
          ? _allEntries 
          : _allEntries.where((e) => e.title.toLowerCase().contains(query) || e.blocks.any((b) => b.type == 'text' && b.value.toLowerCase().contains(query))).toList();
    });
  }

  void _saveOrUpdateEntry(DiaryEntry entry) {
    setState(() {
      final index = _allEntries.indexWhere((e) => e.id == entry.id);
      if (index >= 0) {
        _allEntries[index] = entry; 
      } else {
        _allEntries.insert(0, entry); 
      }
      _runSearch();
    });
    _saveEntriesToStorage();
  }

  String _t(String ru, String en) => widget.currentLang == AppLanguage.ru ? ru : en;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Positioned(
            top: 0, left: 0, right: 0,
            height: MediaQuery.of(context).size.height * 0.35, 
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.black.withValues(alpha: 0.2), Colors.transparent],
                  stops: const [0.0, 0.75, 1.0],
                ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
              },
              blendMode: BlendMode.dstIn,
              child: Image.asset(widget.config.bgImageAsset, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container()),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      color: widget.config.cardColor.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Builder(builder: (ctx) => IconButton(icon: const Icon(Icons.menu_rounded, size: 28), onPressed: () => Scaffold.of(ctx).openDrawer())),
                        Expanded(
                          child: _isSearching
                              ? TextField(
                                  controller: _searchController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: _t('Поиск...', 'Search...'), border: InputBorder.none,
                                    suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() { _searchController.clear(); _isSearching = false; })),
                                  ),
                                )
                              : Padding(padding: const EdgeInsets.only(left: 8.0), child: Text(_t('Мой Дневник', 'My Diary'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                        ),
                        if (!_isSearching) IconButton(icon: const Icon(Icons.search_rounded, size: 28), onPressed: () => setState(() => _isSearching = true)),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 120),
                
                Expanded(
                  child: _filteredEntries.isEmpty
                      ? Center(child: Text(_t('Тут пока пусто... Нажми +', 'Empty here... Press +'), style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 16)))
                      : ShaderMask(
                          shaderCallback: (Rect rect) {
                            // Динамический градиент: если мы вверху списка, верхнего растворения НЕТ
                            final bool isAtTop = _scrollOffset <= 0;
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                isAtTop ? Colors.black : Colors.transparent,
                                Colors.black,
                                Colors.black,
                                Colors.transparent
                              ],
                              stops: const [0.0, 0.08, 0.88, 1.0], 
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.dstIn,
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) {
                              if (notification is ScrollUpdateNotification) {
                                setState(() {
                                  _scrollOffset = notification.metrics.pixels;
                                });
                              }
                              return true;
                            },
                            child: ListView.builder(
                              itemCount: _filteredEntries.length,
                              padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 50),
                              itemBuilder: (ctx, idx) {
                                final entry = _filteredEntries[idx];
                                String previewText = '';
                                for (var b in entry.blocks) {
                                  if (b.type == 'text' && b.value.isNotEmpty) {
                                    previewText = b.value;
                                    break;
                                  }
                                }
                                return GestureDetector(
                                  onTap: () => _openEntryScreen(entry),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: widget.config.cardColor.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: widget.config.accentColor.withValues(alpha: 0.15)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat('dd MMMM yyyy', widget.currentLang == AppLanguage.ru ? 'ru' : 'en').format(entry.date),
                                              style: TextStyle(color: widget.config.accentColor, fontWeight: FontWeight.bold),
                                            ),
                                            Text(entry.moodEmoji, style: const TextStyle(fontSize: 22)),
                                          ],
                                        ),
                                        const Divider(height: 16),
                                        Text(entry.title.isEmpty ? _t('Без названия', 'Untitled') : entry.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                        if (previewText.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(previewText, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: widget.config.textColor.withValues(alpha: 0.7))),
                                        ]
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), notchMargin: 8.0,
        child: Row(children: [IconButton(icon: const Icon(Icons.calendar_month_rounded, size: 28), onPressed: _showCalendarDialog)]),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.config.accentColor, shape: const CircleBorder(),
        onPressed: () => _openEntryScreen(null),
        child: Icon(Icons.add, size: 32, color: widget.config.backgroundColor),
      ),
    );
  }

  void _showCalendarDialog() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked != null) {
      final dayEntries = _allEntries.where((e) => e.date.year == picked.year && e.date.month == picked.month && e.date.day == picked.day).toList();
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('${_t('Заметки за', 'Entries for')} ${DateFormat('dd.MM.yyyy').format(picked)}'),
          content: dayEntries.isEmpty 
              ? Text(_t('Нет записей.', 'No entries.'))
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true, itemCount: dayEntries.length,
                    itemBuilder: (c, i) => ListTile(
                      leading: Text(dayEntries[i].moodEmoji, style: const TextStyle(fontSize: 20)),
                      title: Text(dayEntries[i].title),
                      onTap: () { Navigator.pop(ctx); _openEntryScreen(dayEntries[i]); },
                    ),
                  ),
                ),
        ),
      );
    }
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: widget.config.backgroundColor,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.config.cardColor, widget.config.backgroundColor])),
              child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.auto_stories, size: 32, color: widget.config.accentColor), const SizedBox(width: 12), Text(_t('Настройки', 'Settings'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))])),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildMenuSectionTitle(_t('Язык / Language', 'Language / Язык')),
                  Container(
                    decoration: BoxDecoration(color: widget.config.cardColor, borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: Icon(Icons.g_translate_rounded, color: widget.config.accentColor),
                      title: Text(_t('Язык приложения', 'Interface Language')),
                      trailing: DropdownButton<AppLanguage>(
                        value: widget.currentLang, underline: const SizedBox(), dropdownColor: widget.config.cardColor,
                        onChanged: (lang) { Navigator.pop(context); widget.onLangChanged(lang!); },
                        items: const [DropdownMenuItem(value: AppLanguage.ru, child: Text('Русский')), DropdownMenuItem(value: AppLanguage.en, child: Text('English'))],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildMenuSectionTitle(_t('Оформление', 'Style')),
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Icon(Icons.palette_rounded, color: widget.config.accentColor),
                      title: Text(_t('Выбрать тему', 'Select Theme')),
                      backgroundColor: widget.config.cardColor, collapsedBackgroundColor: widget.config.cardColor,
                      textColor: widget.config.accentColor, iconColor: widget.config.accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              _buildBeautifulThemeCard(_t('Глубокая Синяя', 'Deep Blue'), AppTheme.dark, Icons.bedtime_rounded, const Color(0xFF4C95FF)),
                              _buildBeautifulThemeCard(_t('Мятная Зеленая', 'Mint Green'), AppTheme.light, Icons.eco_rounded, const Color(0xFF2E7D32)),
                              _buildBeautifulThemeCard(_t('Розовая Сакура', 'Cherry Pink'), AppTheme.pink, Icons.auto_awesome_rounded, const Color(0xFFFF4081)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8), 
      child: Text(title.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: widget.config.accentColor.withValues(alpha: 0.6)))
    );
  }

  Widget _buildBeautifulThemeCard(String title, AppTheme theme, IconData icon, Color previewColor) {
    bool isSelected = widget.currentTheme == theme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: isSelected ? widget.config.backgroundColor : widget.config.backgroundColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? widget.config.accentColor : previewColor),
        title: Text(title, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        trailing: isSelected ? Icon(Icons.check_circle, color: widget.config.accentColor, size: 20) : null,
        onTap: () { Navigator.pop(context); widget.onThemeChanged(theme); },
      ),
    );
  }

  void _openEntryScreen(DiaryEntry? entry) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewEntryScreen(entry: entry, onSave: _saveOrUpdateEntry, currentLang: widget.currentLang, config: widget.config)));
  }
}

// --- ЭКРАН СОЗДАНИЯ / РЕДАКТИРОВАНИЯ ---
class NewEntryScreen extends StatefulWidget {
  final DiaryEntry? entry;
  final Function(DiaryEntry) onSave;
  final AppLanguage currentLang;
  final ThemeConfig config;

  const NewEntryScreen({super.key, this.entry, required this.onSave, required this.currentLang, required this.config});

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  late String _id;
  late TextEditingController _titleController;
  
  final List<BlockContent> _blocks = [];
  final List<TextEditingController> _blockControllers = [];
  
  late DateTime _selectedDate;
  String _selectedMood = '😊';
  final List<PlacedSticker> _myStickers = [];

  final List<String> _moods = ['😊', '🥳', '😭', '😡', '🐱', '✨'];
  final List<String> _availableStickers = ['❤️', '⭐', '🎀', '🔥', '🐾', '🍀', '👑', '🧸', '💡', '🍕', '🌸', '🔮'];

  @override
  void initState() {
    super.initState();
    _id = widget.entry?.id ?? DateTime.now().toString();
    _titleController = TextEditingController(text: widget.entry?.title ?? '');
    _selectedDate = widget.entry?.date ?? DateTime.now();
    _selectedMood = widget.entry?.moodEmoji ?? '😊';
    
    if (widget.entry != null) {
      _myStickers.addAll(widget.entry!.stickers);
    }
    
    if (widget.entry != null && widget.entry!.blocks.isNotEmpty) {
      for (var b in widget.entry!.blocks) {
        _blocks.add(BlockContent(type: b.type, value: b.value));
        if (b.type == 'text') {
          _blockControllers.add(TextEditingController(text: b.value));
        } else {
          _blockControllers.add(TextEditingController()); 
        }
      }
    } else {
      _blocks.add(BlockContent(type: 'text', value: ''));
      _blockControllers.add(TextEditingController());
    }

    _titleController.addListener(_triggerAutoSave);
    for (var controller in _blockControllers) {
      controller.addListener(_triggerAutoSave);
    }
  }

  void _triggerAutoSave() {
    for (int i = 0; i < _blocks.length; i++) {
      if (_blocks[i].type == 'text') {
        _blocks[i].value = _blockControllers[i].text;
      }
    }
    widget.onSave(DiaryEntry(
      id: _id, title: _titleController.text, blocks: _blocks,
      date: _selectedDate, moodEmoji: _selectedMood, stickers: List.from(_myStickers),
    ));
  }

  String _t(String ru, String en) => widget.currentLang == AppLanguage.ru ? ru : en;

  void _pickInlineImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      String path = result.files.single.path!;
      setState(() {
        _blocks.add(BlockContent(type: 'image', value: path));
        _blockControllers.add(TextEditingController());
        
        _blocks.add(BlockContent(type: 'text', value: ''));
        var newController = TextEditingController();
        newController.addListener(_triggerAutoSave);
        _blockControllers.add(newController);
      });
      _triggerAutoSave();
    }
  }

  void _openImageFullScreen(File file) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: InteractiveViewer(child: Image.file(file))),
      ),
    ));
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var c in _blockControllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.config.cardColor,
        title: Text(widget.entry != null ? _t('Правка', 'Edit') : _t('Новая мысль', 'New Entry')),
        actions: [
          IconButton(icon: const Icon(Icons.image_rounded, size: 26, color: Colors.greenAccent), onPressed: _pickInlineImage),
          IconButton(icon: const Icon(Icons.face_retouching_natural_rounded, size: 26, color: Colors.pinkAccent), onPressed: _showStickerPicker),
          IconButton(icon: const Icon(Icons.done_rounded, size: 28), onPressed: () { _triggerAutoSave(); Navigator.pop(context); })
        ],
      ),
      // Весь контент и стикеры объединены в один скролл-контейнер
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${_t('Дата', 'Date')}: ${DateFormat('dd.MM.yyyy').format(_selectedDate)}'),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                      if (d != null) { setState(() => _selectedDate = d); _triggerAutoSave(); }
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _moods.map((m) => InkWell(
                      onTap: () { setState(() => _selectedMood = m); _triggerAutoSave(); },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          color: _selectedMood == m ? widget.config.accentColor.withValues(alpha: 0.3) : null
                        ),
                        child: Text(m, style: const TextStyle(fontSize: 24)),
                      ),
                    )).toList(),
                  ),
                  const Divider(),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(hintText: _t('Заголовок', 'Title'), border: InputBorder.none),
                  ),
                  const SizedBox(height: 10),
                  
                  ...List.generate(_blocks.length, (index) {
                    final block = _blocks[index];
                    if (block.type == 'text') {
                      return TextField(
                        controller: _blockControllers[index],
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(hintText: index == 0 ? _t('Пиши тут...', 'Write thoughts...') : '', border: InputBorder.none),
                      );
                    } else {
                      final file = File(block.value);
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () => _openImageFullScreen(file),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(file, fit: BoxFit.cover, width: double.infinity, height: 260), 
                              ),
                            ),
                            Positioned(
                              right: 8, top: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _blocks.removeAt(index);
                                    _blockControllers.removeAt(index);
                                  });
                                  _triggerAutoSave();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.8), shape: BoxShape.circle),
                                  child: const Icon(Icons.close, size: 20, color: Colors.white),
                                ),
                              ),
                            )
                          ],
                        ),
                      );
                    }
                  }),
                  const SizedBox(height: 300), // Запас пространства внизу для размещения стикеров
                ],
              ),
            ),

            // СЛОЙ СТИКЕРОВ: Теперь скроллится СОВМЕСТНО со всем текстом
            ..._myStickers.map((sticker) {
              return Positioned(
                left: sticker.position.dx,
                top: sticker.position.dy,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() { sticker.position += details.delta; });
                    _triggerAutoSave();
                  },
                  onDoubleTap: () {
                    setState(() => _myStickers.remove(sticker));
                    _triggerAutoSave();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.transparent,
                    child: Text(sticker.emoji, style: const TextStyle(fontSize: 42)),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showStickerPicker() {
    showModalBottomSheet(
      context: context, backgroundColor: widget.config.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20), height: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Выбери стикер (Двойной тап для удаления):', 'Select sticker (Double tap to delete):'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: 12, crossAxisSpacing: 12),
                itemCount: _availableStickers.length,
                itemBuilder: (context, index) {
                  final st = _availableStickers[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() {
                        String newId = DateTime.now().microsecondsSinceEpoch.toString();
                        // Создаем стикер в видимой области текущего экрана
                        _myStickers.add(PlacedSticker(id: newId, emoji: st, position: const Offset(140, 220)));
                      });
                      Navigator.pop(ctx);
                      _triggerAutoSave();
                    },
                    child: Center(child: Text(st, style: const TextStyle(fontSize: 34))),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}