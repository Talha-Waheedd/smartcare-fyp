// FILE: lib/screens/patient/book_appointment_screen.dart
// PURPOSE: Patient picks a date + available time slot (from the doctor's
//          schedule) and submits an appointment request (status: pending).

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/appointment_model.dart';
import '../../models/user_model.dart';
import '../../services/appointment_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

const List<String> _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

class BookAppointmentScreen extends StatefulWidget {
  final UserModel doctor;
  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _apptService = AppointmentService();
  final _userService = UserService();
  final _reasonCtrl = TextEditingController();

  String? _patientId;
  String _patientName = '';
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  List<String> _slots = [];
  Set<String> _takenSlots = {};
  bool _loadingSlots = false;
  bool _booking = false;

  static const _accent = AppColors.doctor;

  @override
  void initState() {
    super.initState();
    _patientId = FirebaseAuth.instance.currentUser?.uid;
    if (_patientId == null) {
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
    _loadPatientName();
    _rebuildSlots();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPatientName() async {
    final user = await _userService.getUser(_patientId!);
    if (mounted && user != null) {
      setState(() => _patientName = user.name);
    }
  }

  int _toMinutes(String? hhmm, int fallback) {
    if (hhmm == null) return fallback;
    final parts = hhmm.split(':');
    if (parts.length != 2) return fallback;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return h * 60 + m;
  }

  String _fmtMinutes(int total) =>
      '${(total ~/ 60).toString().padLeft(2, '0')}:${(total % 60).toString().padLeft(2, '0')}';

  Future<void> _rebuildSlots() async {
    setState(() {
      _loadingSlots = true;
      _selectedSlot = null;
    });

    final dayKey = _dayKeys[_selectedDate.weekday - 1];
    final dayCfg = widget.doctor.availability[dayKey] as Map<String, dynamic>?;
    final enabled = dayCfg?['enabled'] as bool? ?? false;

    final slots = <String>[];
    if (enabled) {
      final startMin = _toMinutes(dayCfg?['start'] as String?, 9 * 60);
      final endMin = _toMinutes(dayCfg?['end'] as String?, 17 * 60);
      final duration =
          widget.doctor.slotDurationMinutes > 0 ? widget.doctor.slotDurationMinutes : 30;
      for (var t = startMin; t + duration <= endMin; t += duration) {
        slots.add('${_fmtMinutes(t)} - ${_fmtMinutes(t + duration)}');
      }
    }

    Set<String> taken = {};
    try {
      taken = await _apptService.getTakenSlotLabels(
          widget.doctor.uid, _selectedDate);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _slots = slots;
      _takenSlots = taken;
      _loadingSlots = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _rebuildSlots();
    }
  }

  Future<void> _book() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }
    setState(() => _booking = true);

    final startStr = _selectedSlot!.split(' - ').first;
    final startMin = _toMinutes(startStr, 9 * 60);
    final slotDateTime = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, startMin ~/ 60, startMin % 60);

    final now = DateTime.now();
    try {
      await _apptService.createAppointment(AppointmentModel(
        id: '',
        patientId: _patientId!,
        patientName: _patientName.isEmpty ? 'Patient' : _patientName,
        doctorId: widget.doctor.uid,
        doctorName: widget.doctor.name,
        slotDate: slotDateTime,
        slotLabel: _selectedSlot!,
        status: AppointmentStatus.pending,
        reason: _reasonCtrl.text.trim(),
        createdAt: now,
        updatedAt: now,
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Appointment requested! Awaiting doctor confirmation.'),
        backgroundColor: AppColors.success,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Booking failed: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        title: Text('Book Dr. ${widget.doctor.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _accent.withOpacity(0.15),
                  child: Text(
                    widget.doctor.name.isNotEmpty
                        ? widget.doctor.name[0].toUpperCase()
                        : 'D',
                    style: const TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 22),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. ${widget.doctor.name}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      Text(
                          widget.doctor.specialization.isEmpty
                              ? 'General Physician'
                              : widget.doctor.specialization,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Select Date',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size(double.infinity, 50),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.calendar_today_outlined, color: _accent),
            label: Text(_fmtDate(_selectedDate)),
          ),
          const SizedBox(height: 24),
          const Text('Available Slots',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          if (_loadingSlots)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator(color: _accent)),
            )
          else if (_slots.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'The doctor is not available on this day. Please pick another date.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _slots.map((slot) {
                final taken = _takenSlots.contains(slot);
                final selected = _selectedSlot == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: selected,
                  onSelected: taken
                      ? null
                      : (_) => setState(() => _selectedSlot = slot),
                  disabledColor: AppColors.border.withOpacity(0.4),
                  selectedColor: _accent.withOpacity(0.2),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: taken
                        ? AppColors.textHint
                        : selected
                            ? _accent
                            : AppColors.textPrimary,
                    decoration: taken ? TextDecoration.lineThrough : null,
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),
          const Text('Reason for Visit',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _reasonCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Briefly describe your symptoms or reason...',
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _booking ? null : _book,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
              icon: _booking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_outline),
              label: Text(_booking ? 'Booking...' : 'Request Appointment'),
            ),
          ),
        ],
      ),
    );
  }
}
