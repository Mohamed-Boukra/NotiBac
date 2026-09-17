import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/event.dart';
import '../models/event_list.dart';

class DatabaseService {
  static const String _listsKey = 'event_lists_v2';
  static const String _eventsKey = 'events_v2';
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

    try {
      final jsonString = await rootBundle.loadString('assets/history_dates.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);
      final List<dynamic> categories = jsonData['categories'];

      final List<EventList> defaultLists = [];
      final List<Event> defaultEvents = [];
      int eventIdCounter = 1;

      for (var category in categories) {
        final int unitId = category['unit'];
        final String unitName = category['unit_name'];
        final List<dynamic> eventsList = category['events'];

        defaultLists.add(
          EventList(
            id: unitId,
            name: unitName,
            description: 'أحداث $unitName',
            isEnabled: unitId == 1, // Only first unit is enabled by default
            isPredefined: true,
          ),
        );

        for (var eventMap in eventsList) {
          defaultEvents.add(
            Event(
              id: eventIdCounter++,
              title: eventMap['event'],
              date: eventMap['date'],
              description: eventMap['date_ar'] ?? '',
              listId: unitId,
            ),
          );
        }
      }

      await _saveLists(defaultLists);
      await _saveEvents(defaultEvents);
      await prefs.setInt(_nextIdKey, eventIdCounter);
      _nextId = eventIdCounter;
    } catch (e) {
      print("Error loading default JSON data: $e");
    }
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
