import 'package:flutter/material.dart';
import '../models/event_list.dart';
import '../services/database_service.dart';
import 'events_page.dart';

class ListsPage extends StatefulWidget {
  const ListsPage({super.key});

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> {
  final TextEditingController _listNameController = TextEditingController();
  List<EventList> _allLists = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final lists = await DatabaseService.getAllLists();
      setState(() {
        _allLists = lists;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في تحميل القوائم: $e';
      });
    }
  }

  Future<void> _createNewList(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    final customLists = _allLists.where((l) => !l.isPredefined).toList();
    if (customLists.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يمكنك إضافة قائمة مخصصة واحدة فقط في الوقت الحالي', textAlign: TextAlign.right),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final newList = EventList(
        name: trimmed,
        description: 'قائمة مخصصة',
        isEnabled: true,
        isPredefined: false,
      );

      await DatabaseService.insertList(newList);
      _listNameController.clear();
      await _loadLists();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم إنشاء القائمة: $trimmed', textAlign: TextAlign.right),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء القائمة: $e', textAlign: TextAlign.right),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteCustomList(EventList list) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تأكيد الحذف'),
          content: Text('هل أنت متأكد من حذف القائمة "${list.name}"؟\nسيتم حذف جميع الأحداث التابعة لها.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && list.id != null) {
      await DatabaseService.deleteList(list.id!);
      await _loadLists();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف القائمة: ${list.name}', textAlign: TextAlign.right),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _toggleListEnabled(EventList list) async {
    final updatedList = list.copyWith(isEnabled: !list.isEnabled);
    await DatabaseService.updateList(updatedList);
    await _loadLists();
  }

  @override
  void dispose() {
    _listNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final hasCustomList = _allLists.any((l) => !l.isPredefined);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Header
              Container(
                height: screenHeight * 0.08,
                width: double.infinity,
                color: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        'إدارة الأحداث والتواريخ',
                        style: TextStyle(
                          fontSize: screenHeight * 0.026,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Body
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'قوائمي',
                        style: TextStyle(
                          fontSize: screenHeight * 0.024,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),

                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(color: Colors.orange),
                          ),
                        )
                      else if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadLists,
                                child: const Text('إعادة المحاولة'),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._allLists.map((list) => _buildListItem(list, screenHeight, screenWidth)),

                      SizedBox(height: screenHeight * 0.03),

                      // Create New List Form Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'إنشاء قائمة جديدة',
                              style: TextStyle(
                                fontSize: screenHeight * 0.022,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              hasCustomList
                                  ? 'تم إيجاد قائمة مخصصة بالفعل. يمكنك حذفها لإضافة قائمة جديدة.'
                                  : 'يمكنك إنشاء قائمة مخصصة لإضافة تواريخ جديدة.',
                              style: TextStyle(
                                fontSize: 13,
                                color: hasCustomList ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: hasCustomList ? Colors.grey[100] : Colors.grey[50],
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: TextField(
                                      controller: _listNameController,
                                      enabled: !hasCustomList,
                                      textAlign: TextAlign.right,
                                      decoration: InputDecoration(
                                        hintText: hasCustomList ? 'تمت إضافة القائمة المخصصة' : 'اسم القائمة...',
                                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: hasCustomList ? Colors.grey[300] : Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: hasCustomList
                                        ? null
                                        : () {
                                            _createNewList(_listNameController.text);
                                          },
                                    child: const Text(
                                      'حفظ',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(EventList list, double screenHeight, double screenWidth) {
    return GestureDetector(
      onTap: () {
        if (list.id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventsPage(
                listTitle: list.name,
                listId: list.id!,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight * 0.014),
        padding: EdgeInsets.all(screenWidth * 0.038),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox for active status
            GestureDetector(
              onTap: () => _toggleListEnabled(list),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: list.isEnabled ? Colors.orange : Colors.transparent,
                  border: Border.all(
                    color: list.isEnabled ? Colors.orange : Colors.grey[400]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: list.isEnabled
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    style: TextStyle(
                      fontSize: screenHeight * 0.02,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[850],
                    ),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: DatabaseService.getEventCount(list.id!),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Text(
                        '$count أحداث',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!list.isPredefined)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                    onPressed: () => _deleteCustomList(list),
                    tooltip: 'حذف القائمة',
                  ),
                const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.grey,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
