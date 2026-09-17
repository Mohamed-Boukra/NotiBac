import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  final int _totalPages = 7;

  // Mock states for interactive elements
  bool _cardFlipped = false;
  String _mockPopupPosition = 'right';
  bool _mockServiceEnabled = false;
  double _mockFrequency = 20;
  bool _mockDndEnabled = false;

  // For the overlay popup preview
  OverlayEntry? _overlayEntry;

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
  }

  void _showMockOverlay(String position) {
    _overlayEntry?.remove();
    
    _overlayEntry = OverlayEntry(builder: (context) {
      return Align(
        alignment: position == 'left' 
            ? Alignment.topLeft 
            : (position == 'center' ? Alignment.topCenter : Alignment.topRight),
        child: Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.height / 6,
            right: position == 'right' ? 16 : 0,
            left: position == 'left' ? 16 : 0,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _overlayEntry?.remove();
                _overlayEntry = null;
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                  ]
                ),
                child: const Text(
                  '1954-11-01',
                  style: TextStyle(color: Color(0xFF1A237E), fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    });
    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    // Only show overlay on the position page (index 3)
                    if (index != 3 && _overlayEntry != null) {
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                    }
                  },
                  children: [
                    _buildPageWelcome(),
                    _buildPageFlipCard(),
                    _buildPageStart(),
                    _buildPagePosition(),
                    _buildPageFrequency(),
                    _buildPageDnd(),
                    _buildPageContent(),
                  ],
                ),
              ),
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageWelcome() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 80,
            backgroundColor: Colors.white,
            child: Icon(Icons.school_rounded, size: 90, color: Colors.indigo),
          ),
          const SizedBox(height: 50),
          const Text('مرحباً بك في NotiBac', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
          const SizedBox(height: 20),
          Text(
            'رفيقك الذكي لحفظ تواريخ وأحداث البكالوريا بكل سهولة وبدون مجهود، مباشرة من شاشة هاتفك!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.library_books_rounded, size: 90, color: Colors.blue),
          const SizedBox(height: 40),
          const Text('محتوى جاهز وقابل للتخصيص', textAlign: TextAlign.center, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.blue)),
          const SizedBox(height: 20),
          Text(
            'التطبيق يحتوي مسبقاً على تواريخ 3 وحدات تاريخية للبكالوريا.\n\nولكن هذا ليس كل شيء! يمكنك إضافة القوائم الخاصة بك، ووضع أي سؤال وإجابة تريد حفظها (ليس فقط التواريخ!)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildPageFlipCard() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('كيف يعمل؟', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal)),
          const SizedBox(height: 20),
          Text(
            'ستظهر لك نافذة صغيرة عشوائياً وأنت تستخدم هاتفك.\nاضغط عليها لقلبها ومعرفة الإجابة!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
          ),
          const SizedBox(height: 50),
          
          GestureDetector(
            onTap: () => setState(() => _cardFlipped = !_cardFlipped),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: _cardFlipped ? const Color(0xFFE0F2F1) : const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(50),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Text(
                _cardFlipped ? 'اندلاع الثورة التحريرية الكبرى' : '1954-11-01',
                style: TextStyle(
                  color: _cardFlipped ? const Color(0xFF004D40) : const Color(0xFF1A237E),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app, color: Colors.orange.shade400, size: 24),
              const SizedBox(width: 8),
              Text('جرب الضغط عليها!', style: TextStyle(color: Colors.orange.shade600, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageStart() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.power_settings_new_rounded, size: 90, color: Colors.green),
          const SizedBox(height: 40),
          const Text('ابدأ الاستخدام', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green)),
          const SizedBox(height: 20),
          Text(
            'من صفحة الإعدادات، قم بتفعيل هذا الزر لتبدأ النوافذ بالظهور تلقائياً أثناء استخدامك للهاتف.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: SwitchListTile(
              title: const Text('تفعيل النوافذ التلقائية', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(_mockServiceEnabled ? 'تعمل الآن' : 'متوقفة', style: TextStyle(color: _mockServiceEnabled ? Colors.teal : Colors.grey)),
              value: _mockServiceEnabled,
              activeColor: Colors.teal,
              onChanged: (val) => setState(() => _mockServiceEnabled = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagePosition() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('موضع النافذة', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          const SizedBox(height: 20),
          Text(
            'اختر مكان ظهور النافذة على شاشتك. جرب الضغط على الأزرار أدناه لرؤية النتيجة فوراً!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
          ),
          const SizedBox(height: 50),
          
          Row(
            children: [
              Expanded(child: _buildPositionOption('يمين', 'right', Icons.align_horizontal_right_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildPositionOption('الوسط', 'center', Icons.align_horizontal_center_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _buildPositionOption('يسار', 'left', Icons.align_horizontal_left_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPositionOption(String title, String value, IconData icon) {
    final isSelected = _mockPopupPosition == value;
    return InkWell(
      onTap: () {
        setState(() => _mockPopupPosition = value);
        _showMockOverlay(value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.deepPurple : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.blueGrey, size: 24),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.blueGrey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildPageFrequency() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer_rounded, size: 90, color: Colors.orange),
          const SizedBox(height: 40),
          const Text('وتيرة الظهور', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange)),
          const SizedBox(height: 20),
          Text(
            'تحكم في مدى سرعة ظهور النوافذ. يمكنك اختيار الوقت بين كل نافذة وأخرى.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                Text('الفاصل الزمني: ${_mockFrequency.toInt()} دقيقة', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                Slider(
                  value: _mockFrequency,
                  min: 5,
                  max: 120,
                  divisions: 23,
                  activeColor: Colors.indigo,
                  onChanged: (val) => setState(() => _mockFrequency = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageDnd() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bedtime_rounded, size: 90, color: Colors.indigoAccent),
          const SizedBox(height: 40),
          const Text('وقت النوم', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigoAccent)),
          const SizedBox(height: 20),
          Text(
            'لا تقلق من الإزعاج ليلاً! فعّل وضع "عدم الإزعاج" ليتم إيقاف النوافذ المنبثقة تلقائياً في أوقات نومك.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: SwitchListTile(
              title: const Text('عدم الإزعاج', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('23:00 إلى 07:00', style: TextStyle(color: _mockDndEnabled ? Colors.indigoAccent : Colors.grey)),
              value: _mockDndEnabled,
              activeColor: Colors.indigoAccent,
              onChanged: (val) => setState(() => _mockDndEnabled = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _finishOnboarding,
            child: const Text('تخطي', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ),
          Row(
            children: List.generate(_totalPages, (index) => _buildDot(index)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () {
              if (_currentPage == _totalPages - 1) {
                _finishOnboarding();
              } else {
                _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              }
            },
            child: Text(_currentPage == _totalPages - 1 ? 'ابدأ الآن' : 'التالي', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 3),
      height: 8,
      width: _currentPage == index ? 20 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Colors.indigo : Colors.indigo.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
