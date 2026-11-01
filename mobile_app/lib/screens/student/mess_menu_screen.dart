import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_store.dart';

class MessMenuScreen extends StatefulWidget {
  const MessMenuScreen({super.key});

  @override
  State<MessMenuScreen> createState() => _MessMenuScreenState();
}

class _MessMenuScreenState extends State<MessMenuScreen> {
  List<dynamic> _menus = [];
  final Map<String, dynamic> _timings = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _today {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final menus = await ApiService.instance.messMenu(date: _today);
      final timings = await ApiService.instance.messTimings();
      _timings.clear();
      for (final item in timings) {
        final map = item as Map<String, dynamic>;
        _timings[map['mealType'].toString()] = map;
      }
      setState(() => _menus = menus);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  TimeOfDay? _parseTime(dynamic value) {
    if (value == null) return null;
    final parts = value.toString().split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _entryStatus(String mealType) {
    final timing = _timings[mealType];
    if (timing == null) return 'Timing not set';
    final start = _parseTime(timing['startTime']);
    final end = _parseTime(timing['endTime']);
    if (start == null || end == null) return '';
    final now = TimeOfDay.now();
    final nowMins = now.hour * 60 + now.minute;
    final startMins = start.hour * 60 + start.minute;
    final endMins = end.hour * 60 + end.minute;
    if (nowMins < startMins) return 'Entry not allowed — meal starts at ${_fmt(start)}';
    if (nowMins > endMins) return 'Entry closed — ended at ${_fmt(end)}';
    return 'Entry open now';
  }

  String _fmt(TimeOfDay time) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  IconData _iconFor(String meal) {
    switch (meal) {
      case 'BREAKFAST':
        return Icons.wb_sunny_outlined;
      case 'LUNCH':
        return Icons.restaurant;
      case 'SNACK':
        return Icons.local_cafe_outlined;
      default:
        return Icons.nightlight_outlined;
    }
  }

  Future<void> _rate(int menuId) async {
    final roll = AuthStore.instance.session?.rollNumber ??
        AuthStore.instance.session?.username;
    if (roll == null) return;
    var stars = 5;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate this meal'),
        content: StatefulBuilder(
          builder: (context, setLocal) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final value = i + 1;
                return IconButton(
                  onPressed: () => setLocal(() => stars = value),
                  icon: Icon(
                    value <= stars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                );
              }),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.instance.addMealRating(
        menuId: menuId,
        rollNumber: roll,
        rating: stars,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rating saved')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_menus.isEmpty) {
      return const Center(child: Text('Aaj ka mess menu backend mein nahi mila.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _menus.length,
      itemBuilder: (context, index) {
        final menu = _menus[index] as Map<String, dynamic>;
        final meal = menu['mealType']?.toString() ?? '';
        final timing = _timings[meal];
        final start = _parseTime(timing?['startTime']);
        final end = _parseTime(timing?['endTime']);
        final window = (start != null && end != null) ? '${_fmt(start)} - ${_fmt(end)}' : 'Timing n/a';
        final status = _entryStatus(meal);
        final open = status.contains('open');

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
              child: Icon(_iconFor(meal), color: const Color(0xFF1E3A8A)),
            ),
            title: Text(
              meal,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Timing: $window',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  menu['items']?.toString() ?? '',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: open ? Colors.green : Colors.deepOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: menu['id'] == null ? null : () => _rate(menu['id'] as int),
                  child: const Text('Rate this meal'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
