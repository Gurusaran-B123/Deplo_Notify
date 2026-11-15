// Deplo Notify - Glassmorphism Notification Notes App
//
// pubspec.yaml dependencies:
//   google_fonts: ^6.2.1
//   hive: ^2.2.3
//   hive_flutter: ^1.1.0
//   flutter_local_notifications: ^18.0.1
//   timezone: ^0.9.4
//
// Android: see the setup notes at the bottom of this file.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

// ───────────────────────── GLOBALS ─────────────────────────

late Box notesBox;
late Box settingsBox;
final FlutterLocalNotificationsPlugin notifPlugin =
    FlutterLocalNotificationsPlugin();

const kBgColors = <String, Color>{
  'Red': Color(0xFFE53935),
  'Blue': Color(0xFF1E88E5),
  'Green': Color(0xFF43A047),
  'Purple': Color(0xFF8E24AA),
  'Orange': Color(0xFFFB8C00),
  'Pink': Color(0xFFEC407A),
  'Black': Color(0xFF111111),
  'Teal': Color(0xFF00897B),
};

const kTextColors = <String, Color>{
  'White': Color(0xFFFFFFFF),
  'Black': Color(0xFF000000),
  'Yellow': Color(0xFFFFEB3B),
  'Light Blue': Color(0xFF81D4FA),
  'Light Green': Color(0xFFA5D6A7),
};

const kThemes = <String, List<Color>>{
  'Midnight': [Color(0xFF1A1A2E), Color(0xFF16213E)],
  'Ocean': [Color(0xFF0F2027), Color(0xFF2C5364)],
  'Sunset': [Color(0xFF2D1B3D), Color(0xFF4A1F33)],
};

// ───────────────────────── MAIN ─────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  notesBox = await Hive.openBox('notes');
  settingsBox = await Hive.openBox('settings');

  tzdata.initializeTimeZones();
  const init = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await notifPlugin.initialize(init);
  final android = notifPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission();
  await android?.requestExactAlarmsPermission();

  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(const DeploNotifyApp());
}

// ───────────────────────── THEME HELPERS ─────────────────────────

bool get isDark => settingsBox.get('dark', defaultValue: true) as bool;
String get themeName =>
    settingsBox.get('theme', defaultValue: 'Midnight') as String;

List<Color> get bgGradient => isDark
    ? kThemes[themeName]!
    : const [Color(0xFFE9E4FA), Color(0xFFCFE0F5)];
Color get fg => isDark ? Colors.white : const Color(0xFF1A1A2E);
Color get fgSoft => fg.withOpacity(0.65);
Color get glassFill =>
    isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.55);
Color get glassBorder =>
    isDark ? Colors.white.withOpacity(0.30) : Colors.white.withOpacity(0.80);

TextStyle ps(double size,
        {FontWeight w = FontWeight.w400, Color? c, double? h}) =>
    GoogleFonts.poppins(
        fontSize: size, fontWeight: w, color: c ?? fg, height: h);

// ───────────────────────── APP ─────────────────────────

class DeploNotifyApp extends StatelessWidget {
  const DeploNotifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(),
      builder: (_, __, ___) => MaterialApp(
        title: 'Deplo Notify',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: isDark ? Brightness.dark : Brightness.light,
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

// ───────────────────────── REUSABLE WIDGETS ─────────────────────────

class GradientScaffold extends StatelessWidget {
  final Widget child;
  final Widget? fab;
  const GradientScaffold({super.key, required this.child, this.fab});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      floatingActionButton: fab,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: bgGradient,
          ),
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final double blur;
  final Color? fill;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius = 20,
    this.blur = 15,
    this.fill,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: gradient == null ? (fill ?? glassFill) : null,
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: glassBorder, width: 1),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final IconData? icon;
  final ValueChanged<String>? onChanged;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        minLines: maxLines,
        onChanged: onChanged,
        cursorColor: fg,
        style: ps(15),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: ps(15, c: fgSoft),
          icon: icon == null ? null : Icon(icon, color: fgSoft),
        ),
      ),
    );
  }
}

class GlassFab extends StatelessWidget {
  final VoidCallback onTap;
  const GlassFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      radius: 32,
      padding: const EdgeInsets.all(18),
      gradient: LinearGradient(colors: [
        const Color(0xFF9D7BFF).withOpacity(0.55),
        const Color(0xFF4FC3F7).withOpacity(0.35),
      ]),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
    );
  }
}

