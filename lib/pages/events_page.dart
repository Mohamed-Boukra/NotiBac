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
    setState(() {
      _isLoading = true;
    });

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('إضافة حدث جديد', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'عنوان الحدث *',
                      hintText: 'مثال: اندلاع الثورة التحريرية',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: dateController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'التاريخ (DD-MM-YYYY) *',
                      hintText: 'مثال: 01-11-1954',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descriptionController,
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'التفاصيل / الوصف (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  final title = titleController.text.trim();
                  final date = dateController.text.trim();

                  if (title.isNotEmpty && date.isNotEmpty) {
                    Navigator.of(dialogContext).pop(true);
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('يرجى كتابة عنوان الحدث والتاريخ', textAlign: TextAlign.right),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('إضافة'),
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
          const SnackBar(
            content: Text('تمت إضافة الحدث بنجاح', textAlign: TextAlign.right),
            backgroundColor: Colors.green,
          ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('حذف الحدث'),
          content: Text('هل أنت متأكد من حذف الحدث "${event.title}"؟'),
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

    if (confirmed == true) {
      await DatabaseService.deleteEvent(event.id!);
      await _loadEvents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف الحدث: ${event.title}', textAlign: TextAlign.right),
            backgroundColor: Colors.green,
          ),
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
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;

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
                        widget.listTitle,
                        style: TextStyle(
                          fontSize: screenHeight * 0.024,
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
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    children: [
                      // Search Input Field
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          textAlign: TextAlign.right,
                          onChanged: _filterEvents,
                          decoration: InputDecoration(
                            icon: const Icon(Icons.search_rounded, color: Colors.orange),
                            hintText: 'ابحث عن حدث أو تاريخ...',
                            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.018),

                      // Add Event Button Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'الأحداث والتسلسل الزمني (${_filteredEvents.length})',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[750],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            onPressed: _addEventDialog,
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: const Text(
                              'إضافة حدث',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.018),

                      // Events List Area
                      Expanded(
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                            : _errorMessage != null
                                ? Center(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  )
                                : _filteredEvents.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.event_note_rounded,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              _searchController.text.isNotEmpty
                                                  ? 'لا توجد أحداث تطابق بحثك'
                                                  : 'لا توجد أحداث في هذه القائمة',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _filteredEvents.length,
                                        itemBuilder: (context, index) {
                                          final event = _filteredEvents[index];
                                          return _buildEventCard(event, screenHeight, screenWidth);
                                        },
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

  Widget _buildEventCard(Event event, double screenHeight, double screenWidth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (event.isCustom)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () => _deleteEvent(event),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Date pill badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  event.date,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),

          if (event.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              event.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
