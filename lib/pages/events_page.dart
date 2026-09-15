import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/database_service.dart';

class EventsPage extends StatefulWidget {
  final String listTitle;
  final int listId;

  const EventsPage({
    super.key,
    required this.listTitle,
    required this.listId,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Event> _allEvents = [];
  List<Event> _filteredEvents = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final events = await DatabaseService.getEventsByListId(widget.listId);
      setState(() {
        _allEvents = events;
        _filteredEvents = events;
        _isLoading = false;
        _errorMessage = null;
      });
      _filterEvents(_searchController.text);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'خطأ في تحميل الأحداث: $e';
      });
    }
  }

  void _filterEvents(String query) {
    final trimmed = query.trim().toLowerCase();
    setState(() {
      if (trimmed.isEmpty) {
        _filteredEvents = _allEvents;
      } else {
        _filteredEvents = _allEvents.where((e) {
          return e.title.toLowerCase().contains(trimmed) ||
              e.date.contains(trimmed) ||
              e.description.toLowerCase().contains(trimmed);
        }).toList();
      }
    });
  }

  Future<void> _addEventDialog() async {
    final titleController = TextEditingController();
    final dateController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('إضافة حدث جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'عنوان الحدث *',
                      hintText: 'مثال: اندلاع الثورة التحريرية',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: dateController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      labelText: 'التاريخ (DD-MM-YYYY) *',
                      hintText: 'مثال: 01-11-1954',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'التفاصيل / الوصف (اختياري)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء', style: TextStyle(color: Colors.blueGrey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty && dateController.text.trim().isNotEmpty) {
                    Navigator.of(dialogContext).pop(true);
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('يرجى كتابة عنوان الحدث والتاريخ', textAlign: TextAlign.right), backgroundColor: Colors.redAccent),
                    );
                  }
                },
                child: const Text('إضافة', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      final newEvent = Event(
        title: titleController.text.trim(),
        date: dateController.text.trim(),
        description: descriptionController.text.trim(),
        listId: widget.listId,
        isCustom: true,
      );
      await DatabaseService.insertEvent(newEvent);
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الحدث بنجاح', textAlign: TextAlign.right), backgroundColor: Colors.teal),
        );
      }
    }
  }

  Future<void> _deleteEvent(Event event) async {
    if (event.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('حذف الحدث', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          content: Text('هل أنت متأكد من حذف الحدث "${event.title}"؟'),
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

    if (confirmed == true) {
      await DatabaseService.deleteEvent(event.id!);
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تم حذف الحدث: ${event.title}', textAlign: TextAlign.right), backgroundColor: Colors.teal),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text(widget.listTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Search Input Field
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.indigo.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(color: Colors.indigo.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textAlign: TextAlign.right,
                    onChanged: _filterEvents,
                    decoration: InputDecoration(
                      icon: const Icon(Icons.search_rounded, color: Colors.indigo),
                      hintText: 'ابحث عن حدث أو تاريخ...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),

                // Add Event Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الأحداث (${_filteredEvents.length})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: Colors.indigo.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onPressed: _addEventDialog,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('إضافة حدث', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Events List Area
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
                      : _errorMessage != null
                          ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
                          : _filteredEvents.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.event_note_rounded, size: 64, color: Colors.blueGrey.withValues(alpha: 0.3)),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchController.text.isNotEmpty ? 'لا توجد أحداث تطابق بحثك' : 'لا توجد أحداث في هذه القائمة',
                                        style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade400, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _filteredEvents.length,
                                  itemBuilder: (context, index) {
                                    return _buildEventCard(_filteredEvents[index]);
                                  },
                                ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
                ),
              ),
              if (event.isCustom)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22),
                  onPressed: () => _deleteEvent(event),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  event.date,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                ),
              ],
            ),
          ),
          
          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              event.description,
              style: TextStyle(fontSize: 14, color: Colors.blueGrey.shade600, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