/// Accordion-style card. Can be nested (e.g. Privacy Policy inside About).
class ExpandableAboutCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final bool initiallyExpanded;
  final bool nested;

  const ExpandableAboutCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.initiallyExpanded = false,
    this.nested = false,
  });

  @override
  State<ExpandableAboutCard> createState() => _ExpandableAboutCardState();
}

class _ExpandableAboutCardState extends State<ExpandableAboutCard> {
  late bool open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final header = InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => open = !open),
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: widget.nested ? 10 : 4, horizontal: widget.nested ? 8 : 0),
        child: Row(children: [
          Icon(widget.icon, color: const Color(0xFF9D7BFF), size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text(widget.title,
                  style: ps(widget.nested ? 14 : 16, w: FontWeight.w600))),
          AnimatedRotation(
            turns: open ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            child: Icon(Icons.keyboard_arrow_down_rounded, color: fgSoft),
          ),
        ]),
      ),
    );

    final body = AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: open
          ? Padding(
              padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
              child: widget.child)
          : const SizedBox(width: double.infinity),
    );

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [header, body]);

    if (widget.nested) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: fg.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: glassBorder.withOpacity(0.4)),
        ),
        child: content,
      );
    }
    return GlassContainer(margin: const EdgeInsets.only(top: 8), child: content);
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10, left: 4),
        child: Text(text, style: ps(16, w: FontWeight.w600)),
      );
}

// ───────────────────────── NOTIFICATION SERVICE ─────────────────────────

class NotifService {
  static Future<int> schedule({
    required int noteId,
    required String title,
    required String body,
    required List<DateTime> times,
    required Color bg,
    required Color text,
  }) async {
    int scheduled = 0;
    final sound = settingsBox.get('sound', defaultValue: true) as bool;
    final vibrate = settingsBox.get('vibration', defaultValue: true) as bool;

    for (int i = 0; i < times.length; i++) {
      if (times[i].isBefore(DateTime.now())) continue;
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          'deplo_notify_${sound}_$vibrate',
          'Deplo Notify Reminders',
          channelDescription: 'Reminders for your notes',
          importance: Importance.max,
          priority: Priority.high,
          playSound: sound,
          enableVibration: vibrate,
          color: bg,
          colorized: true,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: DarwinNotificationDetails(presentSound: sound),
      );
      await notifPlugin.zonedSchedule(
        noteId * 100 + i,
        title,
        body,
        tz.TZDateTime.from(times[i], tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      scheduled++;
    }
    return scheduled;
  }

  static Future<void> cancelNote(int noteId, int count) async {
    for (int i = 0; i < count + 20; i++) {
      await notifPlugin.cancel(noteId * 100 + i);
    }
  }
}

// ───────────────────────── HOME SCREEN ─────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String query = '';

  List<Map> get notes {
    final list = notesBox.values.map((e) => Map.from(e as Map)).toList();
    list.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
    if (query.isEmpty) return list;
    final q = query.toLowerCase();
    return list
        .where((n) =>
            n['title'].toString().toLowerCase().contains(q) ||
            n['body'].toString().toLowerCase().contains(q))
        .toList();
  }

  DateTime? nextReminder(Map n) {
    final now = DateTime.now();
    final times = (n['reminders'] as List)
        .map((e) => DateTime.parse(e as String))
        .where((d) => d.isAfter(now))
        .toList()
      ..sort();
    return times.isEmpty ? null : times.first;
  }

  String fmt(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ap = d.hour >= 12 ? 'PM' : 'AM';
    return '${m[d.month - 1]} ${d.day}, $h:${d.minute.toString().padLeft(2, '0')} $ap';
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      fab: GlassFab(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddNoteScreen())),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text('Deplo Notify',
                      style: ps(28, w: FontWeight.w700))),
              GlassContainer(
                radius: 16,
                padding: const EdgeInsets.all(10),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsScreen())),
                child: Icon(Icons.settings_rounded, color: fg, size: 22),
              ),
            ]),
            const SizedBox(height: 16),
            GlassTextField(
              controller: TextEditingController(text: query)
                ..selection = TextSelection.collapsed(offset: query.length),
              hint: 'Search notes...',
              icon: Icons.search_rounded,
              onChanged: (v) => setState(() => query = v),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: notesBox.listenable(),
                builder: (_, __, ___) {
                  final list = notes;
                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.notifications_none_rounded,
                                size: 64, color: fgSoft),
                            const SizedBox(height: 12),
                            Text('No notes yet',
                                style: ps(16, c: fgSoft)),
                            Text('Tap + to create one',
                                style: ps(13, c: fgSoft)),
                          ]),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: list.length,
                    itemBuilder: (_, i) => _noteCard(list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noteCard(Map n) {
    final next = nextReminder(n);
    final dot = Color(n['bg'] as int);
    return Dismissible(
      key: ValueKey(n['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.redAccent.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) async {
        await NotifService.cancelNote(
            n['id'] as int, (n['reminders'] as List).length);
        await notesBox.delete(n['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Note deleted', style: ps(13, c: Colors.white))));
        }
      },
      child: GlassContainer(
        margin: const EdgeInsets.only(bottom: 14),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddNoteScreen(existing: n))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: dot.withOpacity(0.7), blurRadius: 8)],
            ),
          ),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n['title'].toString().isEmpty ? 'Untitled' : n['title'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ps(17, w: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(n['body'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ps(13, c: fgSoft, h: 1.4)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Icon(Icons.alarm_rounded,
                        size: 15, color: const Color(0xFF9D7BFF)),
                    const SizedBox(width: 6),
                    Text(next == null ? 'No upcoming reminder' : fmt(next),
                        style: ps(12, c: fgSoft, w: FontWeight.w500)),
                  ]),
                ]),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── ADD / EDIT NOTE SCREEN ─────────────────────────

