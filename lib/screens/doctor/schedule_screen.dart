// FILE: lib/screens/doctor/schedule_screen.dart
// PURPOSE: Doctor sets weekly availability (enabled days + start/end times) and
//          slot duration. Saved to the users doc as an `availability` map +
//          `slotDurationMinutes`. Patients use this to see bookable slots.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

/// Ordered day keys used in the availability map.
const List<String> kDayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const Map<String, String> kDayLabels = {
  'mon': 'Monday',
  'tue': 'Tuesday',
  'wed': 'Wednesday',
  'thu': 'Thursday',
  'fri': 'Friday',
  'sat': 'Saturday',
  'sun': 'Sunday',
};

class _DaySchedule {
  bool enabled;
  TimeOfDay start;
  TimeOfDay end;
  _DaySchedule({required this.enabled, required this.start, required this.end});
}

TimeOfDay _parseTime(String? raw, TimeOfDay fallback) {
  if (raw == null) return fallback;
  final parts = raw.split(':');
  if (parts.length != 2) return fallback;
  return TimeOfDay(
    hour: int.tryParse(parts[0]) ?? fallback.hour,
    minute: int.tryParse(parts[1]) ?? fallback.minute,
  );
}

String formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final _userService = UserService();
  String? _uid;
  bool _loading = true;
  bool _saving = false;
  int _slotDuration = 30;

  final Map<String, _DaySchedule> _schedule = {};

  static const _c1 = AppColors.doctor;
  static const _slotOptions = [15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    if (_uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      });
      return;
    }
    _load();
  }

  Future<void> _load() async {
    final UserModel? user = await _userService.getUser(_uid!);
    final availability = user?.availability ?? const {};
    for (final key in kDayKeys) {
      final day = availability[key] as Map<String, dynamic>?;
      final isWeekday = key != 'sat' && key != 'sun';
      _schedule[key] = _DaySchedule(
        enabled: day?['enabled'] as bool? ?? isWeekday,
        start: _parseTime(day?['start'] as String?, const TimeOfDay(hour: 9, minute: 0)),
        end: _parseTime(day?['end'] as String?, const TimeOfDay(hour: 17, minute: 0)),
      );
    }
    _slotDuration = user?.slotDurationMinutes ?? 30;
    if (!_slotOptions.contains(_slotDuration)) _slotDuration = 30;
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickTime(String key, bool isStart) async {
    final current = isStart ? _schedule[key]!.start : _schedule[key]!.end;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) {
      setState(() {
        if (isStart) {
          _schedule[key]!.start = picked;
        } else {
          _schedule[key]!.end = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final map = <String, dynamic>{};
    for (final key in kDayKeys) {
      final d = _schedule[key]!;
      map[key] = {
        'enabled': d.enabled,
        'start': formatTimeOfDay(d.start),
        'end': formatTimeOfDay(d.end),
      };
    }
    try {
      await _userService.updateAvailability(
        _uid!,
        availability: map,
        slotDurationMinutes: _slotDuration,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Schedule saved'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save schedule: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: _c1,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _c1))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timelapse_outlined, color: _c1),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Appointment slot duration',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ),
                      DropdownButton<int>(
                        value: _slotDuration,
                        underline: const SizedBox.shrink(),
                        items: _slotOptions
                            .map((m) => DropdownMenuItem(
                                value: m, child: Text('$m min')))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _slotDuration = v ?? 30),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...kDayKeys.map(_buildDayRow),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : _save,
        backgroundColor: _c1,
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.save_outlined),
        label: Text(_saving ? 'Saving...' : 'Save Schedule'),
      ),
    );
  }

  Widget _buildDayRow(String key) {
    final d = _schedule[key]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(kDayLabels[key]!,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
              ),
              Switch(
                value: d.enabled,
                activeColor: _c1,
                onChanged: (v) => setState(() => d.enabled = v),
              ),
            ],
          ),
          if (d.enabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: _timeButton(
                        'From', formatTimeOfDay(d.start),
                        () => _pickTime(key, true)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeButton(
                        'To', formatTimeOfDay(d.end),
                        () => _pickTime(key, false)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _timeButton(String label, String value, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
