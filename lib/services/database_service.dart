import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../models/event_list.dart';

class DatabaseService {
  static const String _listsKey = 'event_lists';
  static const String _eventsKey = 'events';
  static const String _nextIdKey = 'next_id';

  static int _nextId = 1;

  static Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _nextId = prefs.getInt(_nextIdKey) ?? 1;
  }

  static Future<int> _getNextId() async {
    await _initialize();
    final prefs = await SharedPreferences.getInstance();
    final id = _nextId++;
    await prefs.setInt(_nextIdKey, _nextId);
    return id;
  }

  static Future<void> _initializeDefaults() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey(_listsKey)) {
      return;
    }

    final defaultLists = [
      EventList(
        id: 1,
        name: 'تواريخ الفصل الأول',
        description: 'أحداث الحرب العالمية الأولى والثانية',
        isEnabled: true,
        isPredefined: true,
      ),
      EventList(
        id: 2,
        name: 'تواريخ الفصل الثاني',
        description: 'أحداث ما بين الحربين والحرب العالمية الثانية',
        isEnabled: false,
        isPredefined: true,
      ),
      EventList(
        id: 3,
        name: 'تواريخ الفصل الثالث',
        description: 'أحداث الحرب الباردة وما بعدها',
        isEnabled: false,
        isPredefined: true,
      ),
    ];

    final defaultEvents = [
      // Term 1
      Event(
        id: 1,
        title: 'اندلاع الحرب العالمية الأولى',
        date: '28-07-1914',
        description: 'بداية الحرب العالمية الأولى بعد اغتيال الأرشيدوق فرانز فرديناند',
        listId: 1,
      ),
      Event(
        id: 2,
        title: 'تأسيس عصبة الأمم',
        date: '10-01-1920',
        description: 'تأسيس منظمة عصبة الأمم لضمان السلام العالمي',
        listId: 1,
      ),
      Event(
        id: 3,
        title: 'انتهاء الحرب العالمية الثانية',
        date: '02-09-1945',
        description: 'انتهاء الحرب العالمية الثانية بتوقيع اليابان على الاستسلام',
        listId: 1,
      ),
      // Term 2
      Event(
        id: 4,
        title: 'ثورة أكتوبر الروسية',
        date: '07-11-1917',
        description: 'الثورة البلشفية في روسيا',
        listId: 2,
      ),
      Event(
        id: 5,
        title: 'معاهدة فرساي',
        date: '28-06-1919',
        description: 'معاهدة السلام التي أنهت الحرب العالمية الأولى',
        listId: 2,
      ),
      Event(
        id: 6,
        title: 'أزمة الكساد الكبير',
        date: '29-10-1929',
        description: 'انهيار سوق الأسهم الأمريكي',
        listId: 2,
      ),
      Event(
        id: 7,
        title: 'صعود هتلر للسلطة',
        date: '30-01-1933',
        description: 'تعيين أدولف هتلر مستشاراً لألمانيا',
        listId: 2,
      ),
      Event(
        id: 8,
        title: 'غزو بولندا',
        date: '01-09-1939',
        description: 'بداية الحرب العالمية الثانية',
        listId: 2,
      ),
      // Term 3
      Event(
        id: 9,
        title: 'مبدأ ترومان (الحرب الباردة)',
        date: '12-03-1947',
        description: 'بداية سياسة الاحتواء والحرب الباردة بين الولايات المتحدة والاتحاد السوفيتي',
        listId: 3,
      ),
      Event(
        id: 10,
        title: 'تأسيس الأمم المتحدة',
        date: '24-10-1945',
        description: 'تأسيس منظمة الأمم المتحدة',
        listId: 3,
      ),
      Event(
        id: 11,
        title: 'أزمة الصواريخ الكوبية',
        date: '14-10-1962',
        description: 'مواجهة حادة بين الولايات المتحدة والاتحاد السوفيتي حول كوبا',
        listId: 3,
      ),
      Event(
        id: 12,
        title: 'سقوط جدار برلين',
        date: '09-11-1989',
        description: 'انهيار جدار برلين وبداية توحيد ألمانيا',
        listId: 3,
      ),
      Event(
        id: 13,
        title: 'انهيار الاتحاد السوفيتي',
        date: '26-12-1991',
        description: 'نهاية الاتحاد السوفيتي وتفككه',
        listId: 3,
      ),
    ];

    await _saveLists(defaultLists);
    await _saveEvents(defaultEvents);
    await prefs.setInt(_nextIdKey, 14);
    _nextId = 14;
  }

  static Future<void> _saveLists(List<EventList> lists) async {
    final prefs = await SharedPreferences.getInstance();
    final listsJson = lists.map((l) => l.toJson()).toList();
    await prefs.setString(_listsKey, jsonEncode(listsJson));
  }

  static Future<void> _saveEvents(List<Event> events) async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = events.map((e) => e.toJson()).toList();
    await prefs.setString(_eventsKey, jsonEncode(eventsJson));
  }

  static Future<List<EventList>> _loadLists() async {
    final prefs = await SharedPreferences.getInstance();
    final listsJson = prefs.getString(_listsKey) ?? '[]';
    final List<dynamic> listsData = jsonDecode(listsJson);
    return listsData.map((data) => EventList.fromJson(data)).toList();
  }

  static Future<List<Event>> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final eventsJson = prefs.getString(_eventsKey) ?? '[]';
    final List<dynamic> eventsData = jsonDecode(eventsJson);
    return eventsData.map((data) => Event.fromJson(data)).toList();
  }

  // --- Public API ---

  static Future<List<EventList>> getAllLists() async {
    await _initializeDefaults();
    return await _loadLists();
  }

  static Future<EventList?> getListById(int id) async {
    final lists = await _loadLists();
    try {
      return lists.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  static Future<int> insertList(EventList list) async {
    final lists = await _loadLists();
    final newId = await _getNextId();
    final newList = list.copyWith(id: newId);
    lists.add(newList);
    await _saveLists(lists);
    return newId;
  }

  static Future<int> updateList(EventList list) async {
    final lists = await _loadLists();
    final index = lists.indexWhere((l) => l.id == list.id);
    if (index != -1) {
      lists[index] = list;
      await _saveLists(lists);
      return 1;
    }
    return 0;
  }

  static Future<int> deleteList(int id) async {
    final lists = await _loadLists();
    lists.removeWhere((l) => l.id == id);
    await _saveLists(lists);

    final events = await _loadEvents();
    events.removeWhere((e) => e.listId == id);
    await _saveEvents(events);

    return 1;
  }

  static Future<List<Event>> getEventsByListId(int listId) async {
    await _initializeDefaults();
    final events = await _loadEvents();
    return events.where((e) => e.listId == listId).toList();
  }

  static Future<List<Event>> getAllEnabledEvents() async {
    await _initializeDefaults();
    final lists = await _loadLists();
    final enabledListIds = lists.where((l) => l.isEnabled).map((l) => l.id!).toList();
    final events = await _loadEvents();
    return events.where((e) => enabledListIds.contains(e.listId)).toList();
  }

  static Future<List<Event>> searchEvents(String query) async {
    final allEvents = await getAllEnabledEvents();
    final lowerQuery = query.toLowerCase();
    return allEvents.where((e) {
      return e.title.toLowerCase().contains(lowerQuery) ||
          e.date.contains(query) ||
          e.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  static Future<int> insertEvent(Event event) async {
    final events = await _loadEvents();
    final newId = await _getNextId();
    final newEvent = event.copyWith(id: newId);
    events.add(newEvent);
    await _saveEvents(events);
    return newId;
  }

  static Future<int> updateEvent(Event event) async {
    final events = await _loadEvents();
    final index = events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      events[index] = event;
      await _saveEvents(events);
      return 1;
    }
    return 0;
  }

  static Future<int> deleteEvent(int id) async {
    final events = await _loadEvents();
    events.removeWhere((e) => e.id == id);
    await _saveEvents(events);
    return 1;
  }

  static Future<int> getEventCount(int listId) async {
    final events = await getEventsByListId(listId);
    return events.length;
  }
}