class AddNoteScreen extends StatefulWidget {
  final Map? existing;
  const AddNoteScreen({super.key, this.existing});
  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  List<DateTime?> dates = [null];
  List<TimeOfDay?> times = [null];
  Color bgColor = kBgColors['Purple']!;
  Color textColor = kTextColors['White']!;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      titleCtrl.text = e['title'];
      bodyCtrl.text = e['body'];
      bgColor = Color(e['bg'] as int);
      textColor = Color(e['text'] as int);
      final r = (e['reminders'] as List)
          .map((x) => DateTime.parse(x as String))
          .toList();
      if (r.isNotEmpty) {
        dates = r.map<DateTime?>((d) => DateTime(d.year, d.month, d.day)).toList();
        times = r.map<TimeOfDay?>((d) => TimeOfDay(hour: d.hour, minute: d.minute)).toList();
      }
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    bodyCtrl.dispose();
    super.dispose();
  }

  Widget _pickerTheme(BuildContext ctx, Widget? child) => Theme(
        data: ThemeData(
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
              primary: Color(0xFF9D7BFF), surface: Color(0xFF1E1E3A)),
        ),
        child: child!,
      );

  Future<void> pickDate(int i) async {
    final d = await showDatePicker(
      context: context,
      initialDate: dates[i] ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: _pickerTheme,
    );
    if (d != null) setState(() => dates[i] = d);
  }

  Future<void> pickTime(int i) async {
    final t = await showTimePicker(
      context: context,
      initialTime: times[i] ?? TimeOfDay.now(),
      builder: _pickerTheme,
    );
    if (t != null) setState(() => times[i] = t);
  }

  String _d(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _t(TimeOfDay t) => t.format(context);

  Future<void> save() async {
    if (titleCtrl.text.trim().isEmpty && bodyCtrl.text.trim().isEmpty) {
      _toast('Please write a title or note');
      return;
    }
    final reminders = <DateTime>[];
    for (int i = 0; i < dates.length; i++) {
      if (dates[i] != null && times[i] != null) {
        reminders.add(DateTime(dates[i]!.year, dates[i]!.month, dates[i]!.day,
            times[i]!.hour, times[i]!.minute));
      }
    }
    final id = widget.existing?['id'] as int? ??
        (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 2000000;

    if (widget.existing != null) {
      await NotifService.cancelNote(
          id, (widget.existing!['reminders'] as List).length);
    }

    final title = titleCtrl.text.trim().isEmpty ? 'Deplo Notify' : titleCtrl.text.trim();
    final body = bodyCtrl.text.trim();

    await notesBox.put(id, {
      'id': id,
      'title': titleCtrl.text.trim(),
      'body': body,
      'reminders': reminders.map((e) => e.toIso8601String()).toList(),
      'bg': bgColor.value,
      'text': textColor.value,
    });

    final count = await NotifService.schedule(
      noteId: id,
      title: title,
      body: body,
      times: reminders,
      bg: bgColor,
      text: textColor,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            count == 0 ? 'Note saved (no upcoming reminders)' : '$count reminder(s) set',
            style: ps(13, c: Colors.white))));
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m, style: ps(13, c: Colors.white))));

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Row(children: [
            GlassContainer(
              radius: 16,
              padding: const EdgeInsets.all(10),
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
            ),
            const SizedBox(width: 14),
            Text(widget.existing == null ? 'New Note' : 'Edit Note',
                style: ps(24, w: FontWeight.w700)),
          ]),
          const SizedBox(height: 20),
          GlassTextField(controller: titleCtrl, hint: 'Title'),
          const SizedBox(height: 14),
          GlassTextField(controller: bodyCtrl, hint: 'Write your note...', maxLines: 5),

          // Reminders
          const SectionTitle('Reminders'),
          ...List.generate(dates.length, _reminderRow),
          const SizedBox(height: 4),
          GlassContainer(
            onTap: () => setState(() {
              dates.add(null);
              times.add(null);
            }),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.add_rounded, color: Color(0xFF9D7BFF)),
              const SizedBox(width: 8),
              Text('Add Another Date & Time',
                  style: ps(14, w: FontWeight.w500)),
            ]),
          ),

          // Notification Style
          const SectionTitle('Notification Style'),
          GlassContainer(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Background Color', style: ps(13, c: fgSoft)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: kBgColors.entries
                    .map((e) => _colorDot(e.value, e.key, bgColor,
                        (c) => setState(() => bgColor = c)))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text('Text Color', style: ps(13, c: fgSoft)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: kTextColors.entries
                    .map((e) => _colorDot(e.value, e.key, textColor,
                        (c) => setState(() => textColor = c)))
                    .toList(),
              ),
              const SizedBox(height: 20),
              Text('Live Preview', style: ps(13, c: fgSoft)),
              const SizedBox(height: 12),
              _preview(),
            ]),
          ),

          const SizedBox(height: 28),
          GlassContainer(
            onTap: save,
            radius: 28,
            padding: const EdgeInsets.symmetric(vertical: 18),
            gradient: LinearGradient(colors: [
              const Color(0xFF9D7BFF).withOpacity(0.65),
              const Color(0xFF4FC3F7).withOpacity(0.45),
            ]),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.alarm_add_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text('Save & Set Reminder',
                  style: ps(16, w: FontWeight.w600, c: Colors.white)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _reminderRow(int i) {
    Widget chip(IconData icon, String label, VoidCallback onTap) => Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              decoration: BoxDecoration(
                color: fg.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: glassBorder.withOpacity(0.5)),
              ),
              child: Row(children: [
                Icon(icon, size: 18, color: const Color(0xFF9D7BFF)),
                const SizedBox(width: 8),
                Flexible(
                    child: Text(label,
                        overflow: TextOverflow.ellipsis, style: ps(13))),
              ]),
            ),
          ),
        );

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        chip(Icons.calendar_today_rounded,
            dates[i] == null ? 'Date' : _d(dates[i]!), () => pickDate(i)),
        const SizedBox(width: 10),
        chip(Icons.access_time_rounded,
            times[i] == null ? 'Time' : _t(times[i]!), () => pickTime(i)),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
          onPressed: () => setState(() {
            if (dates.length == 1) {
              dates[0] = null;
              times[0] = null;
            } else {
              dates.removeAt(i);
              times.removeAt(i);
            }
          }),
        ),
      ]),
    );
  }

  Widget _colorDot(Color c, String name, Color selected, ValueChanged<Color> onTap) {
    final sel = c.value == selected.value;
    return Tooltip(
      message: name,
      child: GestureDetector(
        onTap: () => onTap(c),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(
                color: sel ? fg : fg.withOpacity(0.3), width: sel ? 3 : 1),
            boxShadow: sel ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 10)] : null,
          ),
          child: sel
              ? Icon(Icons.check_rounded,
                  size: 20,
                  color: c.computeLuminance() > 0.5 ? Colors.black : Colors.white)
              : null,
        ),
      ),
    );
  }

  Widget _preview() {
    final title = titleCtrl.text.trim().isEmpty ? 'Your note title' : titleCtrl.text.trim();
    final body = bodyCtrl.text.trim().isEmpty
        ? 'Your note will appear like this'
        : bodyCtrl.text.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgColor.withOpacity(0.85), bgColor.withOpacity(0.55)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: textColor.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(Icons.notifications_active_rounded,
                  color: textColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ps(15, w: FontWeight.w600, c: textColor)),
                const SizedBox(height: 2),
                Text(body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ps(12, c: textColor.withOpacity(0.85))),
              ]),
            ),
            Text('now', style: ps(11, c: textColor.withOpacity(0.7))),
          ]),
        ),
      ),
    );
  }
}

