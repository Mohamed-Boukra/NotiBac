import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/event.dart';
import '../services/database_service.dart';
import '../widgets/slant_clipper.dart';
import 'lists_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _ch = MethodChannel('notibac/scheduler');
  bool _running = false;
  int _secs = 30;
  Timer? _timer;

  Future<void> _onTestPressed() async {
    // 1. Check permission via native Kotlin
    final bool granted = await _ch.invokeMethod('checkPermission') ?? false;
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '🔐 يرجى السماح لـ NotiBac بـ "الظهور فوق التطبيقات" ثم اضغط مرة أخرى',
            textAlign: TextAlign.right,
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      await _ch.invokeMethod('requestPermission');
      return; // user must press again after granting
    }

    // 2. Seed DB and pick a random event
    await DatabaseService.getAllLists();
    List<Event> events = await DatabaseService.getAllEnabledEvents();
    if (events.isEmpty) events = await DatabaseService.getEventsByListId(1);
    if (events.isEmpty || !mounted) return;
    final event = events[Random().nextInt(events.length)];

    // 3. Start native Kotlin foreground service
    await _ch.invokeMethod('scheduleOverlay', {
      'delay_seconds': 30,
      'date': event.date,
      'title': event.title,
    });

    if (!mounted) return;
    setState(() { _running = true; _secs = 30; });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '✅ تم! ستظهر النافذة بعد 30 ثانية — يمكنك إغلاق التطبيق الآن',
          textAlign: TextAlign.right,
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 5),
      ),
    );

    // Visual countdown only (real timer runs in native Kotlin service)
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secs > 1) {
        if (mounted) setState(() => _secs--);
      } else {
        t.cancel();
        if (mounted) setState(() => _running = false);
      }
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    final sw = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Column(children: [
        ClipPath(
          clipper: TopSlantClipper(),
          child: Container(
            color: Colors.orange, height: sh * 0.16, width: double.infinity,
            alignment: Alignment.center,
            child: const Text('NotiBac',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold,
                  color: Colors.white, letterSpacing: 1.2)),
          ),
        ),
        Expanded(child: Directionality(
          textDirection: TextDirection.rtl,
          child: Center(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.school_rounded, size: 44, color: Colors.orange),
              const SizedBox(height: 10),
              const Text('مرحبًا بك في تطبيق NotiBac!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(
                'اضغط زر التجربة...\nستظهر نافذة عائمة بعد 30 ثانية\nحتى لو أغلقت التطبيق تماماً!\n\n'
                '📅 التاريخ → اضغط → الحدث → اضغط → إغلاق',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.6)),
            ]),
          )),
        )),
        ClipPath(
          clipper: BottomSlantClipper(),
          child: Container(
            color: Colors.orange, width: double.infinity, height: sh * 0.42,
            child: Padding(
              padding: EdgeInsets.only(top: sh * 0.04),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                SizedBox(width: sw * 0.88, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    backgroundColor: _running ? Colors.amber[100] : Colors.white,
                    foregroundColor: Colors.deepOrange, elevation: 5),
                  onPressed: _running ? null : _onTestPressed,
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Icon(_running ? Icons.timer_outlined : Icons.open_in_new_rounded,
                        size: 26, color: Colors.deepOrange),
                    Text(_running ? 'العد التنازلي: $_secs ثانية...'
                        : 'تجربة النافذة المنبثقة (30 ثانية) ⏱️',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ]),
                )),
                const SizedBox(height: 16),
                SizedBox(width: sw * 0.88, child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    backgroundColor: Colors.white.withValues(alpha: 0.95),
                    foregroundColor: Colors.black87, elevation: 3),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ListsPage())),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Icon(Icons.calendar_month_rounded, size: 26, color: Colors.orange),
                    Text('إدارة الأحداث والتواريخ',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ]),
                )),
              ]),
            ),
          ),
        ),
      ])),
    );
  }
}
