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
    setState(() => _isLoading = true);
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
          backgroundColor: Colors.amber,
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
          SnackBar(content: Text('تم إنشاء القائمة: $trimmed', textAlign: TextAlign.right), backgroundColor: Colors.teal),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في إنشاء القائمة: $e', textAlign: TextAlign.right), backgroundColor: Colors.redAccent),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          content: Text('هل أنت متأكد من حذف القائمة "${list.name}"؟\nسيتم حذف جميع الأحداث التابعة لها.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء', style: TextStyle(color: Colors.blueGrey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
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
          SnackBar(content: Text('تم حذف القائمة: ${list.name}', textAlign: TextAlign.right), backgroundColor: Colors.teal),
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
    final hasCustomList = _allLists.any((l) => !l.isPredefined);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: const Text('الأحداث والتواريخ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                                  const SizedBox(height: 16),
                                  Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 16), textAlign: TextAlign.center),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                                    onPressed: _loadLists,
                                    child: const Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _allLists.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text('قوائمي', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                );
                              }
                              return _buildListItem(_allLists[index - 1]);
                            },
                          ),
              ),
              
              // ── Create New List Footer ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.indigo.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                  ],
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إنشاء قائمة جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 8),
                    Text(
                      hasCustomList
                          ? 'تم إضافة القائمة المخصصة بالفعل. احذفها لإنشاء واحدة جديدة.'
                          : 'أنشئ قائمة مخصصة لإضافة تواريخك الخاصة.',
                      style: TextStyle(fontSize: 13, color: hasCustomList ? Colors.grey[500] : Colors.blueGrey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: hasCustomList ? Colors.grey[100] : const Color(0xFFF4F6F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
                            ),
                            child: TextField(
                              controller: _listNameController,
                              enabled: !hasCustomList,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                hintText: hasCustomList ? 'تمت إضافة القائمة' : 'اسم القائمة...',
                                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: hasCustomList ? Colors.grey[300] : Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: hasCustomList ? 0 : 3,
                            ),
                            onPressed: hasCustomList ? null : () => _createNewList(_listNameController.text),
                            child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
    );
  }

  Widget _buildListItem(EventList list) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (list.id != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventsPage(listTitle: list.name, listId: list.id!),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Custom checkbox
                GestureDetector(
                  onTap: () => _toggleListEnabled(list),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: list.isEnabled ? Colors.teal : Colors.transparent,
                      border: Border.all(
                        color: list.isEnabled ? Colors.teal : Colors.grey[300]!,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: list.isEnabled
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<int>(
                        future: DatabaseService.getEventCount(list.id!),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          return Text(
                            '$count أحداث',
                            style: TextStyle(fontSize: 13, color: Colors.blueGrey.withValues(alpha: 0.7)),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Actions
                if (!list.isPredefined)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 24),
                    onPressed: () => _deleteCustomList(list),
                  ),
                const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.blueGrey, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