// ───────────────────────── SETTINGS SCREEN ─────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Widget _switchRow(String label, IconData icon, String key, bool def) {
    final v = settingsBox.get(key, defaultValue: def) as bool;
    return Row(children: [
      Icon(icon, color: const Color(0xFF9D7BFF), size: 22),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: ps(15))),
      Switch(
        value: v,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xFF9D7BFF),
        onChanged: (x) async {
          await settingsBox.put(key, x);
          setState(() {});
        },
      ),
    ]);
  }

  Widget _para(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: ps(13, c: fgSoft, h: 1.6)),
      );

  Widget _sub(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 4),
        child: Text(t, style: ps(14, w: FontWeight.w600)),
      );

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Row(children: [
            GlassContainer(
              radius: 16,
              padding: const EdgeInsets.all(10),
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
            ),
            const SizedBox(width: 14),
            Text('Settings', style: ps(24, w: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),

          // Appearance
          const SectionTitle('Appearance'),
          GlassContainer(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _switchRow('Dark Mode', Icons.dark_mode_rounded, 'dark', true),
              Divider(color: glassBorder.withOpacity(0.4), height: 20),
              Row(children: [
                const Icon(Icons.palette_rounded,
                    color: Color(0xFF9D7BFF), size: 22),
                const SizedBox(width: 12),
                Text('App Theme', style: ps(15)),
              ]),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: kThemes.entries.map((e) {
                  final sel = themeName == e.key;
                  return GestureDetector(
                    onTap: () async {
                      await settingsBox.put('theme', e.key);
                      setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: e.value),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: sel ? Colors.white : Colors.white24,
                            width: sel ? 2 : 1),
                      ),
                      child: Text(e.key,
                          style: ps(12, c: Colors.white, w: FontWeight.w500)),
                    ),
                  );
                }).toList(),
              ),
            ]),
          ),

          // Notifications
          const SectionTitle('Notifications'),
          GlassContainer(
            child: Column(children: [
              _switchRow('Sound', Icons.volume_up_rounded, 'sound', true),
              Divider(color: glassBorder.withOpacity(0.4), height: 20),
              _switchRow('Vibration', Icons.vibration_rounded, 'vibration', true),
            ]),
          ),

          // About (accordion)
          const SectionTitle('About'),
          ExpandableAboutCard(
            title: 'About',
            icon: Icons.info_outline_rounded,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ExpandableAboutCard(
                nested: true,
                title: 'About This App',
                icon: Icons.notifications_active_rounded,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _para(
                      'Deplo Notify is a smart notification notes app. Write any note, set multiple dates and times, and get reminded exactly on time. You can also customize your notification with different background and text colors to make it stand out.'),
                  _para("It's a deplofree creation."),
                ]),
              ),
              ExpandableAboutCard(
                nested: true,
                title: 'How to Use',
                icon: Icons.menu_book_rounded,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _para('1. Tap + to create a note.'),
                  _para('2. Write your title and note.'),
                  _para('3. Add one or more Date & Time.'),
                  _para('4. Choose BG and Text color.'),
                  _para('5. Tap Save.'),
                  _para('Your notification will arrive on time.'),
                ]),
              ),
              ExpandableAboutCard(
                nested: true,
                title: 'Privacy Policy',
                icon: Icons.privacy_tip_rounded,
                child: _para(
                    'Deplo Notify respects your privacy. All your notes are stored only on your device. We do not collect, share or upload any personal data or notes to any server. Your data stays with you.'),
              ),
              const SizedBox(height: 18),
              Center(
                child: Column(children: [
                  _sub('© 2026 All Rights Reserved'),
                  Text('Developed by Mr. Gurusaran B',
                      style: ps(12, c: fgSoft)),
                  const SizedBox(height: 2),
                  Text('Deplo Apps',
                      style: ps(12, c: const Color(0xFF9D7BFF), w: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: 6),
            ]),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── ANDROID SETUP NOTES ─────────────────────────

1) android/app/build.gradle (inside android { ... }):
     compileSdkVersion 34   (or higher)
     compileOptions {
       coreLibraryDesugaringEnabled true
       sourceCompatibility JavaVersion.VERSION_1_8
       targetCompatibility JavaVersion.VERSION_1_8
     }
   dependencies { coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4' }

2) android/app/src/main/AndroidManifest.xml (inside <manifest>):
     <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
     <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
     <uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
     <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
     <uses-permission android:name="android.permission.VIBRATE"/>

   Inside <application>:
     <receiver android:exported="false"
       android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
     <receiver android:exported="false"
       android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
       <intent-filter>
         <action android:name="android.intent.action.BOOT_COMPLETED"/>
         <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
       </intent-filter>
     </receiver>
*/
