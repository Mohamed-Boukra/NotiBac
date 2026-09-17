import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../services/database_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _ch = MethodChannel('notibac/scheduler');

  bool _periodicEnabled = false;
  int _periodicInterval = 20; // in minutes
  String _popupPosition = 'right';

  bool _dndEnabled = false;
  TimeOfDay _dndStart = const TimeOfDay(hour: 23, minute: 0); // 11 PM
  TimeOfDay _dndEnd = const TimeOfDay(hour: 7, minute: 0); // 7 AM

  // 30s test
  bool _runningTest = false;
  int _secs = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _periodicEnabled = prefs.getBool('periodic_enabled') ?? false;
      _periodicInterval = prefs.getInt('periodic_interval') ?? 20;
      _popupPosition = prefs.getString('popup_position') ?? 'right';
      _dndEnabled = prefs.getBool('dnd_enabled') ?? false;
      
      final dStart = prefs.getInt('dnd_start') ?? 23;
      final dEnd = prefs.getInt('dnd_end') ?? 7;
      _dndStart = TimeOfDay(hour: dStart, minute: 0);
      _dndEnd = TimeOfDay(hour: dEnd, minute: 0);
    });
  }

  Future<void> _saveSetting<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
    if (value is String) await prefs.setString(key, value);
    
    if (_periodicEnabled && key != 'periodic_enabled') {
      await _ch.invokeMethod('restartPeriodic');
    }
  }

  Future<void> _togglePeriodic(bool enabled) async {
    final bool granted = await _ch.invokeMethod('checkPermission') ?? false;
    if (!granted && enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🔐 فعّل إذن "الظهور فوق التطبيقات" ثم حاول مجدداً', textAlign: TextAlign.right),
        backgroundColor: Colors.amber,
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
  }

  Future<void> _onTestPressed() async {
    final bool granted = await _ch.invokeMethod('checkPermission') ?? false;
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🔐 فعّل إذن "الظهور فوق التطبيقات" لـ NotiBac ثم اضغط مرة أخرى', textAlign: TextAlign.right),
        backgroundColor: Colors.amber,
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
    setState(() { _runningTest = true; _secs = 30; });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('✅ ستظهر النافذة بعد 30 ثانية — يمكنك إغلاق التطبيق الآن', textAlign: TextAlign.right),
      backgroundColor: Colors.teal,
      duration: Duration(seconds: 4),
    ));

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secs > 1) {
        if (mounted) setState(() => _secs--);
      } else {
        t.cancel();
        if (mounted) setState(() => _runningTest = false);
      }
    });
  }

  String _formatInterval(int mins) {
    if (mins < 60) return '$mins دقيقة';
    if (mins == 60) return '1 ساعة';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (m == 0) return '$h ساعة';
    return '$h ساعة و $m دقيقة';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9), // Light blue-grey background
      appBar: AppBar(
        title: const Text('الإعدادات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // ── Main Service Toggle ──
            _buildSectionCard(
              padding: const EdgeInsets.all(8),
              child: SwitchListTile(
                title: const Text('الخدمة التلقائية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                subtitle: Text(
                  _periodicEnabled 
                    ? 'تعمل الآن — النوافذ ستظهر بانتظام' 
                    : 'متوقفة',
                  style: TextStyle(color: _periodicEnabled ? Colors.teal : Colors.grey[600], fontSize: 13),
                ),
                value: _periodicEnabled,
                activeThumbColor: Colors.teal,
                activeTrackColor: Colors.teal.withValues(alpha: 0.3),
                onChanged: _togglePeriodic,
                secondary: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _periodicEnabled ? Colors.teal.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.notifications_active_rounded, color: _periodicEnabled ? Colors.teal : Colors.grey, size: 28),
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // ── Frequency Settings ──
            _buildSectionTitle('تخصيص الظهور', Icons.tune_rounded),
            _buildSectionCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('تكرار ظهور النافذة:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatInterval(_periodicInterval),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.indigo,
                      inactiveTrackColor: Colors.indigo.withValues(alpha: 0.2),
                      thumbColor: Colors.indigo,
                      overlayColor: Colors.indigo.withValues(alpha: 0.1),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _periodicInterval.toDouble(),
                      min: 2,
                      max: 240, // Up to 4 hours
                      divisions: 119,
                      onChanged: (val) {
                        setState(() => _periodicInterval = val.round());
                      },
                      onChangeEnd: (val) {
                        _saveSetting('periodic_interval', val.round());
                      },
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('دقيقتين', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('4 ساعات', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Popup Position ──
            _buildSectionTitle('موضع النافذة', Icons.align_horizontal_center_rounded),
            _buildSectionCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildPositionOption('يمين', 'right', Icons.align_horizontal_right_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPositionOption('الوسط', 'center', Icons.align_horizontal_center_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPositionOption('يسار', 'left', Icons.align_horizontal_left_rounded),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Do Not Disturb ──
            _buildSectionTitle('وقت النوم', Icons.bedtime_rounded),
            _buildSectionCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: const Text('عدم الإزعاج', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                    subtitle: const Text('إيقاف النوافذ المنبثقة خلال فترة النوم', style: TextStyle(fontSize: 13)),
                    value: _dndEnabled,
                    activeThumbColor: Colors.indigo,
                    activeTrackColor: Colors.indigo.withValues(alpha: 0.3),
                    onChanged: (val) {
                      setState(() => _dndEnabled = val);
                      _saveSetting('dnd_enabled', val);
                    },
                  ),
                  if (_dndEnabled) ...[
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTimePickerCard(
                              title: 'من الساعة',
                              time: _dndStart,
                              onTap: () async {
                                final time = await showTimePicker(context: context, initialTime: _dndStart);
                                if (time != null) {
                                  setState(() => _dndStart = time);
                                  _saveSetting('dnd_start', time.hour);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTimePickerCard(
                              title: 'إلى الساعة',
                              time: _dndEnd,
                              onTap: () async {
                                final time = await showTimePicker(context: context, initialTime: _dndEnd);
                                if (time != null) {
                                  setState(() => _dndEnd = time);
                                  _saveSetting('dnd_end', time.hour);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),

            const SizedBox(height: 40),

            // ── Test Button ──
            /* 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: _runningTest ? Colors.indigo.shade100 : Colors.indigo,
                foregroundColor: _runningTest ? Colors.indigo : Colors.white,
                elevation: 4,
                shadowColor: Colors.indigo.withValues(alpha: 0.4),
              ),
              onPressed: _runningTest ? null : _onTestPressed,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_runningTest ? Icons.timer_outlined : Icons.play_arrow_rounded, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    _runningTest 
                      ? 'اختبار قادم خلال $_secs ثانية...'
                      : 'تجربة النافذة المنبثقة (30 ثانية)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            */
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child, required EdgeInsets padding}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }

  Widget _buildTimePickerCard({required String title, required TimeOfDay time, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
            const SizedBox(height: 8),
            Text(
              time.format(context),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.indigo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionOption(String title, String value, IconData icon) {
    final isSelected = _popupPosition == value;
    return InkWell(
      onTap: () {
        setState(() => _popupPosition = value);
        _saveSetting('popup_position', value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.indigo : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.blueGrey, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.blueGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
