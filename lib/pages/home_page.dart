import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // 30-second test state
  bool _running = false;
  int _secs = 30;
  Timer? _timer;

  // Periodic service state
  bool _periodicEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPeriodicState();
  }

  Future<void> _loadPeriodicState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _periodicEnabled = prefs.getBool('periodic_enabled') ?? false;
    });
  }

  // ── 30-second test ────────────────────────────────────────────────────────

  Future<void> _onTestPressed() async {
    final bool granted = await _ch.invokeMethod('checkPermission') ?? false;
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🔐 فعّل إذن "الظهور فوق التطبيقات" لـ NotiBac ثم اضغط مرة أخرى',
            textAlign: TextAlign.right),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ));
      await _ch.invokeMethod('requestPermission');
      return;
    }

    await DatabaseService.getAllLists();
    List<Event> events = await DatabaseService.getAllEnabledEvents();
    if (events.isEmpty) events = await DatabaseService.getEventsByListId(1);
    if (events.isEmpty || !mounted) return;
    final event = events[Random().nextInt(events.length)];

    await _ch.invokeMethod('scheduleOverlay', {
      'delay_seconds': 30,
      'date': event.date,
      'title': event.title,
    });

    if (!mounted) return;
    setState(() { _running = true; _secs = 30; });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ ستظهر النافذة بعد 30 ثانية — يمكنك إغلاق التطبيق الآن',
          textAlign: TextAlign.right),
      backgroundColor: Colors.green,
      duration: Duration(seconds: 4),
    ));

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

  // ── Periodic service toggle ───────────────────────────────────────────────

  Future<void> _togglePeriodic(bool enabled) async {
    final bool granted = await _ch.invokeMethod('checkPermission') ?? false;
    if (!granted && enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🔐 فعّل إذن "الظهور فوق التطبيقات" ثم حاول مجدداً',
            textAlign: TextAlign.right),
        backgroundColor: Colors.orange,
      ));
      await _ch.invokeMethod('requestPermission');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('periodic_enabled', enabled);

    if (enabled) {
      await _ch.invokeMethod('startPeriodic');
    } else {
      await _ch.invokeMethod('stopPeriodic');
    }

    if (!mounted) return;
    setState(() => _periodicEnabled = enabled);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        enabled
            ? '✅ الخدمة مفعّلة — ستظهر نافذة كل 2 دقيقة (تجريبي)'
            : '⏹️ تم إيقاف الخدمة',
        textAlign: TextAlign.right,
      ),
      backgroundColor: enabled ? Colors.green : Colors.grey[700],
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sh = MediaQuery.of(context).size.height;
    final sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: Column(children: [
        // ── Top header ──
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

        // ── Middle body ──
        Expanded(child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(children: [
              const Icon(Icons.school_rounded, size: 40, color: Colors.orange),
              const SizedBox(height: 8),
              const Text('NotiBac', style: TextStyle(fontSize: 20,
                  fontWeight: FontWeight.bold, color: Colors.black87)),

              const SizedBox(height: 20),

              // ── Periodic service card ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _periodicEnabled
                      ? Colors.green.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _periodicEnabled ? Colors.green : Colors.grey.shade300,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Icon(Icons.notifications_active_rounded,
                        color: _periodicEnabled ? Colors.green : Colors.grey),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('الاختبارات التلقائية',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    Switch(
                      value: _periodicEnabled,
                      onChanged: _togglePeriodic,
                      activeThumbColor: Colors.green,
                      activeTrackColor: Colors.green.withValues(alpha: 0.4),
                    ),
                  ]),
                  if (_periodicEnabled) ...[
                    const SizedBox(height: 6),
                    const Text('✅ الخدمة تعمل — نافذة اختبار كل 2 دقيقة (تجريبي)',  
                        style: TextStyle(fontSize: 12, color: Colors.green)),
                    const Text('يمكنك إغلاق التطبيق وستستمر في العمل',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ] else ...[
                    const SizedBox(height: 6),
                    const Text('فعّل لتظهر نافذة اختبار تلقائياً كل 2 دقيقة (تجريبي)',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ]),
              ),

              const SizedBox(height: 16),

              // ── 30s test button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: _running ? Colors.amber[100] : Colors.orange,
                    foregroundColor: _running ? Colors.deepOrange : Colors.white,
                    elevation: 3,
                  ),
                  onPressed: _running ? null : _onTestPressed,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(_running ? Icons.timer_outlined : Icons.play_arrow_rounded, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      _running ? 'اختبار قادم خلال $_secs ثانية...'
                          : 'اختبار النافذة (30 ثانية)  ⏱️',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
        )),

        // ── Bottom actions ──
        ClipPath(
          clipper: BottomSlantClipper(),
          child: Container(
            color: Colors.orange, width: double.infinity, height: sh * 0.28,
            child: Padding(
              padding: EdgeInsets.only(top: sh * 0.03),
              child: Center(
                child: SizedBox(
                  width: sw * 0.88,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 3,
                    ),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const ListsPage())),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Icon(Icons.calendar_month_rounded, size: 26, color: Colors.orange),
                      Text('إدارة الأحداث والتواريخ',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ])),
    );
  }
}
